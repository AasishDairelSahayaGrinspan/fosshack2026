import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Friendship } from '../entities/friendship.entity.js';
import { User } from '../entities/user.entity.js';
import { MoodLog } from '../entities/mood-log.entity.js';
import { ConfigService } from '@nestjs/config';
import { createCipheriv } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class CommunityService {
  constructor(
    @InjectRepository(Friendship) private friendRepo: Repository<Friendship>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(MoodLog) private moodRepo: Repository<MoodLog>,
    private configService: ConfigService,
  ) {}

  async createInvite(requesterId: string): Promise<{ encryptedCode: string }> {
    const rawCode = `${requesterId}:${uuidv4()}`;
    const encrypted = this.encrypt(rawCode);
    const friendship = this.friendRepo.create({
      requesterId,
      addresseeId: '',
      encryptedInviteCode: encrypted,
      status: 'pending',
    });
    await this.friendRepo.save(friendship);
    return { encryptedCode: encrypted };
  }

  async acceptInvite(addresseeId: string, encryptedCode: string): Promise<Friendship> {
    const friendship = await this.friendRepo.findOneBy({
      encryptedInviteCode: encryptedCode,
      status: 'pending',
    });
    if (!friendship) throw new NotFoundException('Invalid or expired invite code');
    friendship.addresseeId = addresseeId;
    friendship.status = 'accepted';
    return this.friendRepo.save(friendship);
  }

  async getFriends(userId: string): Promise<Array<{ id: string; friendId: string; displayName: string; moodSharingEnabled: boolean }>> {
    const friendships = await this.friendRepo.find({
      where: [
        { requesterId: userId, status: 'accepted' },
        { addresseeId: userId, status: 'accepted' },
      ],
    });

    const results = [];
    for (const f of friendships) {
      const friendId = f.requesterId === userId ? f.addresseeId : f.requesterId;
      if (!friendId) continue;
      const friend = await this.userRepo.findOneBy({ id: friendId });
      if (friend) {
        results.push({
          id: f.id,
          friendId: friendId,
          displayName: friend.displayName,
          moodSharingEnabled: f.moodSharingEnabled,
        });
      }
    }
    return results;
  }

  async getFriendMoods(userId: string): Promise<Array<{ friendId: string; displayName: string; quadrant: string | null }>> {
    const friends = await this.getFriends(userId);
    const results = [];
    for (const f of friends) {
      if (!f.moodSharingEnabled) {
        results.push({ friendId: f.friendId!, displayName: f.displayName, quadrant: null });
        continue;
      }
      const latestMood = await this.moodRepo.findOne({
        where: { userId: f.friendId! },
        order: { timestamp: 'DESC' },
      });
      results.push({
        friendId: f.friendId!,
        displayName: f.displayName,
        quadrant: latestMood?.quadrant ?? null,
      });
    }
    return results;
  }

  async toggleMoodSharing(friendshipId: string, userId: string, enabled: boolean): Promise<void> {
    const f = await this.friendRepo.findOneBy({ id: friendshipId });
    if (!f) throw new NotFoundException();
    if (f.requesterId !== userId && f.addresseeId !== userId) throw new ForbiddenException();
    f.moodSharingEnabled = enabled;
    await this.friendRepo.save(f);
  }

  private encrypt(text: string): string {
    const key = Buffer.from(this.configService.get<string>('INVITE_SECRET_KEY')!, 'hex');
    const iv = Buffer.from(this.configService.get<string>('INVITE_IV')!, 'hex');
    const cipher = createCipheriv('aes-256-cbc', key, iv);
    return cipher.update(text, 'utf8', 'base64') + cipher.final('base64');
  }
}
