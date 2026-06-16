-- Comprovativo de pagamento manual + estados awaiting_review / rejected
PRAGMA foreign_keys=OFF;

CREATE TABLE payment_checkouts_new (
  id TEXT PRIMARY KEY NOT NULL,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid) ON DELETE CASCADE,
  plan_code TEXT NOT NULL REFERENCES plans(code),
  amount_kz INTEGER NOT NULL CHECK (amount_kz >= 0),
  reference TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN (
      'pending',
      'awaiting_review',
      'paid',
      'failed',
      'expired',
      'cancelled',
      'rejected'
    )
  ),
  provider TEXT NOT NULL DEFAULT 'manual',
  expires_at TEXT NOT NULL,
  paid_at TEXT,
  proof_r2_key TEXT,
  proof_mime_type TEXT,
  proof_submitted_at TEXT,
  rejection_reason TEXT,
  rejected_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT INTO payment_checkouts_new (
  id,
  firebase_uid,
  plan_code,
  amount_kz,
  reference,
  status,
  provider,
  expires_at,
  paid_at,
  created_at,
  updated_at
)
SELECT
  id,
  firebase_uid,
  plan_code,
  amount_kz,
  reference,
  status,
  'manual',
  expires_at,
  paid_at,
  created_at,
  updated_at
FROM payment_checkouts;

DROP TABLE payment_checkouts;
ALTER TABLE payment_checkouts_new RENAME TO payment_checkouts;

CREATE INDEX IF NOT EXISTS idx_payment_checkouts_user
  ON payment_checkouts(firebase_uid, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_checkouts_ref
  ON payment_checkouts(reference);
CREATE INDEX IF NOT EXISTS idx_payment_checkouts_status
  ON payment_checkouts(status, created_at DESC);

PRAGMA foreign_keys=ON;
