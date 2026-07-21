import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { RequestsService } from './requests.service';
import { CommentDto, CreateRequestDto, DecisionDto, DelegateDto } from './request.dto';
@Controller('requests') export class RequestsController {
  constructor(private readonly service:RequestsService){}
  @Post() create(@Body() dto:CreateRequestDto){return this.service.create(dto);}
  @Get() list(@Query('organizationId') organizationId?:string,@Query('employeeId') employeeId?:string,@Query('status') status?:string){return this.service.list({organizationId,employeeId,status});}
  @Get(':id') get(@Param('id') id:string){return this.service.get(id);}
  @Post(':id/decision') decide(@Param('id') id:string,@Body() dto:DecisionDto){return this.service.decide(id,dto);}
  @Post(':id/comments') comment(@Param('id') id:string,@Body() dto:CommentDto){return this.service.comment(id,dto);}
  @Post(':id/delegate') delegate(@Param('id') id:string,@Body() dto:DelegateDto){return this.service.delegate(id,dto);}
}
