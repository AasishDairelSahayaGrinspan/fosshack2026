import { IsDateString, IsOptional, IsNumber } from 'class-validator';

export class SubmitHealthDataDto {
  @IsDateString()
  date!: string;

  @IsOptional()
  @IsNumber()
  hrv?: number;

  @IsOptional()
  @IsNumber()
  rhr?: number;

  @IsOptional()
  @IsNumber()
  deepSleepMinutes?: number;

  @IsOptional()
  @IsNumber()
  remSleepMinutes?: number;

  @IsOptional()
  @IsNumber()
  lightSleepMinutes?: number;
}
