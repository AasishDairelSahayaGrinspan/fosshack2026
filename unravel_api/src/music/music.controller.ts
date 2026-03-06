import {
  Controller,
  Post,
  Body,
  UseGuards,
} from '@nestjs/common';
import { MusicService } from './music.service.js';
import { MoodPlaylistRequestDto } from './dto/mood-playlist-request.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';

@Controller('music')
@UseGuards(JwtAuthGuard)
export class MusicController {
  constructor(private readonly musicService: MusicService) {}

  @Post('playlist')
  async generatePlaylist(@Body() dto: MoodPlaylistRequestDto) {
    const playlistUrl = await this.musicService.generatePlaylist(
      dto.quadrant,
      dto.spotifyAccessToken,
    );
    return { playlistUrl };
  }
}
