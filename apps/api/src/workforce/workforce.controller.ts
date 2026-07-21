import { Body, Controller, ForbiddenException, Get, NotFoundException, Param, Patch, Post, Query, Req } from '@nestjs/common';
import { Role } from '@prisma/client';
import { IsBoolean, IsEmail, IsEnum, IsInt, IsLatitude, IsLongitude, IsOptional, IsPositive, IsString, IsUUID, Max, MaxLength, Min, MinLength } from 'class-validator';
import { PrismaService } from '../prisma.service';
import type { GeoAttendIdentity } from '../auth/auth.guard';

type AuthenticatedRequest = { user?: GeoAttendIdentity };
class EmployeeDto {
  @IsUUID() organizationId!: string;
  @IsString() @MinLength(2) @MaxLength(40) employeeNumber!: string;
  @IsString() @MinLength(2) @MaxLength(120) name!: string;
  @IsEmail() @MaxLength(200) email!: string;
  @IsOptional() @IsEnum(Role) role?: Role;
  @IsOptional() @IsUUID() worksiteId?: string;
  @IsOptional() @IsUUID() departmentId?: string;
  @IsOptional() @IsUUID() scheduleId?: string;
}
class EmployeeStatusDto { @IsBoolean() active!: boolean; }
class WorksiteDto { @IsUUID() organizationId!:string; @IsString() name!:string; @IsLatitude() latitude!:number; @IsLongitude() longitude!:number; @IsInt() @IsPositive() @Max(5000) radiusMeters!:number; @IsInt() @Min(1) @Max(1000) maxAccuracyMeters!:number; }
@Controller('workforce') export class WorkforceController {
  constructor(private readonly db:PrismaService){}
  @Get('employees') employees(@Query('organizationId') organizationId:string, @Query('status') status?:string){return this.db.employee.findMany({where:{organizationId,...(status === 'all' ? {} : {active:true})},include:{worksite:true,department:true,schedule:true,devices:{where:{active:true},select:{id:true}}},orderBy:{name:'asc'}});}
  @Post('employees') async createEmployee(@Body() dto:EmployeeDto, @Req() request:AuthenticatedRequest){
    this.requirePeopleAdmin(request.user);
    return this.db.$transaction(async transaction => {
      const employee = await transaction.employee.create({data:{...dto,email:dto.email.trim().toLowerCase(),employeeNumber:dto.employeeNumber.trim().toUpperCase(),name:dto.name.trim()}});
      await transaction.auditLog.create({data:{organizationId:dto.organizationId,actorId:request.user?.employeeId ?? request.user?.subject ?? 'system',action:'EMPLOYEE_CREATED',entityType:'Employee',entityId:employee.id,metadata:{employeeNumber:employee.employeeNumber,email:employee.email,role:employee.role}}});
      return employee;
    });
  }
  @Patch('employees/:id/status') async updateEmployeeStatus(@Param('id') id:string, @Body() dto:EmployeeStatusDto, @Req() request:AuthenticatedRequest){
    this.requirePeopleAdmin(request.user);
    const employee = await this.db.employee.findUnique({where:{id}});
    if (!employee) throw new NotFoundException('Employee not found');
    if (request.user?.organizationId && request.user.organizationId !== employee.organizationId) throw new ForbiddenException('Cross-organization access denied');
    if (!dto.active && request.user?.employeeId === id) throw new ForbiddenException('You cannot suspend your own account');
    return this.db.$transaction(async transaction => {
      const updated = await transaction.employee.update({where:{id},data:{active:dto.active}});
      await transaction.auditLog.create({data:{organizationId:employee.organizationId,actorId:request.user?.employeeId ?? request.user?.subject ?? 'system',action:dto.active ? 'EMPLOYEE_ACTIVATED' : 'EMPLOYEE_SUSPENDED',entityType:'Employee',entityId:id,metadata:{employeeNumber:employee.employeeNumber}}});
      return updated;
    });
  }
  @Get('employees/:id/schedule') schedule(@Param('id') id:string){return this.db.employee.findUniqueOrThrow({where:{id},include:{worksite:true,schedule:{include:{shifts:true}}}});}
  @Get('worksites') worksites(@Query('organizationId') organizationId:string){return this.db.worksite.findMany({where:{organizationId},orderBy:{name:'asc'}});}
  @Post('worksites') createWorksite(@Body() dto:WorksiteDto){return this.db.worksite.create({data:dto});}

  private requirePeopleAdmin(identity?:GeoAttendIdentity){
    const role = identity?.role?.replace(/^org:/u, '').replaceAll(' ', '_').toUpperCase();
    if (!role || !['ADMIN','SUPER_ADMIN','HR'].includes(role)) throw new ForbiddenException('Administrator or HR access required');
  }
}
