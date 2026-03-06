import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToMany,
} from 'typeorm';
import { MoodLog } from './mood-log.entity.js';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  email!: string;

  @Column()
  passwordHash!: string;

  @Column()
  displayName!: string;

  @Column({ default: false })
  noAdviceMode!: boolean;

  @Column({ default: 0 })
  currentStreak!: number;

  @CreateDateColumn()
  createdAt!: Date;

  @OneToMany(() => MoodLog, (ml) => ml.user)
  moodLogs!: MoodLog[];
}
