import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Friendship } from '../entities/friendship.entity.js';
import { User } from '../entities/user.entity.js';
import { MoodLog } from '../entities/mood-log.entity.js';
import { CommunityService } from './community.service.js';
import { CommunityController } from './community.controller.js';

@Module({
  imports: [TypeOrmModule.forFeature([Friendship, User, MoodLog])],
  controllers: [CommunityController],
  providers: [CommunityService],
  exports: [CommunityService],
})
export class CommunityModule {}
