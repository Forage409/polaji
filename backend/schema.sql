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
