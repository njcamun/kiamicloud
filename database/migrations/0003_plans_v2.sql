-- Planos v2: coluna max_file_size_bytes + limites + migração legado
-- Remoto com 0002 antigo (free/start/…) exige INSERT dos novos códigos antes dos FK em users.

ALTER TABLE plans ADD COLUMN max_file_size_bytes INTEGER NOT NULL DEFAULT 15728640;

-- Garantir que todos os códigos de destino existem (bases com seed legado free→ultra)
INSERT OR IGNORE INTO plans (code, name, quota_bytes, price_kz_month, max_file_size_bytes, is_active) VALUES
  ('basico', 'Básico', 21474836480, 0, 15728640, 1),
  ('basico_plus', 'Básico+', 21474836480, 1500, 78643200, 1),
  ('plus', 'Plus', 42949672960, 2550, 157286400, 1),
  ('start', 'Start', 85899345920, 5100, 157286400, 1),
  ('premium', 'Premium', 171798691840, 10200, 157286400, 1),
  ('pro', 'Pro', 343597383680, 20400, 157286400, 1),
  ('ultra', 'Ultra', 536870912000, 40800, 157286400, 1);

UPDATE plans SET
  name = 'Básico',
  quota_bytes = 21474836480,
  price_kz_month = 0,
  max_file_size_bytes = 15728640,
  is_active = 1
WHERE code = 'basico';

UPDATE plans SET
  name = 'Básico+',
  quota_bytes = 21474836480,
  price_kz_month = 1500,
  max_file_size_bytes = 78643200,
  is_active = 1
WHERE code = 'basico_plus';

UPDATE plans SET
  name = 'Plus',
  quota_bytes = 42949672960,
  price_kz_month = 2550,
  max_file_size_bytes = 157286400,
  is_active = 1
WHERE code = 'plus';

UPDATE plans SET
  name = 'Start',
  quota_bytes = 85899345920,
  price_kz_month = 5100,
  max_file_size_bytes = 157286400,
  is_active = 1
WHERE code = 'start';

UPDATE plans SET
  name = 'Premium',
  quota_bytes = 171798691840,
  price_kz_month = 10200,
  max_file_size_bytes = 157286400,
  is_active = 1
WHERE code = 'premium';

UPDATE plans SET
  name = 'Pro',
  quota_bytes = 343597383680,
  price_kz_month = 20400,
  max_file_size_bytes = 157286400,
  is_active = 1
WHERE code = 'pro';

UPDATE plans SET
  name = 'Ultra',
  quota_bytes = 536870912000,
  price_kz_month = 40800,
  max_file_size_bytes = 157286400,
  is_active = 1
WHERE code = 'ultra';

-- Utilizadores: ordem importa (start→basico_plus antes de premium→start)
UPDATE users SET plan_code = 'basico' WHERE plan_code = 'free';
UPDATE users SET plan_code = 'basico_plus' WHERE plan_code = 'start';
UPDATE users SET plan_code = 'start' WHERE plan_code = 'premium';
UPDATE users SET plan_code = 'premium' WHERE plan_code = 'pro';
UPDATE users SET plan_code = 'pro' WHERE plan_code = 'ultra';

UPDATE subscriptions SET plan_code = 'basico' WHERE plan_code = 'free';
UPDATE subscriptions SET plan_code = 'basico_plus' WHERE plan_code = 'start';
UPDATE subscriptions SET plan_code = 'start' WHERE plan_code = 'premium';
UPDATE subscriptions SET plan_code = 'premium' WHERE plan_code = 'pro';
UPDATE subscriptions SET plan_code = 'pro' WHERE plan_code = 'ultra';

UPDATE plans SET is_active = 0 WHERE code = 'free';
