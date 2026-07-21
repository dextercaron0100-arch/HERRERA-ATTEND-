import { IsDateString, IsIn, IsLatitude, IsLongitude, IsNumber, IsPositive, IsString, IsUUID, Max } from 'class-validator';
export class ClockDto {
  @IsUUID() employeeId!:string; @IsUUID() worksiteId!:string;
  @IsIn(['CLOCK_IN','BREAK_START','BREAK_END','CLOCK_OUT']) kind!:'CLOCK_IN'|'BREAK_START'|'BREAK_END'|'CLOCK_OUT';
  @IsDateString() capturedAt!:string; @IsLatitude() latitude!:number; @IsLongitude() longitude!:number;
  @IsNumber() @IsPositive() @Max(10000) accuracyMeters!:number;
  @IsString() idempotencyKey!:string; @IsString() deviceId!:string;
}
