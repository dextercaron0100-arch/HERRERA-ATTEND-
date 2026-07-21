import { IsArray, IsDateString, IsOptional, IsString, IsUUID, Length, Matches } from 'class-validator';

const money = /^\d{1,12}(\.\d{1,4})?$/;

export class CreateCompensationDto {
  @IsUUID() organizationId!: string;
  @IsUUID() employeeId!: string;
  @IsUUID() actorId!: string;
  @IsDateString() effectiveFrom!: string;
  @IsOptional() @IsDateString() effectiveTo?: string;
  @IsString() @Length(3, 3) @Matches(/^[A-Z]{3}$/) currency = 'PHP';
  @IsString() @Matches(money) monthlyBase!: string;
  @IsOptional() @IsString() @Matches(money) hourlyRate?: string;
  @IsArray() allowances: unknown[] = [];
  @IsArray() deductions: unknown[] = [];
}

export class UpdateCompensationDto {
  @IsUUID() organizationId!: string;
  @IsUUID() actorId!: string;
  @IsOptional() @IsDateString() effectiveFrom?: string;
  @IsOptional() @IsDateString() effectiveTo?: string;
  @IsOptional() @IsString() @Length(3, 3) @Matches(/^[A-Z]{3}$/) currency?: string;
  @IsOptional() @IsString() @Matches(money) monthlyBase?: string;
  @IsOptional() @IsString() @Matches(money) hourlyRate?: string;
  @IsOptional() @IsArray() allowances?: unknown[];
  @IsOptional() @IsArray() deductions?: unknown[];
}
