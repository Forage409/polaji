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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
