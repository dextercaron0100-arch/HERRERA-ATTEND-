import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { CreateCycleDto, CreatePilotDto, ReconcileCycleDto, SignOffDto } from './pilot.dto';
import { PilotService } from './pilot.service';

@Controller('pilots')
export class PilotController {
  constructor(private readonly service: PilotService) {}
  @Post() create(@Body() dto: CreatePilotDto) { return this.service.create(dto); }
  @Get() list(@Query('organizationId') organizationId: string) { return this.service.list(organizationId); }
  @Post(':id/cycles') createCycle(@Param('id') id: string, @Body() dto: CreateCycleDto) { return this.service.createCycle(id, dto); }
  @Post('cycles/:id/reconcile') reconcile(@Param('id') id: string, @Body() dto: ReconcileCycleDto) { return this.service.reconcile(id, dto); }
  @Get('cycles/:id/summary') summary(@Param('id') id: string) { return this.service.summary(id); }
  @Post('cycles/:id/sign-off') signOff(@Param('id') id: string, @Body() dto: SignOffDto) { return this.service.signOff(id, dto); }
}
