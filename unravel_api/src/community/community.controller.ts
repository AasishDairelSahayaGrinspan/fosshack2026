import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { CommunityService } from './community.service.js';
import { AcceptInviteDto } from './dto/accept-invite.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { User } from '../entities/user.entity.js';

interface AuthenticatedRequest extends Request {
  user: User;
}

@Controller('community')
@UseGuards(JwtAuthGuard)
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Post('invite')
  async createInvite(@Req() req: AuthenticatedRequest) {
    return this.communityService.createInvite(req.user.id);
  }

  @Post('accept')
  async acceptInvite(
    @Req() req: AuthenticatedRequest,
    @Body() dto: AcceptInviteDto,
  ) {
    return this.communityService.acceptInvite(req.user.id, dto.encryptedCode);
  }

  @Get('friends')
  async getFriends(@Req() req: AuthenticatedRequest) {
    return this.communityService.getFriends(req.user.id);
  }

  @Get('moods')
  async getFriendMoods(@Req() req: AuthenticatedRequest) {
    return this.communityService.getFriendMoods(req.user.id);
  }

  @Patch(':id/sharing')
  async toggleMoodSharing(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body('enabled') enabled: boolean,
  ) {
    await this.communityService.toggleMoodSharing(id, req.user.id, enabled);
    return { success: true };
  }
}
