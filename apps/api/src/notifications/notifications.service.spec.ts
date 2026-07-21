import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

const organizationId = '11111111-1111-4111-8111-111111111111';
const employeeId = '22222222-2222-4222-8222-222222222222';
const access = { organizationId, actorId: employeeId, employeeId };
const employee = { id: employeeId, organizationId };

describe('NotificationsService', () => {
  it('lists newest notifications, caps the limit, and returns total unread count', async () => {
    const db: any = {
      employee: { findUnique: jest.fn().mockResolvedValue(employee) },
      notification: {
        findMany: jest.fn().mockResolvedValue([{ id: 'notification-1' }]),
        count: jest.fn().mockResolvedValue(7),
      },
    };
    await expect(new NotificationsService(db).list({ ...access, limit: '999' })).resolves.toEqual({
      items: [{ id: 'notification-1' }], unreadCount: 7,
    });
    expect(db.notification.findMany).toHaveBeenCalledWith(expect.objectContaining({ take: 100, orderBy: { createdAt: 'desc' } }));
    expect(db.notification.count).toHaveBeenCalledWith({ where: { employeeId, readAt: null } });
  });

  it('rejects cross-tenant access', async () => {
    const db: any = {
      employee: { findUnique: jest.fn()
        .mockResolvedValueOnce(employee)
        .mockResolvedValueOnce({ id: employeeId, organizationId: 'other-organization' }) },
    };
    await expect(new NotificationsService(db).list(access)).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects access to another employee notifications', async () => {
    const actor = { id: '33333333-3333-4333-8333-333333333333', organizationId };
    const db: any = { employee: { findUnique: jest.fn().mockResolvedValueOnce(actor).mockResolvedValueOnce(employee) } };
    await expect(new NotificationsService(db).list({ ...access, actorId: actor.id })).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('marks an unread notification as read', async () => {
    const updated = { id: 'notification-1', employeeId, readAt: new Date() };
    const db: any = {
      employee: { findUnique: jest.fn().mockResolvedValue(employee) },
      notification: {
        findFirst: jest.fn().mockResolvedValue({ id: updated.id, employeeId, readAt: null }),
        update: jest.fn().mockResolvedValue(updated),
      },
    };
    await expect(new NotificationsService(db).read(updated.id, access)).resolves.toEqual(updated);
    expect(db.notification.update).toHaveBeenCalledWith({ where: { id: updated.id }, data: { readAt: expect.any(Date) } });
  });

  it('returns not found when a notification does not belong to the employee', async () => {
    const db: any = {
      employee: { findUnique: jest.fn().mockResolvedValue(employee) },
      notification: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    await expect(new NotificationsService(db).read('missing', access)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('marks all unread notifications as read and returns the affected count', async () => {
    const db: any = {
      employee: { findUnique: jest.fn().mockResolvedValue(employee) },
      notification: { updateMany: jest.fn().mockResolvedValue({ count: 3 }) },
    };
    await expect(new NotificationsService(db).readAll(access)).resolves.toEqual({ updatedCount: 3 });
    expect(db.notification.updateMany).toHaveBeenCalledWith({
      where: { employeeId, readAt: null }, data: { readAt: expect.any(Date) },
    });
  });
});
