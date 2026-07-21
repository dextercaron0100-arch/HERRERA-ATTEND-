import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { ListNotificationsDto, ReadAllNotificationsDto, ReadNotificationDto } from './notifications.dto';

@Injectable()
export class NotificationsService {
  constructor(private readonly db: PrismaService) {}

  async list(dto: ListNotificationsDto) {
    await this.assertAccess(dto.actorId, dto.employeeId, dto.organizationId);
    const limit = Math.min(Math.max(Number(dto.limit ?? 30), 1), 100);
    const where = { employeeId: dto.employeeId };
    const [items, unreadCount] = await Promise.all([
      this.db.notification.findMany({ where, orderBy: { createdAt: 'desc' }, take: limit }),
      this.db.notification.count({ where: { ...where, readAt: null } }),
    ]);
    return { items, unreadCount };
  }

  async read(id: string, dto: ReadNotificationDto) {
    await this.assertAccess(dto.actorId, dto.employeeId, dto.organizationId);
    const notification = await this.db.notification.findFirst({
      where: { id, employeeId: dto.employeeId },
    });
    if (!notification) throw new NotFoundException('Notification not found');
    if (notification.readAt) return notification;
    return this.db.notification.update({ where: { id }, data: { readAt: new Date() } });
  }

  async readAll(dto: ReadAllNotificationsDto) {
    await this.assertAccess(dto.actorId, dto.employeeId, dto.organizationId);
    const result = await this.db.notification.updateMany({
      where: { employeeId: dto.employeeId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updatedCount: result.count };
  }

  private async assertAccess(actorId: string, employeeId: string, organizationId: string) {
    const [actor, employee] = await Promise.all([
      this.db.employee.findUnique({ where: { id: actorId }, select: { id: true, organizationId: true } }),
      this.db.employee.findUnique({ where: { id: employeeId }, select: { id: true, organizationId: true } }),
    ]);
    if (!actor || !employee || actor.organizationId !== organizationId || employee.organizationId !== organizationId) {
      throw new ForbiddenException('Actor and employee must belong to the organization');
    }
    if (actor.id !== employee.id) throw new ForbiddenException('Employees may only access their own notifications');
  }
}
