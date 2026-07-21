import { IsDateString, IsIn, IsObject, IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
export class CreateRequestDto {
  @IsUUID() employeeId!:string;
  @IsIn(['LEAVE','OVERTIME','ATTENDANCE_CORRECTION','REMOTE_WORK','FIELD_ASSIGNMENT']) type!:string;
  @IsDateString() startsAt!:string;
  @IsDateString() endsAt!:string;
  @IsString() @MinLength(3) @MaxLength(2000) reason!:string;
  @IsOptional() @IsObject() evidence:Record<string,unknown>={};
}
export class DecisionDto { @IsUUID() actorId!:string; @IsIn(['APPROVED','REJECTED']) decision!:'APPROVED'|'REJECTED'; @IsOptional() @IsString() @MaxLength(1000) comment?:string; }
export class CommentDto { @IsUUID() authorId!:string; @IsString() @MinLength(1) @MaxLength(2000) body!:string; }
export class DelegateDto { @IsUUID() actorId!:string; @IsUUID() delegateId!:string; }
