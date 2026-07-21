import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { IsEmail, IsInt, IsLatitude, IsLongitude, IsOptional, IsPositive, IsString, IsUUID, Max, Min } from 'class-validator';
import { PrismaService } from '../prisma.service';
class EmployeeDto { @IsUUID() organizationId!:string; @IsString() employeeNumber!:string; @IsString() name!:string; @IsEmail() email!:string; @IsOptional() @IsUUID() worksiteId?:string; @IsOptional() @IsUUID() departmentId?:string; @IsOptional() @IsUUID() scheduleId?:string; }
class WorksiteDto { @IsUUID() organizationId!:string; @IsString() name!:string; @IsLatitude() latitude!:number; @IsLongitude() longitude!:number; @IsInt() @IsPositive() @Max(5000) radiusMeters!:number; @IsInt() @Min(1) @Max(1000) maxAccuracyMeters!:number; }
@Controller('workforce') export class WorkforceController {
  constructor(private readonly db:PrismaService){}
  @Get('employees') employees(@Query('organizationId') organizationId:string){return this.db.employee.findMany({where:{organizationId,active:true},include:{worksite:true,department:true,schedule:true},orderBy:{name:'asc'}});}
  @Post('employees') createEmployee(@Body() dto:EmployeeDto){return this.db.employee.create({data:dto});}
  @Get('employees/:id/schedule') schedule(@Param('id') id:string){return this.db.employee.findUniqueOrThrow({where:{id},include:{worksite:true,schedule:{include:{shifts:true}}}});}
  @Get('worksites') worksites(@Query('organizationId') organizationId:string){return this.db.worksite.findMany({where:{organizationId},orderBy:{name:'asc'}});}
  @Post('worksites') createWorksite(@Body() dto:WorksiteDto){return this.db.worksite.create({data:dto});}
}
