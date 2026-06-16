-- Migra códigos de plano em checkouts (tabela criada em 0003_security_payments.sql).

UPDATE payment_checkouts SET plan_code = 'basico' WHERE plan_code = 'free';
UPDATE payment_checkouts SET plan_code = 'basico_plus' WHERE plan_code = 'start';
UPDATE payment_checkouts SET plan_code = 'start' WHERE plan_code = 'premium';
UPDATE payment_checkouts SET plan_code = 'premium' WHERE plan_code = 'pro';
UPDATE payment_checkouts SET plan_code = 'pro' WHERE plan_code = 'ultra';
