import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../entities/user.entity.js';
import { StreakService } from './streak.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [StreakService],
  exports: [StreakService],
})
export class StreakModule {}
