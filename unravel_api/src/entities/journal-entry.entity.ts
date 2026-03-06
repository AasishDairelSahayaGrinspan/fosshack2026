import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity.js';

@Entity('journal_entries')
export class JournalEntry {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User)
  user!: User;

  @Column('uuid')
  userId!: string;

  @Column({ type: 'text' })
  content!: string;

  @Column('simple-array')
  tags!: string[];

  @Column({ type: 'uuid', nullable: true })
  moodLogId!: string | null;

  @CreateDateColumn()
  timestamp!: Date;
}
