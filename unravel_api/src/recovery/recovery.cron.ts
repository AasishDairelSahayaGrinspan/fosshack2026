import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity.js';
import { RecoveryService } from './recovery.service.js';

@Injectable()
export class RecoveryCron {
  constructor(
    private readonly recoveryService: RecoveryService,
    @InjectRepository(User) private readonly userRepo: Repository<User>,
  ) {}

  @Cron('0 4 * * *')
  async computeAllScores(): Promise<void> {
    const users = await this.userRepo.find();
    for (const user of users) {
      try {
        await this.recoveryService.computeAndStore(user.id);
      } catch (error) {
        console.error(`Failed to compute recovery for user ${user.id}:`, error);
      }
    }
  }
}
