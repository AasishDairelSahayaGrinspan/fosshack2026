import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual } from 'typeorm';
import { RecoveryScore } from '../entities/recovery-score.entity.js';
import { HealthData } from '../entities/health-data.entity.js';
import { SubmitHealthDataDto } from './dto/submit-health-data.dto.js';

@Injectable()
export class RecoveryService {
  constructor(
    @InjectRepository(RecoveryScore) private scoreRepo: Repository<RecoveryScore>,
    @InjectRepository(HealthData) private healthRepo: Repository<HealthData>,
  ) {}

  async submitHealthData(userId: string, dto: SubmitHealthDataDto): Promise<HealthData> {
    const entry = this.healthRepo.create({ userId, ...dto });
    return this.healthRepo.save(entry);
  }

  async computeAndStore(userId: string): Promise<RecoveryScore> {
    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);

    const healthData = await this.healthRepo.find({
      where: { userId, createdAt: MoreThanOrEqual(fourteenDaysAgo) },
      order: { createdAt: 'ASC' },
    });

    const hrvValues = healthData.map(d => d.hrv).filter((v): v is number => v !== null);
    const rhrValues = healthData.map(d => d.rhr).filter((v): v is number => v !== null);
    const sleepValues = healthData
      .map(d => (d.deepSleepMinutes ?? 0) + (d.remSleepMinutes ?? 0))
      .filter(v => v > 0);

    const hrvZ = this.latestZScore(hrvValues);
    const rhrZ = -this.latestZScore(rhrValues); // lower RHR = better, so negate
    const sleepZ = this.latestZScore(sleepValues);

    const validScores = [hrvZ, rhrZ, sleepZ].filter(z => z !== 0);
    const avgZ = validScores.length > 0
      ? validScores.reduce((a, b) => a + b, 0) / validScores.length
      : 0;

    const score = Math.max(0, Math.min(100, 50 + avgZ * 15));

    const entry = this.scoreRepo.create({
      userId,
      score,
      hrvZScore: hrvZ,
      rhrZScore: rhrZ,
      sleepZScore: sleepZ,
      date: new Date().toISOString().split('T')[0],
    });

    return this.scoreRepo.save(entry);
  }

  private latestZScore(values: number[]): number {
    if (values.length < 2) return 0;
    const mean = values.reduce((a, b) => a + b, 0) / values.length;
    const variance = values.reduce((sum, v) => sum + (v - mean) ** 2, 0) / values.length;
    const stdDev = Math.sqrt(variance);
    if (stdDev === 0) return 0;
    return (values[values.length - 1] - mean) / stdDev;
  }

  async getLatestScore(userId: string): Promise<RecoveryScore | null> {
    return this.scoreRepo.findOne({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async getScoreHistory(userId: string, days: number = 7): Promise<RecoveryScore[]> {
    const since = new Date();
    since.setDate(since.getDate() - days);
    return this.scoreRepo.find({
      where: { userId, createdAt: MoreThanOrEqual(since) },
      order: { createdAt: 'ASC' },
    });
  }
}
