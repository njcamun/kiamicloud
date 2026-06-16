-- Remove CHECK restritivo em admin_actions.action (accções novas falhavam com 500).
PRAGMA foreign_keys = OFF;

CREATE TABLE admin_actions_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  admin_uid TEXT NOT NULL,
  target_uid TEXT,
  action TEXT NOT NULL,
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT INTO admin_actions_new
  (id, admin_uid, target_uid, action, metadata_json, created_at)
SELECT id, admin_uid, target_uid, action, metadata_json, created_at
FROM admin_actions;

DROP TABLE admin_actions;

ALTER TABLE admin_actions_new RENAME TO admin_actions;

CREATE INDEX IF NOT EXISTS idx_admin_actions_created
  ON admin_actions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_actions_target
  ON admin_actions(target_uid, created_at DESC);

PRAGMA foreign_keys = ON;
