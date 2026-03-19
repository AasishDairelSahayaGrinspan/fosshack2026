import fs from 'node:fs';
import path from 'node:path';
import Database from 'better-sqlite3';

const DB_PATH = process.env.WELLNESS_DB_PATH || path.resolve('db', 'wellness.db');
const SCHEMA_PATH = path.resolve('db', 'schema.sql');

export function createRepository() {
  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
  const db = new Database(DB_PATH);
  db.pragma('journal_mode = WAL');
  db.exec(fs.readFileSync(SCHEMA_PATH, 'utf8'));

  const insertStmt = db.prepare(`
    INSERT INTO wellness_logs (
      id, user_id, log_date, mood, sleep_hours, stress, energy, anxiety,
      exercise, journaling, journal_sentiment, wellness_score, created_at
    ) VALUES (
      @id, @user_id, @log_date, @mood, @sleep_hours, @stress, @energy, @anxiety,
      @exercise, @journaling, @journal_sentiment, @wellness_score, @created_at
    )
    ON CONFLICT(id) DO UPDATE SET
      mood=excluded.mood,
      sleep_hours=excluded.sleep_hours,
      stress=excluded.stress,
      energy=excluded.energy,
      anxiety=excluded.anxiety,
      exercise=excluded.exercise,
      journaling=excluded.journaling,
      journal_sentiment=excluded.journal_sentiment,
      wellness_score=excluded.wellness_score
  `);

  const byUserStmt = db.prepare(`
    SELECT * FROM wellness_logs
    WHERE user_id = ?
    ORDER BY log_date DESC
    LIMIT ?
  `);

  return {
    upsertLog(payload) {
      insertStmt.run(payload);
    },
    getRecentLogs(userId, limit = 30) {
      return byUserStmt.all(userId, limit);
    }
  };
}
