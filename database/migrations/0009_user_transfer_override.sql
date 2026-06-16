-- Override opcional da taxa de transferência por utilizador (admin).
ALTER TABLE users ADD COLUMN max_file_size_bytes_override INTEGER;
