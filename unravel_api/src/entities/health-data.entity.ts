import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('health_data')
export class HealthData {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid')
  userId!: string;

  @Column({ type: 'date' })
  date!: string;

  @Column({ type: 'float', nullable: true })
  hrv!: number | null;

  @Column({ type: 'float', nullable: true })
  rhr!: number | null;

  @Column({ type: 'float', nullable: true })
  deepSleepMinutes!: number | null;

  @Column({ type: 'float', nullable: true })
  remSleepMinutes!: number | null;

  @Column({ type: 'float', nullable: true })
  lightSleepMinutes!: number | null;

  @CreateDateColumn()
  createdAt!: Date;
}
