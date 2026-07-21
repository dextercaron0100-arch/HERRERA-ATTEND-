import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsDateString, IsInt, IsNumberString, IsOptional, IsString, IsUUID, Max, Min, ValidateNested } from 'class-validator';

export class CreatePilotDto {
  @IsUUID() organizationId!: string;
  @IsUUID() actorId!: string;
  @IsString() name!: string;
  @IsOptional() @IsUUID() worksiteId?: string;
  @IsNumberString() tolerance!: string;
  @IsInt() @Min(2) @Max(12) targetCycles = 2;
  @IsDateString() startsAt!: string;
  @IsArray() @ArrayMinSize(1) @IsUUID('4', { each: true }) employeeIds!: string[];
}

export class CreateCycleDto {
  @IsUUID() actorId!: string;
  @IsUUID() payrollRunId!: string;
}

export class ReferenceLineDto {
  @IsUUID() employeeId!: string;
  @IsString() code!: string;
  @IsNumberString() trustedAmount!: string;
  @IsOptional() @IsString() explanation?: string;
}

export class ReconcileCycleDto {
  @IsUUID() actorId!: string;
  @IsArray() @ArrayMinSize(1) @ValidateNested({ each: true }) @Type(() => ReferenceLineDto) lines!: ReferenceLineDto[];
}

export class SignOffDto {
  @IsUUID() actorId!: string;
  @IsOptional() @IsString() notes?: string;
}
