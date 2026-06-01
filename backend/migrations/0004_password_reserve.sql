ALTER TABLE accounts ADD COLUMN username_hash TEXT;
ALTER TABLE accounts ADD COLUMN username_display TEXT NOT NULL DEFAULT '';
ALTER TABLE accounts ADD COLUMN registration_channel TEXT NOT NULL DEFAULT 'sms';

UPDATE accounts
SET username_hash = phone_hash,
    username_display = phone_mask
WHERE username_hash IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_accounts_username_hash ON accounts(username_hash);

CREATE TABLE IF NOT EXISTS password_login_attempts (
    id TEXT PRIMARY KEY,
    username_hash TEXT NOT NULL,
    ip_hash TEXT NOT NULL,
    success INTEGER NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_password_login_username_created ON password_login_attempts(username_hash, created_at);
CREATE INDEX IF NOT EXISTS idx_password_login_ip_created ON password_login_attempts(ip_hash, created_at);
