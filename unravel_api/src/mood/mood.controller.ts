import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  UseGuards,
  Req,
  Query,
} from '@nestjs/common';
import { Request } from 'express';
import { MoodService } from './mood.service.js';
import { CreateMoodLogDto } from './dto/create-mood-log.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { User } from '../entities/user.entity.js';

interface AuthenticatedRequest extends Request {
  user: User;
}

@Controller('mood')
@UseGuards(JwtAuthGuard)
export class MoodController {
  constructor(private readonly moodService: MoodService) {}

  @Post()
  async create(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateMoodLogDto,
  ) {
    return this.moodService.create(req.user.id, dto);
  }

  @Get()
  async findAll(
    @Req() req: AuthenticatedRequest,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const options = {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
    };
    return this.moodService.findByUser(req.user.id, options);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.moodService.findOne(id);
  }
}
