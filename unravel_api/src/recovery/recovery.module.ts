import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RecoveryScore } from '../entities/recovery-score.entity.js';
import { HealthData } from '../entities/health-data.entity.js';
import { User } from '../entities/user.entity.js';
import { RecoveryService } from './recovery.service.js';
import { RecoveryController } from './recovery.controller.js';
import { RecoveryCron } from './recovery.cron.js';

@Module({
  imports: [TypeOrmModule.forFeature([RecoveryScore, HealthData, User])],
  controllers: [RecoveryController],
  providers: [RecoveryService, RecoveryCron],
  exports: [RecoveryService],
})
export class RecoveryModule {}
