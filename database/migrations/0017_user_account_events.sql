-- Historico unificado: suporte, billing e notificacoes ao utilizador.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS user_account_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firebase_uid TEXT NOT NULL,
  kind TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  metadata_json TEXT,
  read_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (firebase_uid) REFERENCES users(firebase_uid) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_account_events_uid_created
  ON user_account_events(firebase_uid, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_account_events_uid_unread
  ON user_account_events(firebase_uid, read_at, created_at DESC);
