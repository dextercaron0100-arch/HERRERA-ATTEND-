import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import Decimal from 'decimal.js';
import { PrismaService } from '../prisma.service';
import { CreateCompensationDto, UpdateCompensationDto } from './compensation.dto';

@Injectable()
export class CompensationService {
  constructor(private readonly db: PrismaService) {}

  list(organizationId: string, employeeId?: string) {
    if (!organizationId) throw new ConflictException('organizationId is required');
    return this.db.compensationProfile.findMany({
      where: { employee: { organizationId }, ...(employeeId ? { employeeId } : {}) },
      include: { employee: { select: { id: true, employeeNumber: true, name: true, active: true } } },
      orderBy: [{ employee: { name: 'asc' } }, { effectiveFrom: 'desc' }],
    });
  }

  async create(dto: CreateCompensationDto) {
    await this.actor(dto.actorId, dto.organizationId);
    await this.employee(dto.employeeId, dto.organizationId);
    const from = this.date(dto.effectiveFrom);
    const to = dto.effectiveTo ? this.date(dto.effectiveTo) : null;
    this.validateRange(from, to);
    this.validateMoney(dto.monthlyBase, dto.hourlyRate);
    this.validateLines(dto.allowances, 'allowance');
    this.validateLines(dto.deductions, 'deduction');
    await this.assertNoOverlap(dto.employeeId, from, to);
    const profile = await this.db.compensationProfile.create({ data: {
      employeeId: dto.employeeId, effectiveFrom: from, effectiveTo: to, currency: dto.currency,
      monthlyBase: dto.monthlyBase, hourlyRate: dto.hourlyRate,
      allowances: dto.allowances as Prisma.InputJsonValue, deductions: dto.deductions as Prisma.InputJsonValue,
    }});
    await this.audit(dto.organizationId, dto.actorId, 'COMPENSATION_PROFILE_CREATED', profile.id, { employeeId: dto.employeeId, effectiveFrom: dto.effectiveFrom });
    return profile;
  }

  async update(id: string, dto: UpdateCompensationDto) {
    const current = await this.db.compensationProfile.findUnique({ where: { id }, include: { employee: true } });
    if (!current || current.employee.organizationId !== dto.organizationId) throw new NotFoundException('Compensation profile not found');
    await this.actor(dto.actorId, dto.organizationId);
    const from = dto.effectiveFrom ? this.date(dto.effectiveFrom) : current.effectiveFrom;
    const to = dto.effectiveTo === undefined ? current.effectiveTo : this.date(dto.effectiveTo);
    this.validateRange(from, to);
    this.validateMoney(dto.monthlyBase ?? current.monthlyBase.toString(), dto.hourlyRate ?? current.hourlyRate?.toString());
    if (dto.allowances) this.validateLines(dto.allowances, 'allowance');
    if (dto.deductions) this.validateLines(dto.deductions, 'deduction');
    await this.assertNoOverlap(current.employeeId, from, to, id);
    const profile = await this.db.compensationProfile.update({ where: { id }, data: {
      effectiveFrom: from, effectiveTo: to, currency: dto.currency,
      monthlyBase: dto.monthlyBase, hourlyRate: dto.hourlyRate,
      allowances: dto.allowances as Prisma.InputJsonValue | undefined,
      deductions: dto.deductions as Prisma.InputJsonValue | undefined,
    }});
    await this.audit(dto.organizationId, dto.actorId, 'COMPENSATION_PROFILE_UPDATED', id, { employeeId: current.employeeId, effectiveFrom: from.toISOString().slice(0, 10) });
    return profile;
  }

  private async actor(id: string, organizationId: string) {
    const actor = await this.db.employee.findUnique({ where: { id } });
    if (!actor || actor.organizationId !== organizationId || !['PAYROLL', 'FINANCE', 'ADMIN'].includes(actor.role)) {
      throw new ForbiddenException('Requires PAYROLL, FINANCE, or ADMIN role');
    }
    return actor;
  }

  private async employee(id: string, organizationId: string) {
    const employee = await this.db.employee.findUnique({ where: { id } });
    if (!employee || employee.organizationId !== organizationId) throw new NotFoundException('Employee not found');
    return employee;
  }

  private date(value: string) {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) throw new ConflictException('Invalid effective date');
    return date;
  }

  private validateRange(from: Date, to: Date | null) {
    if (to && to < from) throw new ConflictException('effectiveTo must be on or after effectiveFrom');
  }

  private validateMoney(monthlyBase: string, hourlyRate?: string) {
    if (!new Decimal(monthlyBase).isPositive()) throw new ConflictException('monthlyBase must be greater than zero');
    if (hourlyRate !== undefined && new Decimal(hourlyRate).isNegative()) throw new ConflictException('hourlyRate cannot be negative');
  }

  private validateLines(lines: unknown[], label: string) {
    for (const line of lines) {
      if (!line || typeof line !== 'object') throw new ConflictException(`Each ${label} must be an object`);
      const item = line as Record<string, unknown>;
      if (typeof item.code !== 'string' || !item.code.trim() || typeof item.description !== 'string' || !item.description.trim()) throw new ConflictException(`Each ${label} requires code and description`);
      try { if (new Decimal(String(item.amount)).isNegative()) throw new Error(); } catch { throw new ConflictException(`Each ${label} amount must be a non-negative number`); }
    }
  }

  private async assertNoOverlap(employeeId: string, from: Date, to: Date | null, excludedId?: string) {
    const overlap = await this.db.compensationProfile.findFirst({ where: {
      employeeId, ...(excludedId ? { id: { not: excludedId } } : {}),
      effectiveFrom: { lte: to ?? new Date('9999-12-31') },
      OR: [{ effectiveTo: null }, { effectiveTo: { gte: from } }],
    }});
    if (overlap) throw new ConflictException('Compensation period overlaps an existing profile');
  }

  private audit(organizationId: string, actorId: string, action: string, entityId: string, metadata: Record<string, unknown>) {
    return this.db.auditLog.create({ data: { organizationId, actorId, action, entityType: 'CompensationProfile', entityId, metadata: metadata as Prisma.InputJsonValue } });
  }
}
