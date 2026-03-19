import crypto from 'node:crypto';
import express from 'express';
import pino from 'pino';
import { z } from 'zod';

import { createRepository } from './repository/appwriteRepo.js';
import { generateInsights } from './services/insightService.js';
import { calculateTrend } from './services/trendService.js';
import { calculateDailyWellnessScore, sleepHoursToScore } from './utils/scoring.js';
import { scoreJournalSentiment } from './utils/sentiment.js';

const logger = pino({ name: 'wellness-api' });
const app = express();
const repo = createRepository();

app.use(express.json({ limit: '200kb' }));

const logSchema = z.object({
  userId: z.string().min(1),
  date: z.string().datetime().optional(),
  mood: z.number().int().min(1).max(5),
  sleep: z.number().min(0).max(24),
  stress: z.number().int().min(1).max(5),
  energy: z.number().int().min(1).max(5),
  anxiety: z.number().int().min(1).max(5),
  exercise: z.boolean().optional(),
  journaling: z.string().max(3000).optional()
});

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'unravel-wellness-api' });
});

// POST /log -> store log + calculated score
app.post('/log', async (req, res) => {
  const parsed = logSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'INVALID_PAYLOAD',
      details: parsed.error.flatten()
    });
  }

  const input = parsed.data;
  const wellnessScore = calculateDailyWellnessScore({
    mood: input.mood,
    sleepHours: input.sleep,
    stress: input.stress,
    energy: input.energy,
    anxiety: input.anxiety
  });

  const sentiment = scoreJournalSentiment(input.journaling || '');
  const now = new Date();

  const row = {
    id: crypto.randomUUID(),
    user_id: input.userId,
    log_date: new Date(input.date || now).toISOString(),
    mood: input.mood,
    sleep_hours: input.sleep,
    stress: input.stress,
    energy: input.energy,
    anxiety: input.anxiety,
    exercise: input.exercise == null ? null : input.exercise ? 1 : 0,
    journaling: input.journaling || null,
    journal_sentiment: sentiment,
    wellness_score: wellnessScore,
    created_at: now.toISOString()
  };

  await repo.upsertLog(row);

  return res.status(201).json({
    message: 'Log saved successfully.',
    data: {
      id: row.id,
      wellnessScore,
      sleepScore: sleepHoursToScore(input.sleep)
    }
  });
});

// GET /trend?userId=... -> 7 day moving average + previous comparison
app.get('/trend', async (req, res) => {
  const userId = String(req.query.userId || '');
  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const logs = await repo.getRecentLogs(userId, 30);
  const trend = calculateTrend(logs);

  return res.json({
    userId,
    trend,
    points: logs.slice(0, 14).map((l) => ({
      date: l.log_date,
      score: l.wellness_score
    }))
  });
});

// GET /insights?userId=... -> pattern-based supportive messages
app.get('/insights', async (req, res) => {
  const userId = String(req.query.userId || '');
  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const logs = await repo.getRecentLogs(userId, 30);
  const insights = generateInsights(logs);

  return res.json({
    userId,
    safeNotice:
      'Insights are supportive wellness hints and not medical advice or diagnosis.',
    insights
  });
});

app.use((err, _req, res, _next) => {
  logger.error(err);
  res.status(500).json({ error: 'INTERNAL_SERVER_ERROR' });
});

const port = Number(process.env.PORT || 8787);
app.listen(port, () => {
  logger.info(`wellness-api listening on http://localhost:${port}`);
});
