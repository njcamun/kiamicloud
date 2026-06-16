-- Fase 14: feedback de testadores beta

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS beta_feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firebase_uid TEXT REFERENCES users(firebase_uid) ON DELETE SET NULL,
  email TEXT,
  message TEXT NOT NULL,
  app_version TEXT,
  platform TEXT,
  api_base_url TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_beta_feedback_created
  ON beta_feedback(created_at DESC);
