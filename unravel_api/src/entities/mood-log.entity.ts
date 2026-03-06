import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity.js';

@Entity('mood_logs')
export class MoodLog {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, (u) => u.moodLogs)
  user!: User;

  @Column('uuid')
  userId!: string;

  @Column('float')
  valence!: number;

  @Column('float')
  arousal!: number;

  @Column()
  emotionWord!: string;

  @Column()
  quadrant!: string;

  @Column({ type: 'text', nullable: true })
  note!: string | null;

  @CreateDateColumn()
  timestamp!: Date;
}
