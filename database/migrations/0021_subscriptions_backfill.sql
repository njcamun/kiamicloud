-- Backfill: utilizadores sem linha em subscriptions recebem plano gratuito activo.
INSERT INTO subscriptions (
  id,
  firebase_uid,
  plan_code,
  status,
  started_at,
  ends_at,
  grace_period_ends_at,
  auto_renew,
  last_notified_at,
  deletion_scheduled_at,
  created_at,
  updated_at
)
SELECT
  lower(hex(randomblob(16))),
  u.firebase_uid,
  u.plan_code,
  'active',
  datetime('now'),
  NULL,
  NULL,
  0,
  NULL,
  NULL,
  datetime('now'),
  datetime('now')
FROM users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscriptions s WHERE s.firebase_uid = u.firebase_uid
);
