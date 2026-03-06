import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity.js';

@Injectable()
export class StreakService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async recordLogin(userId: string): Promise<{ currentStreak: number }> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    user.currentStreak += 1;
    await this.userRepository.save(user);

    return { currentStreak: user.currentStreak };
  }

  async getStreak(userId: string): Promise<{ currentStreak: number }> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return { currentStreak: user.currentStreak };
  }
}
