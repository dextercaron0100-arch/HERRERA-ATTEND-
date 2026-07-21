import { Body, Controller, Get, Param, Post, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { ActorDto, AdjustmentDto, CreateRunDto, PolicyDto } from './payroll.dto';
import { PayrollService } from './payroll.service';
@Controller('payroll') export class PayrollController {
  constructor(private readonly service:PayrollService){}
  @Post('policies') policy(@Body() dto:PolicyDto){return this.service.createPolicy(dto);}
  @Get('policies') policies(@Query('organizationId') organizationId:string){return this.service.listPolicies(organizationId);}
  @Post('policies/:id/approve') approvePolicy(@Param('id') id:string,@Body() dto:ActorDto){return this.service.approvePolicy(id,dto.actorId);}
  @Post('runs') createRun(@Body() dto:CreateRunDto){return this.service.createRun(dto);}
  @Get('runs') runs(@Query('organizationId') organizationId:string){return this.service.listRuns(organizationId);}
  @Post('runs/:id/calculate') calculate(@Param('id') id:string,@Body() dto:ActorDto){return this.service.calculate(id,dto.actorId);}
  @Post('runs/:id/adjustments') adjust(@Param('id') id:string,@Body() dto:AdjustmentDto){return this.service.adjust(id,dto);}
  @Post('runs/:id/approve') approve(@Param('id') id:string,@Body() dto:ActorDto){return this.service.transition(id,dto.actorId,'APPROVED',dto.reason);}
  @Post('runs/:id/lock') lock(@Param('id') id:string,@Body() dto:ActorDto){return this.service.transition(id,dto.actorId,'LOCKED',dto.reason);}
  @Post('runs/:id/reopen') reopen(@Param('id') id:string,@Body() dto:ActorDto){return this.service.reopen(id,dto.actorId,dto.reason);}
  @Get('runs/:id/payslips/:employeeId') async payslip(@Param('id') id:string,@Param('employeeId') employeeId:string,@Query('actorId') actorId:string,@Res() response:Response){const pdf=await this.service.payslip(id,employeeId,actorId);response.set({'content-type':'application/pdf','content-disposition':`attachment; filename="payslip-${employeeId}.pdf"`,'cache-control':'private, no-store'}).send(pdf);}
}
