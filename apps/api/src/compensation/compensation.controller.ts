import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CompensationService } from './compensation.service';
import { CreateCompensationDto, UpdateCompensationDto } from './compensation.dto';

@Controller('compensation')
export class CompensationController {
  constructor(private readonly service: CompensationService) {}

  @Get()
  list(@Query('organizationId') organizationId: string, @Query('employeeId') employeeId?: string) {
    return this.service.list(organizationId, employeeId);
  }

  @Post()
  create(@Body() dto: CreateCompensationDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateCompensationDto) {
    return this.service.update(id, dto);
  }
}
