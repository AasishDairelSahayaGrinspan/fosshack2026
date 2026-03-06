import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JournalEntry } from '../entities/journal-entry.entity.js';
import { CreateJournalDto } from './dto/create-journal.dto.js';

@Injectable()
export class JournalService {
  constructor(
    @InjectRepository(JournalEntry)
    private readonly journalRepository: Repository<JournalEntry>,
  ) {}

  async create(
    userId: string,
    dto: CreateJournalDto,
  ): Promise<JournalEntry> {
    const entry = this.journalRepository.create({
      userId,
      content: dto.content,
      tags: dto.tags,
      moodLogId: dto.moodLogId ?? null,
    });
    return this.journalRepository.save(entry);
  }

  async findByUser(userId: string): Promise<JournalEntry[]> {
    return this.journalRepository.find({
      where: { userId },
      order: { timestamp: 'DESC' },
    });
  }

  async findOne(id: string): Promise<JournalEntry> {
    const entry = await this.journalRepository.findOne({ where: { id } });
    if (!entry) {
      throw new NotFoundException('Journal entry not found');
    }
    return entry;
  }
}
