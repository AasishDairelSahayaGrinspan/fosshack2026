import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { databaseConfig } from './config/database.config.js';
import { AuthModule } from './auth/auth.module.js';
import { MoodModule } from './mood/mood.module.js';
import { JournalModule } from './journal/journal.module.js';
import { RecoveryModule } from './recovery/recovery.module.js';
import { CommunityModule } from './community/community.module.js';
import { MusicModule } from './music/music.module.js';
import { StreakModule } from './streak/streak.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: databaseConfig,
    }),
    ScheduleModule.forRoot(),
    AuthModule,
    MoodModule,
    JournalModule,
    RecoveryModule,
    CommunityModule,
    MusicModule,
    StreakModule,
  ],
})
export class AppModule {}
