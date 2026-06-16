-- KiamiCloud D1 — esquema inicial (Fase 5)
-- Metadados apenas; binarios ficam no R2 (Fase 6+).

PRAGMA foreign_keys = ON;

-- Planos de subscricao (referencia PLANOS.md)
CREATE TABLE IF NOT EXISTS plans (
  code TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  quota_bytes INTEGER NOT NULL CHECK (quota_bytes > 0),
  price_kz_month INTEGER NOT NULL DEFAULT 0 CHECK (price_kz_month >= 0),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Perfil por utilizador Firebase (1:1 com firebase_uid)
CREATE TABLE IF NOT EXISTS users (
  firebase_uid TEXT PRIMARY KEY NOT NULL,
  email TEXT,
  display_name TEXT,
  photo_url TEXT,
  plan_code TEXT NOT NULL DEFAULT 'basico' REFERENCES plans(code),
  storage_used_bytes INTEGER NOT NULL DEFAULT 0 CHECK (storage_used_bytes >= 0),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_plan ON users(plan_code);

-- Pastas (arvore por utilizador; parent_id NULL = raiz)
CREATE TABLE IF NOT EXISTS folders (
  id TEXT PRIMARY KEY NOT NULL,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid) ON DELETE CASCADE,
  parent_id TEXT REFERENCES folders(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  deleted_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_folders_user ON folders(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_folders_parent ON folders(parent_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_folders_unique_name
  ON folders(firebase_uid, parent_id, name)
  WHERE deleted_at IS NULL;

-- Metadados de ficheiros (conteudo no R2)
CREATE TABLE IF NOT EXISTS files (
  id TEXT PRIMARY KEY NOT NULL,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid) ON DELETE CASCADE,
  folder_id TEXT REFERENCES folders(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  mime_type TEXT,
  size_bytes INTEGER NOT NULL DEFAULT 0 CHECK (size_bytes >= 0),
  r2_object_key TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'failed', 'deleted')),
  checksum_sha256 TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  deleted_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_files_user ON files(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_files_folder ON files(folder_id);
CREATE INDEX IF NOT EXISTS idx_files_status ON files(firebase_uid, status);

-- Subscricoes pagas (Fase 12; schema preparado)
CREATE TABLE IF NOT EXISTS subscriptions (
  id TEXT PRIMARY KEY NOT NULL,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid) ON DELETE CASCADE,
  plan_code TEXT NOT NULL REFERENCES plans(code),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'past_due')),
  started_at TEXT NOT NULL DEFAULT (datetime('now')),
  ends_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(firebase_uid);

-- Historico de accoes (auditoria leve)
CREATE TABLE IF NOT EXISTS file_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid) ON DELETE CASCADE,
  file_id TEXT REFERENCES files(id) ON DELETE SET NULL,
  action TEXT NOT NULL CHECK (action IN ('upload', 'download', 'rename', 'delete', 'restore')),
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_file_actions_user ON file_actions(firebase_uid, created_at DESC);
