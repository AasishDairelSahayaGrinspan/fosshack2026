import { IsString } from 'class-validator';

export class MoodPlaylistRequestDto {
  @IsString()
  quadrant!: string;

  @IsString()
  spotifyAccessToken!: string;
}
