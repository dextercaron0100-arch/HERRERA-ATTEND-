import { Controller,Get,Param,Query,Res } from '@nestjs/common';
import type { Response } from 'express';
import { ReportsService } from './reports.service';
@Controller('reports') export class ReportsController{constructor(private readonly service:ReportsService){}@Get(':type')async export(@Param('type')type:string,@Query()query:Record<string,string>,@Res()response:Response){const result=await this.service.export(type,query);response.set({'content-type':result.contentType,'content-disposition':`attachment; filename="${result.filename}"`,'cache-control':'private, no-store','x-report-rows':String(result.rowCount)}).send(result.body);}}
