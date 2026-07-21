import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  NotFoundException,
  Param,
  Post,
  Query,
  Res,
  UnauthorizedException,
} from '@nestjs/common';
import type { Response } from 'express';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../prisma.service';
import { PayrollService } from '../payroll/payroll.service';
import { Public } from '../auth/public.decorator';
import { MobileLoginDto, RegisterDeviceDto } from './mobile.dto';

@Controller('mobile')
export class MobileController {
  constructor(
    private readonly db: PrismaService,
    private readonly payrollService: PayrollService,
  ) {}

  @Public()
  @Post('auth/login')
  async login(@Body() dto: MobileLoginDto) {
    if ((process.env.AUTH_MODE ?? 'development') !== 'development') {
      throw new ForbiddenException(
        'Password login is disabled; use the configured identity provider.',
      );
    }
    const expected = process.env.DEMO_PASSWORD ?? 'Herrera123!';
    if (dto.password !== expected) {
      throw new UnauthorizedException('Invalid employee ID or password');
    }
    const employee = await this.db.employee.findFirst({
      where: {
        active: true,
        OR: [
          { employeeNumber: { equals: dto.username, mode: 'insensitive' } },
          { email: { equals: dto.username, mode: 'insensitive' } },
        ],
      },
      include: { worksite: true, department: true },
    });
    if (!employee) {
      throw new UnauthorizedException('Invalid employee ID or password');
    }
    return {
      accessToken: `development.${employee.id}.${randomUUID()}`,
      expiresIn: 28800,
      employee: this.employeeIdentity(employee),
    };
  }

  @Get('employees/:id/overview')
  async overview(@Param('id') id: string) {
    const employee = await this.db.employee.findUnique({
      where: { id },
      include: {
        worksite: true,
        department: true,
        schedule: { include: { shifts: { orderBy: { dayOfWeek: 'asc' } } } },
      },
    });
    if (!employee?.active) throw new NotFoundException('Employee not found');

    const since = new Date();
    since.setDate(since.getDate() - 62);
    const [events, summaries, requests, notifications, holidays, payrollRun, pilotMember] =
      await Promise.all([
        this.db.attendanceEvent.findMany({
          where: { employeeId: id, capturedAt: { gte: since } },
          orderBy: { capturedAt: 'desc' },
          take: 150,
        }),
        this.db.dailyAttendanceSummary.findMany({
          where: { employeeId: id, localDate: { gte: since } },
          orderBy: { localDate: 'desc' },
          take: 62,
        }),
        this.db.request.findMany({
          where: { employeeId: id },
          include: { steps: { orderBy: { sequence: 'asc' } } },
          orderBy: { submittedAt: 'desc' },
          take: 30,
        }),
        this.db.notification.findMany({
          where: { employeeId: id },
          orderBy: { createdAt: 'desc' },
          take: 30,
        }),
        this.db.holiday.findMany({
          where: { organizationId: employee.organizationId },
          orderBy: { date: 'asc' },
        }),
        this.db.payrollRun.findFirst({
          where: { organizationId: employee.organizationId, items: { some: { employeeId: id } } },
          include: {
            policy: true,
            items: { where: { employeeId: id }, orderBy: { code: 'asc' } },
            payslips: { where: { employeeId: id } },
          },
          orderBy: { periodEnd: 'desc' },
        }),
        this.db.pilotMember.findFirst({
          where: { employeeId: id, pilot: { status: { in: ['ACTIVE', 'COMPLETED'] } } },
          include: {
            pilot: {
              include: {
                cycles: { orderBy: { cycleNumber: 'asc' } },
                _count: { select: { members: true } },
              },
            },
          },
          orderBy: { enrolledAt: 'desc' },
        }),
      ]);

    const profile = await this.db.compensationProfile.findFirst({
      where: { employeeId: id },
      orderBy: { effectiveFrom: 'desc' },
    });
    return {
      employee: this.employeeIdentity(employee),
      schedule: employee.schedule,
      holidays,
      attendance: { events, summaries },
      requests,
      notifications,
      leaveBalances: { vacation: 12, sick: 5, personal: 3 },
      pilot: pilotMember
        ? {
            id: pilotMember.pilot.id,
            name: pilotMember.pilot.name,
            status: pilotMember.pilot.status,
            enrolledAt: pilotMember.enrolledAt,
            targetCycles: pilotMember.pilot.targetCycles,
            completedCycles: pilotMember.pilot.cycles.filter(
              (cycle) => cycle.status === 'SIGNED_OFF',
            ).length,
            memberCount: pilotMember.pilot._count.members,
          }
        : null,
      payroll: payrollRun
        ? {
            id: payrollRun.id,
            periodStart: payrollRun.periodStart,
            periodEnd: payrollRun.periodEnd,
            status: payrollRun.status,
            currency: payrollRun.policy?.currency ?? profile?.currency ?? 'PHP',
            lines: payrollRun.items,
            payslipAvailable: payrollRun.payslips.length > 0,
          }
        : profile
          ? {
              id: null,
              periodStart: profile.effectiveFrom,
              periodEnd: null,
              status: 'ESTIMATE',
              currency: profile.currency,
              lines: [
                {
                  code: 'BASE',
                  description: 'Basic Salary',
                  category: 'EARNING',
                  amount: profile.monthlyBase,
                },
              ],
              payslipAvailable: false,
            }
          : null,
    };
  }

  @Get('employees/:id/payslip')
  async payslip(
    @Param('id') employeeId: string,
    @Query('runId') runId: string,
    @Res() response: Response,
  ) {
    if (!runId) throw new NotFoundException('Payroll run is required');
    const pdf = await this.payrollService.payslip(runId, employeeId, employeeId);
    response
      .set({
        'content-type': 'application/pdf',
        'content-disposition': `attachment; filename="herrera-payslip-${employeeId}.pdf"`,
        'cache-control': 'private, no-store',
      })
      .send(pdf);
  }

  @Post('devices/register')
  async registerDevice(@Body() dto: RegisterDeviceDto) {
    if (dto.verificationCode !== (process.env.DEVICE_TEST_CODE ?? '123456')) {
      throw new UnauthorizedException('Invalid device verification code');
    }
    const employee = await this.db.employee.findUnique({ where: { id: dto.employeeId } });
    if (!employee?.active) throw new NotFoundException('Employee not found');
    return this.db.registeredDevice.upsert({
      where: { deviceId: dto.deviceId },
      create: {
        employeeId: dto.employeeId,
        deviceId: dto.deviceId,
        name: dto.name,
        platform: dto.platform,
        biometricsEnabled: dto.biometricsEnabled,
      },
      update: {
        employeeId: dto.employeeId,
        name: dto.name,
        platform: dto.platform,
        biometricsEnabled: dto.biometricsEnabled,
        active: true,
        lastSeenAt: new Date(),
      },
    });
  }

  private employeeIdentity(employee: any) {
    return {
      id: employee.id,
      organizationId: employee.organizationId,
      employeeNumber: employee.employeeNumber,
      name: employee.name,
      email: employee.email,
      role: employee.role,
      department: employee.department?.name ?? null,
      worksite: employee.worksite
        ? {
            id: employee.worksite.id,
            name: employee.worksite.name,
            latitude: Number(employee.worksite.latitude),
            longitude: Number(employee.worksite.longitude),
            radiusMeters: employee.worksite.radiusMeters,
            maxAccuracyMeters: employee.worksite.maxAccuracyMeters,
          }
        : null,
    };
  }
}
