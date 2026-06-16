-- Admin pode marcar feedback como tratado (notificação pendente enquanto reviewed_at IS NULL).
ALTER TABLE beta_feedback ADD COLUMN reviewed_at TEXT;

CREATE INDEX IF NOT EXISTS idx_beta_feedback_uid_pending
  ON beta_feedback(firebase_uid, reviewed_at);
