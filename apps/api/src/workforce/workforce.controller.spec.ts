import { ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { SupabaseAdminService } from '../auth/supabase-admin.service';
import type { GeoAttendIdentity } from '../auth/auth.guard';
import { WorkforceController } from './workforce.controller';

const identity = (role: string): GeoAttendIdentity => ({
  subject: 'auth-admin',
  employeeId: 'actor-1',
  organizationId: 'org-1',
  role,
  passwordResetRequired: false,
});

describe('WorkforceController password reset', () => {
  it('prevents HR from resetting a Super Admin account', async () => {
    const db = {
      employee: { findUnique: jest.fn().mockResolvedValue({ id: 'admin-1', authUserId: 'auth-1', organizationId: 'org-1', employeeNumber: 'ADMIN-001', email: 'admin@example.com', role: 'ADMIN' }) },
    } as unknown as PrismaService;
    const supabaseAdmin = { resolveUserId: jest.fn(), updatePassword: jest.fn() } as unknown as SupabaseAdminService;
    const controller = new WorkforceController(db, supabaseAdmin);

    await expect(controller.resetEmployeePassword('admin-1', { user: identity('HR') })).rejects.toBeInstanceOf(ForbiddenException);
    expect(supabaseAdmin.resolveUserId).not.toHaveBeenCalled();
  });

  it('issues a temporary password without writing it to the audit metadata', async () => {
    const transaction = {
      employee: { update: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const db = {
      employee: { findUnique: jest.fn().mockResolvedValue({ id: 'employee-1', authUserId: 'auth-1', organizationId: 'org-1', employeeNumber: 'EMP-001', email: 'employee@example.com', role: 'EMPLOYEE' }) },
      $transaction: jest.fn(async (callback: (client: typeof transaction) => Promise<void>) => callback(transaction)),
    } as unknown as PrismaService;
    const supabaseAdmin = {
      resolveUserId: jest.fn().mockResolvedValue('auth-1'),
      updatePassword: jest.fn().mockResolvedValue(undefined),
    } as unknown as SupabaseAdminService;
    const controller = new WorkforceController(db, supabaseAdmin);

    const result = await controller.resetEmployeePassword('employee-1', { user: identity('ADMIN') });

    expect(result.temporaryPassword).toMatch(/^Ha1![A-Za-z0-9_-]{12}$/u);
    expect(supabaseAdmin.updatePassword).toHaveBeenCalledWith('auth-1', result.temporaryPassword);
    expect(transaction.employee.update).toHaveBeenCalledWith(expect.objectContaining({ data: { authUserId: 'auth-1', passwordResetRequired: true } }));
    expect(JSON.stringify(transaction.auditLog.create.mock.calls)).not.toContain(result.temporaryPassword);
  });

  it('sets the employee password and clears the forced-reset flag', async () => {
    const transaction = {
      employee: { update: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const db = {
      employee: { findFirst: jest.fn().mockResolvedValue({ id: 'employee-1', authUserId: 'auth-1', organizationId: 'org-1', employeeNumber: 'EMP-001', passwordResetRequired: true }) },
      $transaction: jest.fn(async (callback: (client: typeof transaction) => Promise<void>) => callback(transaction)),
    } as unknown as PrismaService;
    const supabaseAdmin = { updatePassword: jest.fn().mockResolvedValue(undefined) } as unknown as SupabaseAdminService;
    const controller = new WorkforceController(db, supabaseAdmin);

    await expect(controller.completePasswordReset({ password: 'PrivatePass123!' }, { user: identity('EMPLOYEE') })).resolves.toEqual({ completed: true });
    expect(supabaseAdmin.updatePassword).toHaveBeenCalledWith('auth-1', 'PrivatePass123!');
    expect(transaction.employee.update).toHaveBeenCalledWith(expect.objectContaining({ data: { passwordResetRequired: false } }));
  });
});
