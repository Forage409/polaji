ALTER TABLE users ADD COLUMN vip_until DATETIME;
ALTER TABLE users ADD COLUMN vip_plan TEXT;

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
