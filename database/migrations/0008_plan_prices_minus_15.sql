-- Preços cobrados: Plus em diante = tabela −15%

UPDATE plans SET price_kz_month = 2550 WHERE code = 'plus';
UPDATE plans SET price_kz_month = 5100 WHERE code = 'start';
UPDATE plans SET price_kz_month = 10200 WHERE code = 'premium';
UPDATE plans SET price_kz_month = 20400 WHERE code = 'pro';
UPDATE plans SET price_kz_month = 40800 WHERE code = 'ultra';
