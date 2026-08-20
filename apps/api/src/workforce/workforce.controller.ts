import { Body, Controller, ForbiddenException, Get, NotFoundException, Param, Patch, Post, Query, Req, UnauthorizedException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { IsBoolean, IsEmail, IsEnum, IsInt, IsLatitude, IsLongitude, IsNumber, IsOptional, IsPositive, IsString, IsUUID, Max, MaxLength, Min, MinLength, ValidateIf } from 'class-validator';
import { PrismaService } from '../prisma.service';
import type { GeoAttendIdentity } from '../auth/auth.guard';
import { decideMobileLogin, distanceMeters } from '../attendance/geofence';

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
class EmployeeWorksiteDto { @ValidateIf((_object,value)=>value!==null) @IsUUID() worksiteId!: string | null; }
class WorksiteDto { @IsUUID() organizationId!:string; @IsString() @MinLength(2) @MaxLength(120) name!:string; @IsLatitude() latitude!:number; @IsLongitude() longitude!:number; @IsInt() @IsPositive() @Max(5000) radiusMeters!:number; @IsInt() @Min(1) @Max(1000) maxAccuracyMeters!:number; }
class MobileLoginLocationDto { @IsLatitude() latitude!:number; @IsLongitude() longitude!:number; @IsNumber() @Min(0) @Max(10000) accuracyMeters!:number; }

@Controller('workforce') export class WorkforceController {
  constructor(private readonly db:PrismaService){}
  @Get('session') async session(@Req() request:AuthenticatedRequest){
    const identity=request.user;
    if(!identity?.employeeId||!identity.organizationId) throw new UnauthorizedException('Employee identity is unavailable');
    const employee=await this.db.employee.findFirst({where:{id:identity.employeeId,organizationId:identity.organizationId,active:true},select:{id:true,organizationId:true,employeeNumber:true,name:true,email:true,role:true,worksite:{select:{id:true,name:true}}}});
    if(!employee) throw new NotFoundException('Active employee record not found');
    return {employee};
  }
  @Post('mobile-session') async mobileSession(@Body() dto:MobileLoginLocationDto, @Req() request:AuthenticatedRequest){
    const identity=request.user;
    if(!identity?.employeeId||!identity.organizationId) throw new UnauthorizedException('Employee identity is unavailable');
    const employee=await this.db.employee.findFirst({where:{id:identity.employeeId,organizationId:identity.organizationId,active:true},select:{id:true,organizationId:true,employeeNumber:true,name:true,email:true,role:true,worksite:{select:{id:true,name:true,latitude:true,longitude:true,radiusMeters:true,maxAccuracyMeters:true}}}});
    if(!employee) throw new NotFoundException('Active employee record not found');
    if(!employee.worksite) throw new ForbiddenException('No worksite is assigned to this employee. Contact HR before signing in.');
    const distance=distanceMeters(dto.latitude,dto.longitude,Number(employee.worksite.latitude),Number(employee.worksite.longitude));
    const outcome=decideMobileLogin(distance,employee.worksite.radiusMeters,dto.accuracyMeters,employee.worksite.maxAccuracyMeters);
    if(!outcome.allowed){
      if(outcome.reasonCode==='LOW_GPS_ACCURACY') throw new ForbiddenException(`GPS accuracy must be within ${employee.worksite.maxAccuracyMeters} meters. Move to an open area and try again.`);
      throw new ForbiddenException(`You must be within ${employee.worksite.radiusMeters} meters of ${employee.worksite.name} to sign in.`);
    }
    const {worksite,...employeeDetails}=employee;
    return {employee:{...employeeDetails,worksite:{id:worksite.id,name:worksite.name}},locationVerification:{allowed:true,distanceMeters:Math.round(distance),accuracyMeters:dto.accuracyMeters,radiusMeters:worksite.radiusMeters}};
  }
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
  @Patch('employees/:id/worksite') async updateEmployeeWorksite(@Param('id') id:string, @Body() dto:EmployeeWorksiteDto, @Req() request:AuthenticatedRequest){
    this.requirePeopleAdmin(request.user);
    const employee=await this.db.employee.findUnique({where:{id}});
    if(!employee) throw new NotFoundException('Employee not found');
    if(request.user?.organizationId&&request.user.organizationId!==employee.organizationId) throw new ForbiddenException('Cross-organization access denied');
    if(dto.worksiteId){
      const worksite=await this.db.worksite.findFirst({where:{id:dto.worksiteId,organizationId:employee.organizationId}});
      if(!worksite) throw new NotFoundException('Worksite not found in this organization');
    }
    return this.db.$transaction(async transaction=>{
      const updated=await transaction.employee.update({where:{id},data:{worksiteId:dto.worksiteId??null},include:{worksite:true,department:true,schedule:true,devices:{where:{active:true},select:{id:true}}}});
      await transaction.auditLog.create({data:{organizationId:employee.organizationId,actorId:request.user?.employeeId??request.user?.subject??'system',action:'EMPLOYEE_WORKSITE_UPDATED',entityType:'Employee',entityId:id,metadata:{employeeNumber:employee.employeeNumber,previousWorksiteId:employee.worksiteId,worksiteId:dto.worksiteId??null}}});
      return updated;
    });
  }
  @Get('employees/:id/schedule') schedule(@Param('id') id:string){return this.db.employee.findUniqueOrThrow({where:{id},include:{worksite:true,schedule:{include:{shifts:true}}}});}
  @Get('worksites') worksites(@Query('organizationId') organizationId:string){return this.db.worksite.findMany({where:{organizationId},orderBy:{name:'asc'}});}
  @Post('worksites') createWorksite(@Body() dto:WorksiteDto, @Req() request:AuthenticatedRequest){this.requirePeopleAdmin(request.user);this.requireSameOrganization(request.user,dto.organizationId);return this.db.worksite.create({data:{...dto,name:dto.name.trim()}});}
  @Patch('worksites/:id') async updateWorksite(@Param('id') id:string, @Body() dto:WorksiteDto, @Req() request:AuthenticatedRequest){
    this.requirePeopleAdmin(request.user);
    this.requireSameOrganization(request.user,dto.organizationId);
    const worksite=await this.db.worksite.findUnique({where:{id}});
    if(!worksite) throw new NotFoundException('Worksite not found');
    if(worksite.organizationId!==dto.organizationId) throw new ForbiddenException('Cross-organization access denied');
    return this.db.worksite.update({where:{id},data:{name:dto.name.trim(),latitude:dto.latitude,longitude:dto.longitude,radiusMeters:dto.radiusMeters,maxAccuracyMeters:dto.maxAccuracyMeters}});
  }

  private requirePeopleAdmin(identity?:GeoAttendIdentity){
    const role = identity?.role?.replace(/^org:/u, '').replaceAll(' ', '_').toUpperCase();
    if (!role || !['ADMIN','SUPER_ADMIN','HR'].includes(role)) throw new ForbiddenException('Administrator or HR access required');
  }
  private requireSameOrganization(identity:GeoAttendIdentity|undefined, organizationId:string){
    if(identity?.organizationId&&identity.organizationId!==organizationId) throw new ForbiddenException('Cross-organization access denied');
  }
}
