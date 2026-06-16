-- Capacidade de armazenamento personalizada por utilizador (admin, sobretudo KiamiLocal).
ALTER TABLE users ADD COLUMN quota_bytes_override INTEGER;
