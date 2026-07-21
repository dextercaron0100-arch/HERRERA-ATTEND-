import { IsDateString, IsIn, IsNumberString, IsObject, IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
export class PolicyDto { @IsUUID() organizationId!:string; @IsString() name!:string; @IsDateString() effectiveFrom!:string; @IsString() currency!:string; @IsObject() rules!:Record<string,unknown>; @IsUUID() actorId!:string; }
export class ActorDto { @IsUUID() actorId!:string; @IsOptional() @IsString() @MaxLength(1000) reason?:string; }
export class CreateRunDto { @IsUUID() organizationId!:string; @IsDateString() periodStart!:string; @IsDateString() periodEnd!:string; @IsUUID() policyId!:string; @IsUUID() actorId!:string; }
export class AdjustmentDto { @IsUUID() actorId!:string; @IsUUID() employeeId!:string; @IsString() code!:string; @IsString() description!:string; @IsNumberString() amount!:string; @IsString() @MinLength(3) @MaxLength(1000) reason!:string; }
