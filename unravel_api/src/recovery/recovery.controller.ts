import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Req,
  Query,
} from '@nestjs/common';
import { Request } from 'express';
import { RecoveryService } from './recovery.service.js';
import { SubmitHealthDataDto } from './dto/submit-health-data.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { User } from '../entities/user.entity.js';

interface AuthenticatedRequest extends Request {
  user: User;
}

@Controller('recovery')
@UseGuards(JwtAuthGuard)
export class RecoveryController {
  constructor(private readonly recoveryService: RecoveryService) {}

  @Post('health-data')
  async submitHealthData(
    @Req() req: AuthenticatedRequest,
    @Body() dto: SubmitHealthDataDto,
  ) {
    return this.recoveryService.submitHealthData(req.user.id, dto);
  }

  @Get('score')
  async getScore(@Req() req: AuthenticatedRequest) {
    return this.recoveryService.getLatestScore(req.user.id);
  }

  @Get('history')
  async getHistory(
    @Req() req: AuthenticatedRequest,
    @Query('days') days?: string,
  ) {
    return this.recoveryService.getScoreHistory(req.user.id, days ? parseInt(days, 10) : 7);
  }
}
