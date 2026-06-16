-- Chat de suporte (utilizador <-> admin).

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS support_chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firebase_uid TEXT NOT NULL,
  sender_role TEXT NOT NULL CHECK (sender_role IN ('user', 'admin')),
  sender_uid TEXT,
  message TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (firebase_uid) REFERENCES users(firebase_uid) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_support_chat_uid_created
  ON support_chat_messages(firebase_uid, created_at ASC);

CREATE TABLE IF NOT EXISTS support_chat_read_state (
  firebase_uid TEXT PRIMARY KEY,
  user_last_read_id INTEGER NOT NULL DEFAULT 0,
  admin_last_read_id INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (firebase_uid) REFERENCES users(firebase_uid) ON DELETE CASCADE
);
