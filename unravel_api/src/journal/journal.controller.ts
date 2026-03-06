import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { JournalService } from './journal.service.js';
import { CreateJournalDto } from './dto/create-journal.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { User } from '../entities/user.entity.js';

interface AuthenticatedRequest extends Request {
  user: User;
}

@Controller('journal')
@UseGuards(JwtAuthGuard)
export class JournalController {
  constructor(private readonly journalService: JournalService) {}

  @Post()
  async create(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateJournalDto,
  ) {
    return this.journalService.create(req.user.id, dto);
  }

  @Get()
  async findAll(@Req() req: AuthenticatedRequest) {
    return this.journalService.findByUser(req.user.id);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.journalService.findOne(id);
  }
}
