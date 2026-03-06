import {
  IsString,
  IsArray,
  IsOptional,
  IsUUID,
} from 'class-validator';

export class CreateJournalDto {
  @IsString()
  content!: string;

  @IsArray()
  @IsString({ each: true })
  tags!: string[];

  @IsOptional()
  @IsUUID()
  moodLogId?: string;
}
