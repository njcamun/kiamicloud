-- Fase 11: seguranca (rate limit + auditoria)
-- Fase 12: pagamentos (checkout mock + historico)

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS rate_limit_buckets (
  bucket_key TEXT PRIMARY KEY NOT NULL,
  count INTEGER NOT NULL DEFAULT 0 CHECK (count >= 0),
  window_start_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS security_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_type TEXT NOT NULL CHECK (
    event_type IN (
      'auth_failed',
      'rate_limited',
      'webhook_invalid',
      'plan_changed',
      'checkout_created',
      'checkout_paid'
    )
  ),
  firebase_uid TEXT,
  ip_hash TEXT,
  path TEXT,
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_security_events_created
  ON security_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_security_events_uid
  ON security_events(firebase_uid, created_at DESC);

-- Checkout de pagamento (mock MVP; gateway real na producao)
CREATE TABLE IF NOT EXISTS payment_checkouts (
  id TEXT PRIMARY KEY NOT NULL,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid) ON DELETE CASCADE,
  plan_code TEXT NOT NULL REFERENCES plans(code),
  amount_kz INTEGER NOT NULL CHECK (amount_kz >= 0),
  reference TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'paid', 'failed', 'expired', 'cancelled')
  ),
  provider TEXT NOT NULL DEFAULT 'mock',
  expires_at TEXT NOT NULL,
  paid_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_payment_checkouts_user
  ON payment_checkouts(firebase_uid, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_payment_checkouts_ref
  ON payment_checkouts(reference);
