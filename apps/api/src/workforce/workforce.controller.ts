import { Body, Controller, Get, NotFoundException, Param, Post, Query, Req, UnauthorizedException } from '@nestjs/common';
import { IsEmail, IsInt, IsLatitude, IsLongitude, IsOptional, IsPositive, IsString, IsUUID, Max, Min } from 'class-validator';
import { PrismaService } from '../prisma.service';
import type { GeoAttendIdentity } from '../auth/auth.guard';

class EmployeeDto { @IsUUID() organizationId!:string; @IsString() employeeNumber!:string; @IsString() name!:string; @IsEmail() email!:string; @IsOptional() @IsUUID() worksiteId?:string; @IsOptional() @IsUUID() departmentId?:string; @IsOptional() @IsUUID() scheduleId?:string; }
class WorksiteDto { @IsUUID() organizationId!:string; @IsString() name!:string; @IsLatitude() latitude!:number; @IsLongitude() longitude!:number; @IsInt() @IsPositive() @Max(5000) radiusMeters!:number; @IsInt() @Min(1) @Max(1000) maxAccuracyMeters!:number; }
type AuthenticatedRequest = { user?: GeoAttendIdentity };

@Controller('workforce') export class WorkforceController {
  constructor(private readonly db:PrismaService){}
  @Get('session') async session(@Req() request:AuthenticatedRequest){
    const identity=request.user;
    if(!identity?.employeeId||!identity.organizationId) throw new UnauthorizedException('Employee identity is unavailable');
    const employee=await this.db.employee.findFirst({where:{id:identity.employeeId,organizationId:identity.organizationId,active:true},select:{id:true,organizationId:true,employeeNumber:true,name:true,email:true,role:true}});
    if(!employee) throw new NotFoundException('Active employee record not found');
    return {employee};
  }
  @Get('employees') employees(@Query('organizationId') organizationId:string){return this.db.employee.findMany({where:{organizationId,active:true},include:{worksite:true,department:true,schedule:true},orderBy:{name:'asc'}});}
  @Post('employees') createEmployee(@Body() dto:EmployeeDto){return this.db.employee.create({data:dto});}
  @Get('employees/:id/schedule') schedule(@Param('id') id:string){return this.db.employee.findUniqueOrThrow({where:{id},include:{worksite:true,schedule:{include:{shifts:true}}}});}
  @Get('worksites') worksites(@Query('organizationId') organizationId:string){return this.db.worksite.findMany({where:{organizationId},orderBy:{name:'asc'}});}
  @Post('worksites') createWorksite(@Body() dto:WorksiteDto){return this.db.worksite.create({data:dto});}
}
