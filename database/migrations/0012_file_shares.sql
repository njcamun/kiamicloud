-- Partilha por link (Fase 21) — download só leitura via token público
CREATE TABLE IF NOT EXISTS file_shares (
  id TEXT PRIMARY KEY NOT NULL,
  token TEXT NOT NULL UNIQUE,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid) ON DELETE CASCADE,
  file_id TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  expires_at TEXT NOT NULL,
  revoked_at TEXT,
  access_count INTEGER NOT NULL DEFAULT 0 CHECK (access_count >= 0),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_file_shares_token ON file_shares(token);
CREATE INDEX IF NOT EXISTS idx_file_shares_user ON file_shares(firebase_uid, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_file_shares_file ON file_shares(file_id);
