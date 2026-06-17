-- Fase 20: ciclo de vida de subscrições (tolerância, restrição, suspensão, eliminação).
PRAGMA foreign_keys = OFF;

CREATE TABLE subscriptions_v2 (
  id TEXT PRIMARY KEY NOT NULL,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid) ON DELETE CASCADE,
  plan_code TEXT NOT NULL REFERENCES plans(code),
  status TEXT NOT NULL DEFAULT 'active',
  started_at TEXT NOT NULL DEFAULT (datetime('now')),
  ends_at TEXT,
  grace_period_ends_at TEXT,
  auto_renew INTEGER NOT NULL DEFAULT 0,
  last_notified_at TEXT,
  deletion_scheduled_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT INTO subscriptions_v2 (
  id, firebase_uid, plan_code, status, started_at, ends_at,
  grace_period_ends_at, auto_renew, last_notified_at, deletion_scheduled_at,
  created_at, updated_at
)
SELECT
  id, firebase_uid, plan_code, status, started_at, ends_at,
  NULL, 0, NULL, NULL, created_at, updated_at
FROM subscriptions;

DROP TABLE subscriptions;
ALTER TABLE subscriptions_v2 RENAME TO subscriptions;

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_ends ON subscriptions(ends_at);

PRAGMA foreign_keys = ON;
