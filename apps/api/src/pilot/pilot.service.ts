import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { PrismaService } from '../prisma.service';
import { CreateCycleDto, CreatePilotDto, ReconcileCycleDto, SignOffDto } from './pilot.dto';
import { reconcileLines } from './reconciliation';

@Injectable()
export class PilotService {
  constructor(private readonly db: PrismaService) {}

  async create(dto: CreatePilotDto) {
    const actor = await this.actor(dto.actorId, dto.organizationId, ['HR', 'PAYROLL', 'ADMIN']);
    const employeeCount = await this.db.employee.count({ where: { id: { in: dto.employeeIds }, organizationId: dto.organizationId, active: true } });
    if (employeeCount !== new Set(dto.employeeIds).size) throw new ConflictException('Every pilot member must be an active employee in the organization');
    const pilot = await this.db.pilot.create({ data: { organizationId: dto.organizationId, worksiteId: dto.worksiteId, name: dto.name, status: 'ACTIVE', tolerance: dto.tolerance, targetCycles: dto.targetCycles, startsAt: new Date(dto.startsAt), createdById: actor.id, members: { create: [...new Set(dto.employeeIds)].map(employeeId => ({ employeeId })) } }, include: { members: true } });
    await this.audit(dto.organizationId, actor.id, 'PILOT_STARTED', pilot.id, { memberCount: pilot.members.length, targetCycles: pilot.targetCycles });
    return pilot;
  }

  list(organizationId: string) { return this.db.pilot.findMany({ where: { organizationId }, include: { members: true, cycles: { include: { referenceLines: true }, orderBy: { cycleNumber: 'asc' } } }, orderBy: { createdAt: 'desc' } }); }

  async createCycle(pilotId: string, dto: CreateCycleDto) {
    const pilot = await this.db.pilot.findUnique({ where: { id: pilotId }, include: { cycles: true } });
    if (!pilot || pilot.status !== 'ACTIVE') throw new NotFoundException('Active pilot not found');
    const actor = await this.actor(dto.actorId, pilot.organizationId, ['PAYROLL', 'ADMIN']);
    const run = await this.db.payrollRun.findUnique({ where: { id: dto.payrollRunId } });
    if (!run || run.organizationId !== pilot.organizationId || !['CALCULATED', 'APPROVED', 'LOCKED'].includes(run.status)) throw new ConflictException('Pilot cycles require a calculated payroll run in the same organization');
    const cycle = await this.db.pilotCycle.create({ data: { pilotId, payrollRunId: run.id, cycleNumber: pilot.cycles.length + 1 } });
    await this.audit(pilot.organizationId, actor.id, 'PILOT_CYCLE_OPENED', cycle.id, { pilotId, cycleNumber: cycle.cycleNumber, payrollRunId: run.id });
    return cycle;
  }

  async reconcile(cycleId: string, dto: ReconcileCycleDto) {
    const cycle = await this.db.pilotCycle.findUnique({ where: { id: cycleId }, include: { pilot: { include: { members: true } }, payrollRun: { include: { items: true } } } });
    if (!cycle || cycle.status === 'SIGNED_OFF') throw new NotFoundException('Open pilot cycle not found');
    const actor = await this.actor(dto.actorId, cycle.pilot.organizationId, ['PAYROLL', 'FINANCE', 'ADMIN']);
    const memberIds = new Set(cycle.pilot.members.map(member => member.employeeId));
    if (dto.lines.some(line => !memberIds.has(line.employeeId))) throw new ConflictException('Reference line employee is outside the pilot cohort');
    const lines = reconcileLines(dto.lines, cycle.payrollRun.items.map(item => ({ employeeId: item.employeeId, code: item.code, amount: item.amount })), cycle.pilot.tolerance.toString());
    await this.db.$transaction(async tx => {
      await tx.pilotReferenceLine.deleteMany({ where: { pilotCycleId: cycle.id } });
      await tx.pilotReferenceLine.createMany({ data: lines.map(line => ({ pilotCycleId: cycle.id, ...line })) });
      await tx.pilotCycle.update({ where: { id: cycle.id }, data: { status: 'RECONCILED', reconciledAt: new Date() } });
      await tx.auditLog.create({ data: { organizationId: cycle.pilot.organizationId, actorId: actor.id, action: 'PILOT_CYCLE_RECONCILED', entityType: 'PilotCycle', entityId: cycle.id, metadata: { lineCount: lines.length, unresolvedCount: lines.filter(line => !line.resolved).length } } });
    });
    return this.summary(cycle.id);
  }

  async signOff(cycleId: string, dto: SignOffDto) {
    const cycle = await this.db.pilotCycle.findUnique({ where: { id: cycleId }, include: { pilot: true, referenceLines: true } });
    if (!cycle || cycle.status !== 'RECONCILED') throw new NotFoundException('Reconciled cycle not found');
    const actor = await this.actor(dto.actorId, cycle.pilot.organizationId, ['FINANCE', 'ADMIN']);
    if (cycle.referenceLines.length === 0 || cycle.referenceLines.some(line => !line.resolved)) throw new ConflictException('Every variance must be within tolerance before sign-off');
    const updated = await this.db.pilotCycle.update({ where: { id: cycle.id }, data: { status: 'SIGNED_OFF', signedOffAt: new Date(), signedOffById: actor.id, notes: dto.notes } });
    const signedCycles = await this.db.pilotCycle.count({ where: { pilotId: cycle.pilotId, status: 'SIGNED_OFF' } });
    if (signedCycles >= cycle.pilot.targetCycles) await this.db.pilot.update({ where: { id: cycle.pilotId }, data: { status: 'COMPLETED', endsAt: new Date() } });
    await this.audit(cycle.pilot.organizationId, actor.id, 'PILOT_CYCLE_SIGNED_OFF', cycle.id, { cycleNumber: cycle.cycleNumber, pilotCompleted: signedCycles >= cycle.pilot.targetCycles });
    return updated;
  }

  async summary(cycleId: string) {
    const cycle = await this.db.pilotCycle.findUniqueOrThrow({ where: { id: cycleId }, include: { referenceLines: true } });
    const absoluteVariance = cycle.referenceLines.reduce((total, line) => total.plus(line.variance.abs()), new Prisma.Decimal(0));
    return { ...cycle, metrics: { lineCount: cycle.referenceLines.length, resolvedCount: cycle.referenceLines.filter(line => line.resolved).length, unresolvedCount: cycle.referenceLines.filter(line => !line.resolved).length, absoluteVariance: absoluteVariance.toFixed(2), readyForSignOff: cycle.referenceLines.length > 0 && cycle.referenceLines.every(line => line.resolved) } };
  }

  private async actor(id: string, organizationId: string, roles: Role[]) { const actor = await this.db.employee.findUnique({ where: { id } }); if (!actor || actor.organizationId !== organizationId || !roles.includes(actor.role)) throw new ForbiddenException(); return actor; }
  private audit(organizationId: string, actorId: string, action: string, entityId: string, metadata: Record<string, unknown>) { return this.db.auditLog.create({ data: { organizationId, actorId, action, entityType: 'Pilot', entityId, metadata: metadata as Prisma.InputJsonValue } }); }
}
