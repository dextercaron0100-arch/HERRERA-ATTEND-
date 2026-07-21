import { ConflictException, ForbiddenException } from '@nestjs/common';
import { CompensationService } from './compensation.service';

const dto = {
  organizationId: '11111111-1111-4111-8111-111111111111',
  employeeId: '22222222-2222-4222-8222-222222222222',
  actorId: '33333333-3333-4333-8333-333333333333',
  effectiveFrom: '2026-08-01', currency: 'PHP', monthlyBase: '25000.00', hourlyRate: '142.0455',
  allowances: [{ code: 'MEAL', description: 'Meal allowance', amount: '1000.00' }], deductions: [],
};

describe('CompensationService', () => {
  it('creates an audited profile for an authorized same-tenant actor', async () => {
    const db: any = {
      employee: { findUnique: jest.fn().mockResolvedValueOnce({ id: dto.actorId, organizationId: dto.organizationId, role: 'PAYROLL' }).mockResolvedValueOnce({ id: dto.employeeId, organizationId: dto.organizationId }) },
      compensationProfile: { findFirst: jest.fn().mockResolvedValue(null), create: jest.fn().mockResolvedValue({ id: 'profile-1' }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    await expect(new CompensationService(db).create(dto)).resolves.toEqual({ id: 'profile-1' });
    expect(db.auditLog.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ action: 'COMPENSATION_PROFILE_CREATED' }) }));
  });

  it('rejects overlapping effective periods', async () => {
    const db: any = {
      employee: { findUnique: jest.fn().mockResolvedValueOnce({ id: dto.actorId, organizationId: dto.organizationId, role: 'ADMIN' }).mockResolvedValueOnce({ id: dto.employeeId, organizationId: dto.organizationId }) },
      compensationProfile: { findFirst: jest.fn().mockResolvedValue({ id: 'existing' }) },
    };
    await expect(new CompensationService(db).create(dto)).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects actors without a payroll management role', async () => {
    const db: any = { employee: { findUnique: jest.fn().mockResolvedValue({ id: dto.actorId, organizationId: dto.organizationId, role: 'EMPLOYEE' }) } };
    await expect(new CompensationService(db).create(dto)).rejects.toBeInstanceOf(ForbiddenException);
  });
});
