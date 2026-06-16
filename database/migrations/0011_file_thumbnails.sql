-- Miniaturas de imagens (objecto R2 separado; nao conta na quota do utilizador)
ALTER TABLE files ADD COLUMN thumb_r2_object_key TEXT;
