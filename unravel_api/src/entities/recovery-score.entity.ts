import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity.js';

@Entity('recovery_scores')
export class RecoveryScore {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User)
  user!: User;

  @Column('uuid')
  userId!: string;

  @Column('float')
  score!: number;

  @Column({ type: 'float', nullable: true })
  hrvZScore!: number | null;

  @Column({ type: 'float', nullable: true })
  rhrZScore!: number | null;

  @Column({ type: 'float', nullable: true })
  sleepZScore!: number | null;

  @Column({ type: 'date' })
  date!: string;

  @CreateDateColumn()
  createdAt!: Date;
}
