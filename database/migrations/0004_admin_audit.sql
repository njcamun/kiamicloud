-- Fase 13: auditoria de accoes administrativas

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS admin_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  admin_uid TEXT NOT NULL,
  target_uid TEXT,
  action TEXT NOT NULL CHECK (
    action IN ('plan_change', 'storage_adjust', 'user_view', 'note_update')
  ),
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_admin_actions_created
  ON admin_actions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_actions_target
  ON admin_actions(target_uid, created_at DESC);
