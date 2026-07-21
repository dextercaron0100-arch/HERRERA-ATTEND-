import { IsBoolean, IsIn, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class MobileLoginDto {
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  username!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(200)
  password!: string;
}

export class RegisterDeviceDto {
  @IsUUID() employeeId!: string;
  @IsString() @MinLength(8) @MaxLength(200) deviceId!: string;
  @IsString() @MinLength(3) @MaxLength(100) name!: string;
  @IsIn(['android', 'ios']) platform!: string;
  @IsBoolean() biometricsEnabled!: boolean;
  @IsString() @MinLength(6) @MaxLength(6) verificationCode!: string;
}
