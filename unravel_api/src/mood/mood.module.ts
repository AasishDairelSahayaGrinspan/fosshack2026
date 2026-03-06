import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MoodLog } from '../entities/mood-log.entity.js';
import { MoodService } from './mood.service.js';
import { MoodController } from './mood.controller.js';

@Module({
  imports: [TypeOrmModule.forFeature([MoodLog])],
  controllers: [MoodController],
  providers: [MoodService],
  exports: [MoodService],
})
export class MoodModule {}
