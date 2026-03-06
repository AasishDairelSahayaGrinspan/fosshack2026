import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { MusicService } from './music.service.js';
import { MusicController } from './music.controller.js';

@Module({
  imports: [HttpModule],
  controllers: [MusicController],
  providers: [MusicService],
  exports: [MusicService],
})
export class MusicModule {}
