import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ListNotificationsDto, ReadAllNotificationsDto, ReadNotificationDto } from './notifications.dto';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  list(@Query() query: ListNotificationsDto) {
    return this.service.list(query);
  }

  @Patch(':id/read')
  read(@Param('id') id: string, @Body() dto: ReadNotificationDto) {
    return this.service.read(id, dto);
  }

  @Post('read-all')
  readAll(@Body() dto: ReadAllNotificationsDto) {
    return this.service.readAll(dto);
  }
}
