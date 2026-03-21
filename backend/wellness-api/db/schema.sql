CREATE TABLE IF NOT EXISTS wellness_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  log_date TEXT NOT NULL,
  mood INTEGER NOT NULL CHECK (mood BETWEEN 1 AND 5),
  sleep_hours REAL NOT NULL CHECK (sleep_hours BETWEEN 0 AND 24),
  stress INTEGER NOT NULL CHECK (stress BETWEEN 1 AND 5),
  energy INTEGER NOT NULL CHECK (energy BETWEEN 1 AND 5),
  anxiety INTEGER NOT NULL CHECK (anxiety BETWEEN 1 AND 5),
  exercise INTEGER,
  journaling TEXT,
  journal_sentiment REAL,
  wellness_score REAL NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_wellness_user_date
  ON wellness_logs(user_id, log_date DESC);
