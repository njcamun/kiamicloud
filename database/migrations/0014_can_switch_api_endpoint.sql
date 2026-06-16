-- Permite ao utilizador alternar servidor (Cloudflare / ZimaBlade LAN) nas Definições.
ALTER TABLE users ADD COLUMN can_switch_api_endpoint INTEGER NOT NULL DEFAULT 0 CHECK (
  can_switch_api_endpoint IN (0, 1)
);
