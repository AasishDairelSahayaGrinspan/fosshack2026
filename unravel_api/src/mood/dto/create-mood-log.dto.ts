import { IsNumber, IsString, IsOptional } from 'class-validator';

export class CreateMoodLogDto {
  @IsNumber()
  valence!: number;

  @IsNumber()
  arousal!: number;

  @IsString()
  emotionWord!: string;

  @IsString()
  quadrant!: string;

  @IsOptional()
  @IsString()
  note?: string;
}
