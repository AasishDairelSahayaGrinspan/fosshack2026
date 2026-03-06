import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { MoodLog } from '../entities/mood-log.entity.js';
import { CreateMoodLogDto } from './dto/create-mood-log.dto.js';

export interface MoodLogQueryOptions {
  startDate?: Date;
  endDate?: Date;
}

@Injectable()
export class MoodService {
  constructor(
    @InjectRepository(MoodLog)
    private readonly moodLogRepository: Repository<MoodLog>,
  ) {}

  async create(userId: string, dto: CreateMoodLogDto): Promise<MoodLog> {
    const moodLog = this.moodLogRepository.create({
      userId,
      valence: dto.valence,
      arousal: dto.arousal,
      emotionWord: dto.emotionWord,
      quadrant: dto.quadrant,
      note: dto.note ?? null,
    });
    return this.moodLogRepository.save(moodLog);
  }

  async findByUser(
    userId: string,
    options?: MoodLogQueryOptions,
  ): Promise<MoodLog[]> {
    const where: Record<string, unknown> = { userId };

    if (options?.startDate && options?.endDate) {
      where['timestamp'] = Between(options.startDate, options.endDate);
    }

    return this.moodLogRepository.find({
      where,
      order: { timestamp: 'DESC' },
    });
  }

  async findOne(id: string): Promise<MoodLog> {
    const moodLog = await this.moodLogRepository.findOne({ where: { id } });
    if (!moodLog) {
      throw new NotFoundException('Mood log not found');
    }
    return moodLog;
  }
}
