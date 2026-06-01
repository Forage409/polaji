CREATE TABLE IF NOT EXISTS templates (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    cover_image TEXT,
    category TEXT,
    author_id TEXT,
    author_name TEXT,
    status TEXT DEFAULT 'draft',
    form_config_raw TEXT,
    result_config_raw TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS template_stats (
    template_id TEXT PRIMARY KEY,
    view_count INTEGER DEFAULT 0,
    start_count INTEGER DEFAULT 0,
    generate_count INTEGER DEFAULT 0,
    usage_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    report_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS works (
    id TEXT PRIMARY KEY,
    template_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    is_anonymous INTEGER DEFAULT 0,
    author_id TEXT,
    author_name TEXT,
    author_avatar TEXT,
    tags TEXT,
    category TEXT,
    image_url TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    install_token_hash TEXT NOT NULL,
    vip_until DATETIME,
    vip_plan TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS work_likes (
    work_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (work_id, user_id)
);

CREATE TABLE IF NOT EXISTS ai_usage (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    feature TEXT NOT NULL,
    tone TEXT NOT NULL,
    status TEXT NOT NULL,
    model TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_created_at ON ai_usage(user_id, created_at);

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
