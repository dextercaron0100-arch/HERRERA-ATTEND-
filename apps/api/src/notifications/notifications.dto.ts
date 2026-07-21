import { IsOptional, IsUUID, Matches } from 'class-validator';

export class ListNotificationsDto {
  @IsUUID() organizationId!: string;
  @IsUUID() actorId!: string;
  @IsUUID() employeeId!: string;
  @IsOptional() @Matches(/^\d{1,3}$/) limit?: string;
}

export class ReadNotificationDto {
  @IsUUID() organizationId!: string;
  @IsUUID() actorId!: string;
  @IsUUID() employeeId!: string;
}

export class ReadAllNotificationsDto extends ReadNotificationDto {}
