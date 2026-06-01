CREATE TABLE IF NOT EXISTS accounts (
    id TEXT PRIMARY KEY,
    phone_hash TEXT NOT NULL UNIQUE,
    phone_mask TEXT NOT NULL,
    nickname TEXT NOT NULL,
    bio TEXT NOT NULL DEFAULT '',
    avatar_url TEXT NOT NULL DEFAULT 'logo',
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    vip_until DATETIME,
    vip_plan TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    accepted_terms_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS account_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    revoked_at DATETIME
);

CREATE TABLE IF NOT EXISTS sms_requests (
    id TEXT PRIMARY KEY,
    phone_hash TEXT NOT NULL,
    purpose TEXT NOT NULL,
    ip_hash TEXT NOT NULL,
    client_hash TEXT NOT NULL,
    status TEXT NOT NULL,
    provider_request_id TEXT,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS account_migrations (
    legacy_user_id TEXT PRIMARY KEY,
    account_user_id TEXT NOT NULL,
    migrated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_account_sessions_token ON account_sessions(token_hash, expires_at);
CREATE INDEX IF NOT EXISTS idx_sms_requests_phone_created ON sms_requests(phone_hash, created_at);
CREATE INDEX IF NOT EXISTS idx_sms_requests_ip_created ON sms_requests(ip_hash, created_at);
