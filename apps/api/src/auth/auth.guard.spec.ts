import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { JWTPayload } from 'jose';
import { AuthGuard } from './auth.guard';
import { PrismaService } from '../prisma.service';

const context = (request: Record<string, unknown>) => ({
  getHandler: () => function handler() {},
  getClass: () => class Controller {},
  switchToHttp: () => ({ getRequest: () => request }),
}) as unknown as ExecutionContext;

type GuardInternals = {
  resolveEmployeeIdentity(payload: JWTPayload): Promise<unknown>;
  assertPasswordResetAccess(request: unknown, identity: unknown): void;
  assertTenantConsistency(request: unknown, identity: unknown): void;
};

describe('AuthGuard', () => {
  const priorUrl = process.env.SUPABASE_URL;

  beforeEach(() => {
    process.env.SUPABASE_URL = 'https://project.supabase.co';
  });

  afterEach(() => {
    process.env.SUPABASE_URL = priorUrl;
  });

  it('rejects missing bearer tokens', async () => {
    const guard = new AuthGuard(new Reflector(), {} as PrismaService);
    await expect(guard.canActivate(context({ headers: {} }))).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('resolves an active employee by Supabase subject', async () => {
    const db = {
      employee: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'employee-1',
          authUserId: 'supabase-user-1',
          organizationId: 'org-1',
          role: 'HR',
          active: true,
          passwordResetRequired: false,
        }),
      },
    } as unknown as PrismaService;
    const guard = new AuthGuard(new Reflector(), db) as unknown as GuardInternals;

    await expect(guard.resolveEmployeeIdentity({ sub: 'supabase-user-1' })).resolves.toEqual({
      subject: 'supabase-user-1',
      employeeId: 'employee-1',
      organizationId: 'org-1',
      role: 'HR',
      passwordResetRequired: false,
    });
  });

  it('links the first verified Supabase login by employee email', async () => {
    const db = {
      employee: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([{
          id: 'employee-1',
          authUserId: null,
          organizationId: 'org-1',
          role: 'EMPLOYEE',
          active: true,
          passwordResetRequired: false,
        }]),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
    } as unknown as PrismaService;
    const guard = new AuthGuard(new Reflector(), db) as unknown as GuardInternals;

    await expect(guard.resolveEmployeeIdentity({
      sub: 'supabase-user-1',
      email: 'employee@example.com',
    })).resolves.toMatchObject({ employeeId: 'employee-1', subject: 'supabase-user-1' });
  });

  it('rejects suspended linked employees', async () => {
    const db = {
      employee: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'employee-1',
          authUserId: 'supabase-user-1',
          organizationId: 'org-1',
          role: 'EMPLOYEE',
          active: false,
          passwordResetRequired: false,
        }),
      },
    } as unknown as PrismaService;
    const guard = new AuthGuard(new Reflector(), db) as unknown as GuardInternals;

    await expect(guard.resolveEmployeeIdentity({ sub: 'supabase-user-1' })).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rejects cross-tenant values before controllers are called', () => {
    const guard = new AuthGuard(new Reflector(), {} as PrismaService) as unknown as GuardInternals;
    expect(() => guard.assertTenantConsistency(
      { headers: {}, query: { organizationId: 'other-org' } },
      { subject: 'user', organizationId: 'org-1', employeeId: 'employee-1', role: 'ADMIN', passwordResetRequired: false },
    )).toThrow(ForbiddenException);
  });

  it('blocks normal API access until a required password reset is completed', () => {
    const guard = new AuthGuard(new Reflector(), {} as PrismaService) as unknown as GuardInternals;
    const identity = { subject: 'user', organizationId: 'org-1', employeeId: 'employee-1', role: 'EMPLOYEE', passwordResetRequired: true };
    expect(() => guard.assertPasswordResetAccess(
      { headers: {}, method: 'GET', originalUrl: '/api/mobile/overview' },
      identity,
    )).toThrow(ForbiddenException);
    expect(() => guard.assertPasswordResetAccess(
      { headers: {}, method: 'POST', originalUrl: '/api/workforce/password-reset/complete' },
      identity,
    )).not.toThrow();
  });
});
