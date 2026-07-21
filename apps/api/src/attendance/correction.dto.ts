import { IsIn, IsString, IsUUID } from 'class-validator';
export class CorrectionDto {
  @IsUUID() originalEventId!:string;
  @IsIn(['CLOCK_IN','BREAK_START','BREAK_END','CLOCK_OUT']) kind!:'CLOCK_IN'|'BREAK_START'|'BREAK_END'|'CLOCK_OUT';
  @IsString() reason!:string;
  @IsString() idempotencyKey!:string;
}
