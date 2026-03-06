import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('friendships')
export class Friendship {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid')
  requesterId!: string;

  @Column({ type: 'uuid', nullable: true })
  addresseeId!: string | null;

  @Column({ default: 'pending' })
  status!: string;

  @Column({ type: 'text', nullable: true })
  encryptedInviteCode!: string | null;

  @Column({ default: false })
  moodSharingEnabled!: boolean;

  @CreateDateColumn()
  createdAt!: Date;
}
