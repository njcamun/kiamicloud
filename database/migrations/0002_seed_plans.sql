-- Planos oficiais KiamiCloud v2 (docs/PLANOS.md)
-- Preço cobrado: Plus+ = tabela −15% (3000→2550, 6000→5100, …)
INSERT OR IGNORE INTO plans (code, name, quota_bytes, price_kz_month) VALUES
  ('basico', 'Básico', 21474836480, 0),
  ('basico_plus', 'Básico+', 21474836480, 1500),
  ('plus', 'Plus', 42949672960, 2550),
  ('start', 'Start', 85899345920, 5100),
  ('premium', 'Premium', 171798691840, 10200),
  ('pro', 'Pro', 343597383680, 20400),
  ('ultra', 'Ultra', 536870912000, 40800);
