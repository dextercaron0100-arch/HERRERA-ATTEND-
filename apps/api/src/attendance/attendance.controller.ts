import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { AttendanceService } from './attendance.service'; import { ClockDto } from './clock.dto';
import { CorrectionDto } from './correction.dto';
@Controller('attendance') export class AttendanceController {
  constructor(private readonly service:AttendanceService){}
  @Post('events') clock(@Body() dto:ClockDto){return this.service.clock(dto);}
  @Post('corrections') correct(@Body() dto:CorrectionDto){return this.service.correct(dto);}
  @Post('summaries/:employeeId') summarize(@Param('employeeId') employeeId:string,@Query('date') date:string){return this.service.summarizeDay(employeeId,date);}
  @Get('summaries') summaries(@Query('organizationId') organizationId:string,@Query('date') date:string){return this.service.listSummaries(organizationId,date);}
  @Get('exceptions') exceptions(@Query('organizationId') organizationId:string,@Query('status') status='OPEN'){return this.service.listExceptions(organizationId,status);}
  @Post('exceptions/:id/resolve') resolveException(@Param('id') id:string,@Body() body:{actorId:string;status?:'RESOLVED'|'DISMISSED'}){return this.service.resolveException(id,body.actorId,body.status??'RESOLVED');}
}
