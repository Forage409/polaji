export interface Env {
    BUCKET: R2Bucket;
    DB: D1Database;
    AI: any;
    AI_MODEL?: string;
    ALLOW_DEBUG_VIP?: string;
    AUTH_HASH_PEPPER?: string;
    ALIYUN_ACCESS_KEY_ID?: string;
    ALIYUN_ACCESS_KEY_SECRET?: string;
    ALIYUN_SMS_SCHEME_NAME?: string;
    ALIYUN_SMS_SIGN_NAME?: string;
    ALIYUN_SMS_TEMPLATE_CODE?: string;
    ALIYUN_SMS_TEMPLATE_PARAM?: string;
}

// Safe binding helpers: D1 throws D1_TYPE_ERROR if any bind value is undefined.
// Use s() for strings, n() for numbers. Both convert undefined/null to safe defaults.
function s(value: any, fallback: string = ''): string {
    if (value === undefined || value === null) return fallback;
    return String(value);
}

function n(value: any, fallback: number = 0): number {
    if (value === undefined || value === null) return fallback;
    const num = Number(value);
    return isNaN(num) ? fallback : num;
}

function cleanText(value: any): string {
    return s(value).trim();
}

function isTextWithin(value: any, maxLength: number, allowEmpty: boolean = false): boolean {
    const text = cleanText(value);
    return (allowEmpty || text.length > 0) && text.length <= maxLength;
}

function isAllowedTemplateStatus(value: any): boolean {
    return ['draft', 'published', 'hidden'].includes(s(value));
}

function isAllowedAvatar(value: any): boolean {
    const avatar = cleanText(value);
    return avatar === 'logo' || avatar.startsWith('theme_') || /^https:\/\/zhenghuo\.miaogou\.site\/api\/images\//.test(avatar);
}

function serializeConfig(rawValue: any, fallbackValue: any): string {
    return s(typeof rawValue === 'string' ? rawValue : JSON.stringify(fallbackValue ?? {}));
}

function isValidTemplateFormConfig(raw: string): boolean {
    if (!raw || raw.length > 20000) return false;
    try {
        const parsed = JSON.parse(raw);
        const fields = parsed?.fields;
        if (!Array.isArray(fields) || fields.length < 1 || fields.length > 8) return false;

        const labels = new Set<string>();
        for (const field of fields) {
            const label = cleanText(field?.label);
            const type = s(field?.type);
            if (!label || label.length > 12 || labels.has(label)) return false;
            labels.add(label);
            if (!['text', 'number', 'singleSelect', 'multiSelect', 'participants'].includes(type)) return false;
            if (s(field?.placeholder).length > 30) return false;

            if (type === 'singleSelect' || type === 'multiSelect') {
                if (!Array.isArray(field?.options) || field.options.length < 2 || field.options.length > 8) return false;
                const options = field.options.map((option: any) => cleanText(option));
                if (options.some((option: string) => !option || option.length > 16)) return false;
                if (new Set(options).size !== options.length) return false;
            }

            if (type === 'participants') {
                const minCount = n(field?.minCount, 3);
                const maxCount = n(field?.maxCount, 8);
                if (minCount < 2 || maxCount > 12 || minCount > maxCount) return false;
            }
        }
        return true;
    } catch {
        return false;
    }
}

function isValidResultConfig(raw: string): boolean {
    if (!raw || raw.length > 20000) return false;
    try {
        const parsed = JSON.parse(raw);
        return parsed && typeof parsed === 'object' && !Array.isArray(parsed);
    } catch {
        return false;
    }
}

const FREE_AI_LIMIT = 3;
const VIP_AI_LIMIT = 50;
const DEFAULT_AI_MODEL = "@cf/meta/llama-3.1-8b-instruct-fast";
const ALLOWED_AI_TONES = new Set(["default", "sharp", "cute", "absurd", "formal", "moments"]);
const OPTIMIZED_COPY_KEYS = ["title", "subtitle", "evidence", "resultLevel", "quote", "finalComment"];
const TEMPLATE_COPY_KEYS = ["stats", "evidencePool", "finalPool", "levels"];

const OPTIMIZED_COPY_SCHEMA = {
    type: "object",
    additionalProperties: false,
    properties: {
        title: { type: "string", minLength: 1, maxLength: 18 },
        subtitle: { type: "string", maxLength: 30 },
        evidence: {
            type: "array",
            minItems: 1,
            maxItems: 3,
            items: { type: "string", minLength: 1, maxLength: 28 },
        },
        resultLevel: { type: "string", minLength: 1, maxLength: 16 },
        quote: { type: "string", minLength: 1, maxLength: 36 },
        finalComment: { type: "string", minLength: 1, maxLength: 50 },
    },
    required: OPTIMIZED_COPY_KEYS,
};

const TEMPLATE_COPY_SCHEMA = {
    type: "object",
    additionalProperties: false,
    properties: {
        stats: {
            type: "array",
            minItems: 2,
            maxItems: 4,
            items: { type: "string", minLength: 1, maxLength: 12 },
        },
        evidencePool: {
            type: "array",
            minItems: 3,
            maxItems: 8,
            items: { type: "string", minLength: 1, maxLength: 28 },
        },
        finalPool: {
            type: "array",
            minItems: 2,
            maxItems: 6,
            items: { type: "string", minLength: 1, maxLength: 50 },
        },
        levels: {
            type: "array",
            minItems: 2,
            maxItems: 6,
            items: { type: "string", minLength: 1, maxLength: 16 },
        },
    },
    required: TEMPLATE_COPY_KEYS,
};

type AIQuotaStatus = {
    isVip: boolean;
    limit: number;
    used: number;
    remaining: number;
    window: "rolling_24h";
};

function safeText(value: any, maxLength: number): string {
    return cleanText(value).slice(0, maxLength);
}

function safePromptText(value: any, maxLength: number): string {
    const text = safeText(value, maxLength);
    return containsUnsafeText(text) ? "" : text;
}

function safeTextArray(value: any, maxItems: number, maxLength: number): string[] {
    if (!Array.isArray(value)) return [];
    return value
        .map((item: any) => safeText(item, maxLength))
        .filter((item: string) => item.length > 0)
        .slice(0, maxItems);
}

function containsUnsafeText(value: string): boolean {
    return /(身份证|银行卡|手机号|电话号码|住址|密码|威胁|杀死|去死|种族歧视|性别歧视|傻逼|废物|垃圾|滚蛋|微信|QQ|邮箱|联系我|加我|https?:\/\/|www\.|[\w.+-]+@[\w.-]+\.[a-z]{2,}|(?<!\d)1[3-9]\d{9}(?!\d)|(?<!\d)\d{17}[\dXx](?!\d))/i.test(value);
}

function isSafeTextArray(values: string[]): boolean {
    return values.every((value) => !containsUnsafeText(value));
}

function hasExactKeys(value: Record<string, any>, expectedKeys: string[]): boolean {
    const actualKeys = Object.keys(value).sort();
    return actualKeys.length === expectedKeys.length &&
        actualKeys.every((key, index) => key === [...expectedKeys].sort()[index]);
}

function outputText(value: any, maxLength: number, allowEmpty: boolean = false): string | null {
    if (typeof value !== "string") return null;
    const text = value.trim();
    if ((!allowEmpty && !text) || text.length > maxLength || containsUnsafeText(text)) return null;
    return text;
}

function outputTextArray(value: any, minItems: number, maxItems: number, maxLength: number): string[] | null {
    if (!Array.isArray(value) || value.length < minItems || value.length > maxItems) return null;
    const texts = value.map((item) => outputText(item, maxLength));
    return texts.every((item): item is string => item !== null) ? texts : null;
}

function aiError(code: string, status: number, headers: Record<string, string>, message: string): Response {
    return Response.json({ error: message, code }, { status, headers });
}

async function ensureAIUsageTable(env: Env): Promise<void> {
    await env.DB.prepare(`
        CREATE TABLE IF NOT EXISTS ai_usage (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            feature TEXT NOT NULL,
            tone TEXT NOT NULL,
            status TEXT NOT NULL,
            model TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `).run();
    await env.DB.prepare("CREATE INDEX IF NOT EXISTS idx_ai_usage_user_created_at ON ai_usage(user_id, created_at)").run();
}

async function getAIQuotaStatus(request: Request, env: Env, userId: string): Promise<AIQuotaStatus> {
    await ensureAIUsageTable(env);
    let user: any = null;
    try {
        user = await env.DB.prepare("SELECT vip_until FROM accounts WHERE id = ?").bind(userId).first();
        if (!user) user = await env.DB.prepare("SELECT vip_until FROM users WHERE id = ?").bind(userId).first();
    } catch {
        // Compatibility during rolling deployment before the vip_until migration lands.
        user = null;
    }
    const debugVip = env.ALLOW_DEBUG_VIP === "true" && request.headers.get("X-Debug-Vip") === "true";
    const vipUntil = Date.parse(s(user?.vip_until));
    const isVip = debugVip || (!Number.isNaN(vipUntil) && vipUntil > Date.now());
    const limit = isVip ? VIP_AI_LIMIT : FREE_AI_LIMIT;
    const used = n(await env.DB.prepare(`
        SELECT COUNT(*) AS c FROM ai_usage
        WHERE user_id = ?
          AND status IN ('pending', 'succeeded')
          AND created_at >= datetime('now', '-24 hours')
    `).bind(userId).first("c"));
    return { isVip, limit, used, remaining: Math.max(0, limit - used), window: "rolling_24h" };
}

async function reserveAIUsage(env: Env, requestId: string, userId: string, feature: string, tone: string, model: string): Promise<boolean> {
    const existing = await env.DB.prepare("SELECT id FROM ai_usage WHERE id = ?").bind(requestId).first();
    if (existing) return false;
    await env.DB.prepare(`
        INSERT INTO ai_usage (id, user_id, feature, tone, status, model)
        VALUES (?, ?, ?, ?, 'pending', ?)
    `).bind(requestId, userId, feature, tone, model).run();
    return true;
}

async function finishAIUsage(env: Env, requestId: string, status: "succeeded" | "failed"): Promise<void> {
    await env.DB.prepare("UPDATE ai_usage SET status = ? WHERE id = ?").bind(status, requestId).run();
}

function parseAIJSON(raw: any): any {
    if (raw && typeof raw.response === "object") return raw.response;
    const text = s(raw?.response ?? raw?.result ?? raw).replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "");
    return JSON.parse(text);
}

function sanitizeUserInputs(value: any): Record<string, string> {
    if (!value || typeof value !== "object" || Array.isArray(value)) return {};
    const entries = Object.entries(value)
        .slice(0, 12)
        .map(([key, item]) => [safePromptText(key, 16), safePromptText(item, 80)])
        .filter(([key, item]) => key && item);
    return Object.fromEntries(entries);
}

function sanitizeResultDocument(value: any): Record<string, any> {
    const doc = value && typeof value === "object" && !Array.isArray(value) ? value : {};
    return {
        title: safePromptText(doc.title, 36),
        subtitle: safePromptText(doc.subtitle, 52),
        evidence: safeTextArray(doc.evidence, 3, 80).filter((item) => !containsUnsafeText(item)),
        resultLevel: safePromptText(doc.resultLevel, 24),
        quote: safePromptText(doc.quote, 72),
        finalComment: safePromptText(doc.finalComment, 100),
    };
}

function validateOptimizedCopy(value: any): any | null {
    if (!value || typeof value !== "object" || Array.isArray(value) || !hasExactKeys(value, OPTIMIZED_COPY_KEYS)) return null;
    const title = outputText(value.title, 18);
    const subtitle = outputText(value.subtitle, 30, true);
    const evidence = outputTextArray(value.evidence, 1, 3, 28);
    const resultLevel = outputText(value.resultLevel, 16);
    const quote = outputText(value.quote, 36);
    const finalComment = outputText(value.finalComment, 50);
    if (title === null || subtitle === null || evidence === null || resultLevel === null || quote === null || finalComment === null) return null;
    const result = {
        title,
        subtitle,
        evidence,
        resultLevel,
        quote,
        finalComment,
    };
    return result;
}

function validateTemplateCopy(value: any): any | null {
    if (!value || typeof value !== "object" || Array.isArray(value) || !hasExactKeys(value, TEMPLATE_COPY_KEYS)) return null;
    const stats = outputTextArray(value.stats, 2, 4, 12);
    const evidencePool = outputTextArray(value.evidencePool, 3, 8, 28);
    const finalPool = outputTextArray(value.finalPool, 2, 6, 50);
    const levels = outputTextArray(value.levels, 2, 6, 16);
    if (stats === null || evidencePool === null || finalPool === null || levels === null) return null;
    const result = {
        stats,
        evidencePool,
        finalPool,
        levels,
    };
    return result;
}

async function runJSONAI(env: Env, system: string, user: string, jsonSchema: Record<string, any>): Promise<any> {
    const model = env.AI_MODEL || DEFAULT_AI_MODEL;
    const response = await env.AI.run(model, {
        messages: [
            { role: "system", content: system },
            { role: "user", content: user },
        ],
        response_format: {
            type: "json_schema",
            json_schema: jsonSchema,
        },
        max_tokens: 900,
        temperature: 0.75,
    });
    return parseAIJSON(response);
}

// Map a templates row (joined with template_stats) to the frontend RemoteTemplate shape.
// Frontend uses camelCase and requires stats fields even when none exist yet.
function mapTemplate(row: any, origin: string = ''): any {
    if (!row) return null;
    return {
        id: s(row.id),
        title: s(row.title),
        description: s(row.description),
        coverImage: rewriteImageUrl(s(row.cover_image), origin),
        category: s(row.category),
        authorId: s(row.author_id),
        authorName: s(row.author_name),
        viewCount: n(row.view_count),
        startCount: n(row.start_count),
        generateCount: n(row.generate_count),
        usageCount: n(row.usage_count),
        shareCount: n(row.share_count),
        likeCount: n(row.like_count),
        reportCount: n(row.report_count),
        status: s(row.status, 'draft'),
        createdAt: s(row.created_at),
        updatedAt: s(row.updated_at || row.created_at),
        formConfigRaw: row.form_config_raw ?? null,
        resultConfigRaw: row.result_config_raw ?? null,
    };
}

function mapWork(row: any, origin: string = '', revealAuthor: boolean = false): any {
    if (!row) return null;
    let tags: string[] = [];
    if (row.tags) {
        try {
            const parsed = JSON.parse(row.tags);
            if (Array.isArray(parsed)) tags = parsed.map((t: any) => String(t));
        } catch { /* ignore */ }
    }
    const isAnonymous = row.is_anonymous === 1 || row.is_anonymous === true;
    return {
        id: s(row.id),
        title: s(row.title),
        description: s(row.description),
        imageUrl: rewriteImageUrl(s(row.image_url), origin),
        authorId: isAnonymous && !revealAuthor ? '' : s(row.author_id),
        authorName: isAnonymous && !revealAuthor ? '匿名用户' : s(row.author_name),
        authorAvatar: isAnonymous && !revealAuthor ? '' : s(row.author_avatar),
        templateId: s(row.template_id),
        category: s(row.category),
        isAnonymous,
        tags,
        likeCount: n(row.like_count),
        reportCount: n(row.report_count),
        createdAt: s(row.created_at),
    };
}

/// Rewrite legacy/dead R2 hostnames to the worker-served proxy path.
/// Existing rows in DB may carry the old `r2.zhenghuoju.com` prefix from when
/// uploads pointed to a public R2 domain that never got configured. We map
/// those URLs to `${origin}/api/images/<key>` on the fly.
function rewriteImageUrl(raw: string, origin: string): string {
    if (!raw) return raw;
    const deadPrefix = "https://r2.zhenghuoju.com/";
    if (raw.startsWith(deadPrefix) && origin) {
        const key = raw.slice(deadPrefix.length);
        return `${origin}/api/images/${key}`;
    }
    return raw;
}

function imageKeyFromUrl(raw: string): string | null {
    const proxyMarker = "/api/images/";
    const markerIndex = raw.indexOf(proxyMarker);
    if (markerIndex >= 0) return decodeURIComponent(raw.slice(markerIndex + proxyMarker.length));

    const legacyPrefix = "https://r2.zhenghuoju.com/";
    if (raw.startsWith(legacyPrefix)) return decodeURIComponent(raw.slice(legacyPrefix.length));
    return null;
}

async function hashToken(token: string): Promise<string> {
    const encoder = new TextEncoder();
    const data = encoder.encode(token);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

function normalizePhone(value: any): string {
    return cleanText(value).replace(/\s+/g, '');
}

function isValidMainlandPhone(value: any): boolean {
    return /^1[3-9]\d{9}$/.test(normalizePhone(value));
}

function maskPhone(phone: string): string {
    return `${phone.slice(0, 3)}****${phone.slice(-4)}`;
}

function randomToken(): string {
    return `${crypto.randomUUID()}${crypto.randomUUID()}`.replace(/-/g, '');
}

function isoAfterSeconds(seconds: number): string {
    return new Date(Date.now() + seconds * 1000).toISOString();
}

async function secureHash(value: string, pepper: string): Promise<string> {
    return hashToken(`${pepper}:${value}`);
}

async function hashPassword(password: string, salt: string): Promise<string> {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveBits']);
    const bits = await crypto.subtle.deriveBits({
        name: 'PBKDF2',
        hash: 'SHA-256',
        salt: encoder.encode(salt),
        iterations: 120000,
    }, key, 256);
    return Array.from(new Uint8Array(bits)).map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

function aliyunPercentEncode(value: string): string {
    return encodeURIComponent(value).replace(/\+/g, '%20').replace(/\*/g, '%2A').replace(/%7E/g, '~');
}

async function hmacSHA1Base64(secret: string, content: string): Promise<string> {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey('raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-1' }, false, ['sign']);
    const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(content));
    let binary = '';
    for (const byte of new Uint8Array(signature)) binary += String.fromCharCode(byte);
    return btoa(binary);
}

async function callAliyunDypns(env: Env, action: string, actionParameters: Record<string, string>): Promise<any> {
    if (!env.ALIYUN_ACCESS_KEY_ID || !env.ALIYUN_ACCESS_KEY_SECRET) {
        throw new Error('ALIYUN_SMS_NOT_CONFIGURED');
    }
    const parameters: Record<string, string> = {
        AccessKeyId: env.ALIYUN_ACCESS_KEY_ID,
        Action: action,
        Format: 'JSON',
        SignatureMethod: 'HMAC-SHA1',
        SignatureNonce: crypto.randomUUID(),
        SignatureVersion: '1.0',
        Timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
        Version: '2017-05-25',
        ...actionParameters,
    };
    const canonicalized = Object.keys(parameters)
        .sort()
        .map((key) => `${aliyunPercentEncode(key)}=${aliyunPercentEncode(parameters[key])}`)
        .join('&');
    const stringToSign = `POST&%2F&${aliyunPercentEncode(canonicalized)}`;
    const signature = await hmacSHA1Base64(`${env.ALIYUN_ACCESS_KEY_SECRET}&`, stringToSign);
    const body = new URLSearchParams({ ...parameters, Signature: signature });
    const response = await fetch('https://dypnsapi.aliyuncs.com/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8' },
        body,
    });
    const json: any = await response.json();
    if (!response.ok || s(json?.Code) !== 'OK') {
        console.error('Aliyun Dypns request failed', { action, code: s(json?.Code), requestId: s(json?.RequestId) });
        throw new Error(`ALIYUN_SMS_FAILED:${s(json?.Code, 'UNKNOWN')}`);
    }
    return json;
}

async function ensureAccountTables(env: Env): Promise<void> {
    await env.DB.batch([
        env.DB.prepare(`
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
            )
        `),
        env.DB.prepare(`
            CREATE TABLE IF NOT EXISTS account_sessions (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                token_hash TEXT NOT NULL UNIQUE,
                expires_at DATETIME NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                last_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                revoked_at DATETIME
            )
        `),
        env.DB.prepare(`
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
            )
        `),
        env.DB.prepare(`
            CREATE TABLE IF NOT EXISTS account_migrations (
                legacy_user_id TEXT PRIMARY KEY,
                account_user_id TEXT NOT NULL,
                migrated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `),
        env.DB.prepare('CREATE INDEX IF NOT EXISTS idx_account_sessions_token ON account_sessions(token_hash, expires_at)'),
        env.DB.prepare('CREATE INDEX IF NOT EXISTS idx_sms_requests_phone_created ON sms_requests(phone_hash, created_at)'),
        env.DB.prepare('CREATE INDEX IF NOT EXISTS idx_sms_requests_ip_created ON sms_requests(ip_hash, created_at)'),
    ]);
}

function accountProfile(row: any): any {
    const vipUntil = s(row?.vip_until);
    const isVip = !!vipUntil && !Number.isNaN(Date.parse(vipUntil)) && Date.parse(vipUntil) > Date.now();
    return {
        id: s(row?.id),
        displayId: s(row?.id).replace(/-/g, '').slice(-8).toUpperCase(),
        phoneMasked: s(row?.phone_mask),
        nickname: s(row?.nickname, '整活新人'),
        bio: s(row?.bio),
        avatar: s(row?.avatar_url, 'logo'),
        isVip,
        vipPlan: s(row?.vip_plan),
        vipUntil,
    };
}

async function getAccount(env: Env, userId: string): Promise<any | null> {
    await ensureAccountTables(env);
    return env.DB.prepare("SELECT * FROM accounts WHERE id = ? AND status = 'active'").bind(userId).first();
}

async function getAuthorProfile(env: Env, userId: string, fallbackName: any = '', fallbackAvatar: any = ''): Promise<{ nickname: string; avatar: string }> {
    const account = await getAccount(env, userId);
    return account
        ? { nickname: s(account.nickname, '整活新人'), avatar: s(account.avatar_url, 'logo') }
        : { nickname: safeText(fallbackName, 12), avatar: safeText(fallbackAvatar, 2048) };
}

async function createAccountSession(env: Env, userId: string): Promise<string> {
    const token = randomToken();
    await env.DB.prepare(`
        INSERT INTO account_sessions (id, user_id, token_hash, expires_at)
        VALUES (?, ?, ?, ?)
    `).bind(crypto.randomUUID(), userId, await hashToken(token), isoAfterSeconds(30 * 24 * 60 * 60)).run();
    return token;
}

async function transferLegacyIdentity(env: Env, accountUserId: string, legacyUserId: any, legacyInstallToken: any): Promise<void> {
    const oldId = cleanText(legacyUserId);
    const token = cleanText(legacyInstallToken);
    if (!oldId || !token) return;
    const oldUser: any = await env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(oldId).first();
    if (!oldUser || s(oldUser.install_token_hash) !== await hashToken(token)) return;
    const existing = await env.DB.prepare('SELECT legacy_user_id FROM account_migrations WHERE legacy_user_id = ?').bind(oldId).first();
    if (existing) return;
    await env.DB.batch([
        env.DB.prepare('UPDATE templates SET author_id = ? WHERE author_id = ?').bind(accountUserId, oldId),
        env.DB.prepare('UPDATE works SET author_id = ? WHERE author_id = ?').bind(accountUserId, oldId),
        env.DB.prepare('UPDATE ai_usage SET user_id = ? WHERE user_id = ?').bind(accountUserId, oldId),
        env.DB.prepare('INSERT INTO account_migrations (legacy_user_id, account_user_id) VALUES (?, ?)').bind(oldId, accountUserId),
    ]);
    if (oldUser.vip_until) {
        await env.DB.prepare('UPDATE accounts SET vip_until = ?, vip_plan = ? WHERE id = ? AND (vip_until IS NULL OR vip_until < ?)')
            .bind(s(oldUser.vip_until), s(oldUser.vip_plan), accountUserId, s(oldUser.vip_until)).run();
    }
}

async function authenticateAccount(request: Request, env: Env): Promise<string | null> {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) return null;
    await ensureAccountTables(env);
    const tokenHash = await hashToken(authHeader.slice(7));
    const session: any = await env.DB.prepare(`
        SELECT s.user_id FROM account_sessions s
        JOIN accounts a ON a.id = s.user_id
        WHERE s.token_hash = ? AND s.revoked_at IS NULL
          AND s.expires_at > CURRENT_TIMESTAMP AND a.status = 'active'
    `).bind(tokenHash).first();
    return session ? s(session.user_id) : null;
}

async function verifySMSChallenge(env: Env, challengeId: string, phone: string, purpose: string, code: string): Promise<boolean> {
    const pepper = s(env.AUTH_HASH_PEPPER);
    if (!pepper) throw new Error('AUTH_NOT_CONFIGURED');
    const phoneHash = await secureHash(phone, pepper);
    const challenge: any = await env.DB.prepare(`
        SELECT * FROM sms_requests
        WHERE id = ? AND phone_hash = ? AND purpose = ? AND status = 'sent'
          AND expires_at > CURRENT_TIMESTAMP
    `).bind(challengeId, phoneHash, purpose).first();
    if (!challenge || n(challenge.attempt_count) >= 5) return false;
    await env.DB.prepare('UPDATE sms_requests SET attempt_count = attempt_count + 1 WHERE id = ?').bind(challengeId).run();
    const checked = await callAliyunDypns(env, 'CheckSmsVerifyCode', {
        ...(env.ALIYUN_SMS_SCHEME_NAME ? { SchemeName: env.ALIYUN_SMS_SCHEME_NAME } : {}),
        CountryCode: '86',
        PhoneNumber: phone,
        VerifyCode: code,
        OutId: challengeId,
    });
    const passed = s(checked?.Model?.VerifyResult).toUpperCase() === 'PASS';
    await env.DB.prepare("UPDATE sms_requests SET status = ? WHERE id = ?")
        .bind(passed ? 'verified' : 'sent', challengeId).run();
    return passed;
}

async function ensureWorkLikesTable(env: Env): Promise<void> {
    await env.DB.prepare(`
        CREATE TABLE IF NOT EXISTS work_likes (
            work_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (work_id, user_id)
        )
    `).run();
}

async function verifyAuth(request: Request, env: Env): Promise<string | null> {
    const accountUserId = await authenticateAccount(request, env);
    if (accountUserId) return accountUserId;

    const userId = request.headers.get("X-Anonymous-User-Id");
    const authHeader = request.headers.get("Authorization");

    if (!userId || !authHeader || !authHeader.startsWith("Bearer ")) {
        console.log("Auth failed: missing headers", { userId: !!userId, authHeader: !!authHeader });
        return null;
    }

    const token = authHeader.substring(7);
    const tokenHash = await hashToken(token);
    let user: any = await env.DB.prepare("SELECT * FROM users WHERE id = ?").bind(s(userId)).first();

    // If user doesn't exist, auto-register them
    if (!user) {
        console.log("User not found, auto-registering:", userId);
        await env.DB.prepare(`INSERT OR REPLACE INTO users (id, install_token_hash, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)`).bind(s(userId), s(tokenHash)).run();
        user = { id: userId, install_token_hash: tokenHash };
    }

    if (user.install_token_hash !== tokenHash) {
        console.log("Auth failed: token mismatch");
        return null;
    }
    return userId;
}

export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
        const url = new URL(request.url);
        const path = url.pathname;
        const method = request.method;

        const corsHeaders = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,HEAD,POST,OPTIONS,PUT,DELETE",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Anonymous-User-Id, X-Debug-Vip",
        };

        if (method === "OPTIONS") return new Response(null, { headers: corsHeaders });

        try {
            // ---- PUBLIC ENDPOINTS ----

            // 1. Phone Account Authentication
            if (path === "/api/auth/sms/send" && method === "POST") {
                await ensureAccountTables(env);
                const body: any = await request.json();
                const phone = normalizePhone(body.phone);
                const purpose = s(body.purpose);
                const clientInstallId = safeText(body.clientInstallId, 128);
                if (!isValidMainlandPhone(phone) || !['register', 'login'].includes(purpose) || !clientInstallId) {
                    return Response.json({ error: 'Invalid SMS request', code: 'SMS_INVALID_REQUEST' }, { status: 400, headers: corsHeaders });
                }
                if (!env.AUTH_HASH_PEPPER || !env.ALIYUN_ACCESS_KEY_ID || !env.ALIYUN_ACCESS_KEY_SECRET ||
                    !env.ALIYUN_SMS_SIGN_NAME || !env.ALIYUN_SMS_TEMPLATE_CODE) {
                    return Response.json({ error: 'SMS service is not configured', code: 'SMS_NOT_CONFIGURED' }, { status: 503, headers: corsHeaders });
                }
                const pepper = env.AUTH_HASH_PEPPER;
                const phoneHash = await secureHash(phone, pepper);
                const ipHash = await secureHash(request.headers.get('CF-Connecting-IP') || 'unknown', pepper);
                const clientHash = await secureHash(clientInstallId, pepper);
                const account = await env.DB.prepare("SELECT id FROM accounts WHERE phone_hash = ? AND status = 'active'").bind(phoneHash).first();
                if ((purpose === 'register' && account) || (purpose === 'login' && !account)) {
                    return Response.json({
                        error: purpose === 'register' ? 'Phone number is already registered' : 'Account does not exist',
                        code: purpose === 'register' ? 'ACCOUNT_EXISTS' : 'ACCOUNT_NOT_FOUND',
                    }, { status: 409, headers: corsHeaders });
                }
                const recentPhone = n(await env.DB.prepare("SELECT COUNT(*) AS c FROM sms_requests WHERE phone_hash = ? AND created_at >= datetime('now', '-60 seconds')").bind(phoneHash).first('c'));
                const dailyPhone = n(await env.DB.prepare("SELECT COUNT(*) AS c FROM sms_requests WHERE phone_hash = ? AND created_at >= datetime('now', '-24 hours')").bind(phoneHash).first('c'));
                const hourlyIP = n(await env.DB.prepare("SELECT COUNT(*) AS c FROM sms_requests WHERE ip_hash = ? AND created_at >= datetime('now', '-1 hour')").bind(ipHash).first('c'));
                const hourlyClient = n(await env.DB.prepare("SELECT COUNT(*) AS c FROM sms_requests WHERE client_hash = ? AND created_at >= datetime('now', '-1 hour')").bind(clientHash).first('c'));
                const globalTenMinutes = n(await env.DB.prepare("SELECT COUNT(*) AS c FROM sms_requests WHERE created_at >= datetime('now', '-10 minutes')").first('c'));
                if (recentPhone >= 1 || dailyPhone >= 8 || hourlyIP >= 20 || hourlyClient >= 8 || globalTenMinutes >= 300) {
                    return Response.json({ error: 'Too many SMS requests', code: 'SMS_RATE_LIMITED' }, { status: 429, headers: corsHeaders });
                }
                const challengeId = crypto.randomUUID();
                await env.DB.prepare(`
                    INSERT INTO sms_requests (id, phone_hash, purpose, ip_hash, client_hash, status, expires_at)
                    VALUES (?, ?, ?, ?, ?, 'pending', ?)
                `).bind(challengeId, phoneHash, purpose, ipHash, clientHash, isoAfterSeconds(300)).run();
                try {
                    const sent = await callAliyunDypns(env, 'SendSmsVerifyCode', {
                        ...(env.ALIYUN_SMS_SCHEME_NAME ? { SchemeName: env.ALIYUN_SMS_SCHEME_NAME } : {}),
                        CountryCode: '86',
                        PhoneNumber: phone,
                        SignName: env.ALIYUN_SMS_SIGN_NAME,
                        TemplateCode: env.ALIYUN_SMS_TEMPLATE_CODE,
                        TemplateParam: env.ALIYUN_SMS_TEMPLATE_PARAM || '{"code":"##code##","min":"5"}',
                        OutId: challengeId,
                        CodeLength: '6',
                        ValidTime: '300',
                        DuplicatePolicy: '1',
                        Interval: '60',
                        CodeType: '1',
                        ReturnVerifyCode: 'false',
                    });
                    await env.DB.prepare("UPDATE sms_requests SET status = 'sent', provider_request_id = ? WHERE id = ?")
                        .bind(s(sent?.RequestId), challengeId).run();
                    return Response.json({ challengeId, cooldownSeconds: 60, expiresInSeconds: 300 }, { headers: corsHeaders });
                } catch (error) {
                    await env.DB.prepare("UPDATE sms_requests SET status = 'failed' WHERE id = ?").bind(challengeId).run();
                    console.error('SMS send failed', { challengeId, reason: s((error as any)?.message) });
                    return Response.json({ error: 'SMS service is temporarily unavailable', code: 'SMS_UPSTREAM_FAILED' }, { status: 502, headers: corsHeaders });
                }
            }

            if ((path === "/api/auth/register" || path === "/api/auth/login") && method === "POST") {
                await ensureAccountTables(env);
                const body: any = await request.json();
                const purpose = path.endsWith('/register') ? 'register' : 'login';
                const phone = normalizePhone(body.phone);
                const code = cleanText(body.code);
                const challengeId = safeText(body.challengeId, 128);
                if (!isValidMainlandPhone(phone) || !/^\d{4,6}$/.test(code) || !challengeId) {
                    return Response.json({ error: 'Invalid verification request', code: 'SMS_INVALID_REQUEST' }, { status: 400, headers: corsHeaders });
                }
                if (!env.AUTH_HASH_PEPPER) {
                    return Response.json({ error: 'Authentication service is not configured', code: 'AUTH_NOT_CONFIGURED' }, { status: 503, headers: corsHeaders });
                }
                const nickname = cleanText(body.nickname);
                const password = s(body.password);
                if (purpose === 'register' && (!body.agreedToTerms || nickname.length < 2 || nickname.length > 12 ||
                    containsUnsafeText(nickname) || password.length < 6 || password.length > 20)) {
                    return Response.json({ error: 'Invalid registration fields', code: 'REGISTER_INVALID_FIELDS' }, { status: 400, headers: corsHeaders });
                }
                let verified = false;
                try {
                    verified = await verifySMSChallenge(env, challengeId, phone, purpose, code);
                } catch (error) {
                    console.error('SMS verification failed', { challengeId, reason: s((error as any)?.message) });
                    return Response.json({ error: 'SMS verification service is temporarily unavailable', code: 'SMS_UPSTREAM_FAILED' }, { status: 502, headers: corsHeaders });
                }
                if (!verified) {
                    return Response.json({ error: 'Verification code is incorrect or expired', code: 'SMS_CODE_INVALID' }, { status: 400, headers: corsHeaders });
                }
                const phoneHash = await secureHash(phone, env.AUTH_HASH_PEPPER);
                let account: any;
                if (purpose === 'register') {
                    if (await env.DB.prepare('SELECT id FROM accounts WHERE phone_hash = ?').bind(phoneHash).first()) {
                        return Response.json({ error: 'Phone number is already registered', code: 'ACCOUNT_EXISTS' }, { status: 409, headers: corsHeaders });
                    }
                    const userId = crypto.randomUUID();
                    const salt = randomToken().slice(0, 32);
                    await env.DB.prepare(`
                        INSERT INTO accounts (id, phone_hash, phone_mask, nickname, bio, avatar_url, password_hash, password_salt, accepted_terms_at)
                        VALUES (?, ?, ?, ?, '', 'logo', ?, ?, CURRENT_TIMESTAMP)
                    `).bind(userId, phoneHash, maskPhone(phone), nickname, await hashPassword(password, salt), salt).run();
                    await transferLegacyIdentity(env, userId, body.legacyUserId, body.legacyInstallToken);
                    account = await getAccount(env, userId);
                } else {
                    account = await env.DB.prepare("SELECT * FROM accounts WHERE phone_hash = ? AND status = 'active'").bind(phoneHash).first();
                    if (!account) return Response.json({ error: 'Account does not exist', code: 'ACCOUNT_NOT_FOUND' }, { status: 404, headers: corsHeaders });
                }
                const token = await createAccountSession(env, s(account.id));
                return Response.json({ token, profile: accountProfile(await getAccount(env, s(account.id))) }, { headers: corsHeaders });
            }

            // 2. Legacy anonymous device auth. Retained temporarily for older app builds.
            if (path === "/api/auth/device" && method === "POST") {
                const body: any = await request.json();
                if (!isTextWithin(body.anonymousUserId, 128) || !isTextWithin(body.installToken, 128)) {
                    return Response.json({ error: "Missing fields" }, { status: 400, headers: corsHeaders });
                }
                const tokenHash = await hashToken(body.installToken);
                await env.DB.prepare(`
                    INSERT INTO users (id, install_token_hash, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)
                    ON CONFLICT(id) DO UPDATE SET install_token_hash = excluded.install_token_hash
                `).bind(s(body.anonymousUserId), s(tokenHash)).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }

            // 3. Templates Feed & Trending
            if (path === "/api/templates" && method === "GET") {
                const { results } = await env.DB.prepare(`
                    SELECT t.*, ts.view_count, ts.start_count, ts.generate_count, ts.usage_count, ts.share_count, ts.like_count, ts.report_count
                    FROM templates t LEFT JOIN template_stats ts ON ts.template_id = t.id
                    WHERE t.status = 'published' ORDER BY t.created_at DESC LIMIT 20
                `).all();
                return Response.json((results || []).map((r: any) => mapTemplate(r, url.origin)), { headers: corsHeaders });
            }
            if (path === "/api/templates/featured" && method === "GET") {
                const { results } = await env.DB.prepare(`
                    SELECT t.*, ts.view_count, ts.start_count, ts.generate_count, ts.usage_count, ts.share_count, ts.like_count, ts.report_count
                    FROM templates t LEFT JOIN template_stats ts ON ts.template_id = t.id
                    WHERE t.status = 'published' LIMIT 5
                `).all();
                return Response.json((results || []).map((r: any) => mapTemplate(r, url.origin)), { headers: corsHeaders });
            }
            if (path === "/api/templates/trending" && method === "GET") {
                const { results } = await env.DB.prepare(`
                    SELECT t.*, ts.view_count, ts.start_count, ts.generate_count, ts.usage_count, ts.share_count, ts.like_count, ts.report_count
                    FROM templates t LEFT JOIN template_stats ts ON ts.template_id = t.id
                    WHERE t.status = 'published' LIMIT 10
                `).all();
                return Response.json((results || []).map((r: any) => mapTemplate(r, url.origin)), { headers: corsHeaders });
            }

            // 3. Works Feed
            if (path === "/api/works/feed" && method === "GET") {
                const offset = Math.max(0, Math.min(10000, n(url.searchParams.get("offset"))));
                const limit = Math.max(1, Math.min(50, n(url.searchParams.get("limit"), 20)));
                const { results } = await env.DB.prepare("SELECT * FROM works ORDER BY created_at DESC LIMIT ? OFFSET ?").bind(limit, offset).all();
                return Response.json((results || []).map((r: any) => mapWork(r, url.origin)), { headers: corsHeaders });
            }

            // 4. Template & Work Details (Public)
            const templateDetailMatch = path.match(/^\/api\/templates\/([^\/]+)$/);
            if (templateDetailMatch && method === "GET") {
                const template = await env.DB.prepare(`
                    SELECT t.*, ts.view_count, ts.start_count, ts.generate_count, ts.usage_count, ts.share_count, ts.like_count, ts.report_count
                    FROM templates t LEFT JOIN template_stats ts ON ts.template_id = t.id
                    WHERE t.id = ? AND t.status = 'published'
                `).bind(s(templateDetailMatch[1])).first();
                if (!template) return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
                return Response.json(mapTemplate(template, url.origin), { headers: corsHeaders });
            }

            const workDetailMatch = path.match(/^\/api\/works\/([^\/]+)$/);
            if (workDetailMatch && method === "GET") {
                const work = await env.DB.prepare("SELECT * FROM works WHERE id = ?").bind(s(workDetailMatch[1])).first();
                if (!work) return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
                return Response.json(mapWork(work, url.origin), { headers: corsHeaders });
            }

            // ---- EVENTS (Public / Unauthenticated Tracking) ----
            const templateEventMatch = path.match(/^\/api\/templates\/([^\/]+)\/events$/);
            if (templateEventMatch && method === "POST") {
                const id = s(templateEventMatch[1]);
                const body: any = await request.json();
                const type = body.eventType;
                if (!id) return Response.json({ error: "Missing template id" }, { status: 400, headers: corsHeaders });
                await env.DB.prepare(`INSERT OR IGNORE INTO template_stats (template_id) VALUES (?)`).bind(id).run();
                if (type === "template_view") await env.DB.prepare(`UPDATE template_stats SET view_count = view_count + 1 WHERE template_id = ?`).bind(id).run();
                if (type === "template_start") await env.DB.prepare(`UPDATE template_stats SET start_count = start_count + 1 WHERE template_id = ?`).bind(id).run();
                if (type === "template_generate") await env.DB.prepare(`UPDATE template_stats SET generate_count = generate_count + 1, usage_count = usage_count + 1 WHERE template_id = ?`).bind(id).run();
                if (type === "template_share") await env.DB.prepare(`UPDATE template_stats SET share_count = share_count + 1 WHERE template_id = ?`).bind(id).run();
                if (type === "template_like") await env.DB.prepare(`UPDATE template_stats SET like_count = like_count + 1 WHERE template_id = ?`).bind(id).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }

            // ---- PUBLIC IMAGE PROXY (before auth) ----
            // Streams an R2 object back to the client. Public; no auth required.
            const imageMatch = path.match(/^\/api\/images\/(.+)$/);
            if (imageMatch && (method === "GET" || method === "HEAD")) {
                const key = decodeURIComponent(imageMatch[1]);
                const obj = await env.BUCKET.get(key);
                if (!obj) {
                    return new Response("Not found", { status: 404, headers: corsHeaders });
                }
                const headers = new Headers(corsHeaders);
                obj.writeHttpMetadata(headers);
                headers.set("etag", obj.httpEtag);
                headers.set("cache-control", "public, max-age=31536000, immutable");
                return new Response(method === "HEAD" ? null : obj.body, { headers });
            }

            // ---- REQUIRE AUTHENTICATION ----
            const userId = await verifyAuth(request, env);
            if (!userId) {
                return Response.json({ error: "Unauthorized" }, { status: 401, headers: corsHeaders });
            }
            const safeUserId = s(userId);

            // ---- PROTECTED ACCOUNT ENDPOINTS ----
            if (path === "/api/auth/me" && method === "GET") {
                const account = await getAccount(env, safeUserId);
                if (!account) return Response.json({ error: 'Account login required', code: 'ACCOUNT_LOGIN_REQUIRED' }, { status: 401, headers: corsHeaders });
                return Response.json({ profile: accountProfile(account) }, { headers: corsHeaders });
            }

            if (path === "/api/auth/logout" && method === "POST") {
                const authHeader = request.headers.get('Authorization');
                if (authHeader?.startsWith('Bearer ')) {
                    await env.DB.prepare('UPDATE account_sessions SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = ?')
                        .bind(await hashToken(authHeader.slice(7))).run();
                }
                return Response.json({ success: true }, { headers: corsHeaders });
            }

            if (path === "/api/account/profile" && method === "PUT") {
                const account = await getAccount(env, safeUserId);
                if (!account) return Response.json({ error: 'Account login required', code: 'ACCOUNT_LOGIN_REQUIRED' }, { status: 401, headers: corsHeaders });
                const body: any = await request.json();
                const nickname = cleanText(body.nickname);
                const bio = cleanText(body.bio);
                const avatar = cleanText(body.avatar);
                if (nickname.length < 2 || nickname.length > 12 || bio.length > 80 ||
                    containsUnsafeText(nickname) || containsUnsafeText(bio) || !isAllowedAvatar(avatar)) {
                    return Response.json({ error: 'Invalid profile fields', code: 'PROFILE_INVALID_FIELDS' }, { status: 400, headers: corsHeaders });
                }
                await env.DB.batch([
                    env.DB.prepare('UPDATE accounts SET nickname = ?, bio = ?, avatar_url = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?')
                        .bind(nickname, bio, avatar, safeUserId),
                    env.DB.prepare('UPDATE templates SET author_name = ? WHERE author_id = ?').bind(nickname, safeUserId),
                    env.DB.prepare('UPDATE works SET author_name = ?, author_avatar = ? WHERE author_id = ?').bind(nickname, avatar, safeUserId),
                ]);
                return Response.json({ profile: accountProfile(await getAccount(env, safeUserId)) }, { headers: corsHeaders });
            }

            if (path === "/api/account" && method === "DELETE") {
                const account = await getAccount(env, safeUserId);
                if (!account) return Response.json({ error: 'Account login required', code: 'ACCOUNT_LOGIN_REQUIRED' }, { status: 401, headers: corsHeaders });
                await env.DB.batch([
                    env.DB.prepare("UPDATE accounts SET status = 'deleted', phone_hash = ?, phone_mask = '', nickname = '已注销用户', bio = '', avatar_url = 'logo', password_hash = ?, password_salt = ?, vip_until = NULL, vip_plan = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = ?")
                        .bind(`deleted:${safeUserId}:${Date.now()}`, randomToken(), randomToken(), safeUserId),
                    env.DB.prepare('UPDATE account_sessions SET revoked_at = CURRENT_TIMESTAMP WHERE user_id = ?').bind(safeUserId),
                    env.DB.prepare("UPDATE templates SET status = 'hidden', author_name = '已注销用户' WHERE author_id = ?").bind(safeUserId),
                    env.DB.prepare("UPDATE works SET author_name = '已注销用户', author_avatar = 'logo' WHERE author_id = ?").bind(safeUserId),
                ]);
                return Response.json({ success: true }, { headers: corsHeaders });
            }

            // ---- PROTECTED AI ENDPOINTS ----
            if (path === "/api/ai/status" && method === "GET") {
                return Response.json(await getAIQuotaStatus(request, env, safeUserId), { headers: corsHeaders });
            }

            if (path === "/api/ai/optimize-result" && method === "POST") {
                const body: any = await request.json();
                const requestId = safeText(body.requestId, 128);
                const templateId = safeText(body.templateId, 128);
                const tone = safeText(body.tone || "default", 20);
                if (!requestId || !templateId || !ALLOWED_AI_TONES.has(tone)) {
                    return aiError("AI_INVALID_REQUEST", 400, corsHeaders, "Invalid AI optimize request");
                }

                const quota = await getAIQuotaStatus(request, env, safeUserId);
                if (!quota.isVip && tone !== "default") {
                    return aiError("VIP_REQUIRED", 403, corsHeaders, "VIP is required for custom AI tones");
                }
                if (quota.remaining <= 0) {
                    return aiError("AI_QUOTA_EXCEEDED", 429, corsHeaders, "AI quota exceeded");
                }

                const model = env.AI_MODEL || DEFAULT_AI_MODEL;
                if (!await reserveAIUsage(env, requestId, safeUserId, "optimize_result", tone, model)) {
                    return aiError("AI_REQUEST_REPLAY", 409, corsHeaders, "Duplicate AI request");
                }
                const reservedQuota = await getAIQuotaStatus(request, env, safeUserId);
                if (reservedQuota.used > reservedQuota.limit) {
                    await finishAIUsage(env, requestId, "failed");
                    return aiError("AI_QUOTA_EXCEEDED", 429, corsHeaders, "AI quota exceeded");
                }

                try {
                    const document = sanitizeResultDocument(body.resultDocument);
                    const inputs = sanitizeUserInputs(body.userInputs);
                    const optimized = validateOptimizedCopy(await runJSONAI(
                        env,
                        `你是中文娱乐海报文案编辑。只输出 JSON 对象，字段必须为 title、subtitle、evidence、resultLevel、quote、finalComment。
内容要轻松、有传播感、像朋友群里的神评。不得输出威胁、歧视、隐私信息、恶意羞辱、联系方式或身份证件信息。
evidence 必须是 1 到 3 条字符串。不要改变用户事实，不要解释，不要输出 Markdown。`,
                        JSON.stringify({ templateId, tone, document, userInputs: inputs }),
                        OPTIMIZED_COPY_SCHEMA
                    ));
                    if (!optimized) {
                        await finishAIUsage(env, requestId, "failed");
                        return aiError("AI_INVALID_RESPONSE", 502, corsHeaders, "AI returned invalid content");
                    }
                    await finishAIUsage(env, requestId, "succeeded");
                    return Response.json({
                        ...optimized,
                        quota: await getAIQuotaStatus(request, env, safeUserId),
                    }, { headers: corsHeaders });
                } catch (error) {
                    console.error("AI optimize failed:", error);
                    await finishAIUsage(env, requestId, "failed");
                    return aiError("AI_UPSTREAM_FAILED", 502, corsHeaders, "AI service is temporarily unavailable");
                }
            }

            if (path === "/api/ai/generate-template-copy" && method === "POST") {
                const body: any = await request.json();
                const requestId = safeText(body.requestId, 128);
                const templateTitle = safePromptText(body.templateTitle, 15);
                const category = safePromptText(body.category, 16);
                const tone = safeText(body.tone || "default", 20);
                if (!requestId || !templateTitle || !category || !ALLOWED_AI_TONES.has(tone)) {
                    return aiError("AI_INVALID_REQUEST", 400, corsHeaders, "Invalid AI template request");
                }

                const quota = await getAIQuotaStatus(request, env, safeUserId);
                if (!quota.isVip) {
                    return aiError("VIP_REQUIRED", 403, corsHeaders, "VIP is required for template copy generation");
                }
                if (quota.remaining <= 0) {
                    return aiError("AI_QUOTA_EXCEEDED", 429, corsHeaders, "AI quota exceeded");
                }

                const model = env.AI_MODEL || DEFAULT_AI_MODEL;
                if (!await reserveAIUsage(env, requestId, safeUserId, "generate_template_copy", tone, model)) {
                    return aiError("AI_REQUEST_REPLAY", 409, corsHeaders, "Duplicate AI request");
                }
                const reservedQuota = await getAIQuotaStatus(request, env, safeUserId);
                if (reservedQuota.used > reservedQuota.limit) {
                    await finishAIUsage(env, requestId, "failed");
                    return aiError("AI_QUOTA_EXCEEDED", 429, corsHeaders, "AI quota exceeded");
                }

                try {
                    const generated = validateTemplateCopy(await runJSONAI(
                        env,
                        `你是中文互动玩法策划。只输出 JSON 对象，字段必须为 stats、evidencePool、finalPool、levels。
stats 为 2 到 4 个短指标名称；evidencePool 为至少 3 条轻松证据；finalPool 为至少 2 条海报结论；levels 为至少 2 个结果等级。
内容要适合朋友间娱乐分享，不得输出威胁、歧视、隐私信息、恶意羞辱或联系方式。不要解释，不要输出 Markdown。`,
                        JSON.stringify({ templateTitle, category, tone }),
                        TEMPLATE_COPY_SCHEMA
                    ));
                    if (!generated) {
                        await finishAIUsage(env, requestId, "failed");
                        return aiError("AI_INVALID_RESPONSE", 502, corsHeaders, "AI returned invalid content");
                    }
                    await finishAIUsage(env, requestId, "succeeded");
                    return Response.json({
                        ...generated,
                        quota: await getAIQuotaStatus(request, env, safeUserId),
                    }, { headers: corsHeaders });
                } catch (error) {
                    console.error("AI template copy failed:", error);
                    await finishAIUsage(env, requestId, "failed");
                    return aiError("AI_UPSTREAM_FAILED", 502, corsHeaders, "AI service is temporarily unavailable");
                }
            }

            // ---- PROTECTED CREATOR ENDPOINTS ----
            if (path === "/api/creator/dashboard" && method === "GET") {
                const publishedCount = await env.DB.prepare("SELECT COUNT(*) as c FROM templates WHERE author_id = ? AND status = 'published'").bind(safeUserId).first("c") || 0;
                const stats: any = await env.DB.prepare("SELECT SUM(view_count) as v, SUM(generate_count) as g, SUM(share_count) as s, SUM(like_count) as l FROM template_stats ts JOIN templates t ON ts.template_id = t.id WHERE t.author_id = ?").bind(safeUserId).first();
                return Response.json({
                    publishedCount, totalViewCount: stats?.v || 0, totalGenerateCount: stats?.g || 0, totalShareCount: stats?.s || 0, totalLikeCount: stats?.l || 0
                }, { headers: corsHeaders });
            }

            if (path === "/api/creator/templates" && method === "GET") {
                const { results } = await env.DB.prepare(`
                    SELECT t.*, ts.view_count, ts.start_count, ts.generate_count, ts.usage_count, ts.share_count, ts.like_count, ts.report_count
                    FROM templates t LEFT JOIN template_stats ts ON ts.template_id = t.id
                    WHERE t.author_id = ? ORDER BY t.created_at DESC
                `).bind(safeUserId).all();
                return Response.json((results || []).map((r: any) => mapTemplate(r, url.origin)), { headers: corsHeaders });
            }

            if (path === "/api/creator/works" && method === "GET") {
                const { results } = await env.DB.prepare("SELECT * FROM works WHERE author_id = ? ORDER BY created_at DESC LIMIT 100").bind(safeUserId).all();
                return Response.json((results || []).map((r: any) => mapWork(r, url.origin, true)), { headers: corsHeaders });
            }

            // Creator Actions on Specific Templates
            const creatorActionMatch = path.match(/^\/api\/creator\/templates\/([^\/]+)(?:\/(hide|status|stats))?$/);
            if (creatorActionMatch) {
                const id = s(creatorActionMatch[1]);
                const action = creatorActionMatch[2];

                if (!id) {
                    console.error("Creator action missing id:", { id, userId: safeUserId, path });
                    return Response.json({ error: "Invalid request" }, { status: 400, headers: corsHeaders });
                }

                // Ensure owner
                const check: any = await env.DB.prepare("SELECT id, cover_image FROM templates WHERE id = ? AND author_id = ?").bind(id, safeUserId).first();
                if (!check) return Response.json({ error: "Forbidden" }, { status: 403, headers: corsHeaders });

                if (method === "DELETE" && !action) {
                    await env.DB.prepare("DELETE FROM templates WHERE id = ?").bind(id).run();
                    await env.DB.prepare("DELETE FROM template_stats WHERE template_id = ?").bind(id).run();
                    const coverKey = imageKeyFromUrl(s(check.cover_image));
                    if (coverKey) await env.BUCKET.delete(coverKey);
                    return Response.json({ success: true }, { headers: corsHeaders });
                }
                if (method === "POST" && action === "hide") {
                    await env.DB.prepare("UPDATE templates SET status = 'hidden' WHERE id = ?").bind(id).run();
                    return Response.json({ success: true }, { headers: corsHeaders });
                }
                if (method === "PUT" && action === "status") {
                    const body: any = await request.json();
                    if (!isAllowedTemplateStatus(body.status)) {
                        return Response.json({ error: "Invalid status" }, { status: 400, headers: corsHeaders });
                    }
                    await env.DB.prepare("UPDATE templates SET status = ? WHERE id = ?").bind(s(body.status), id).run();
                    return Response.json({ success: true }, { headers: corsHeaders });
                }
                if (method === "GET" && action === "stats") {
                    const stats: any = await env.DB.prepare("SELECT * FROM template_stats WHERE template_id = ?").bind(id).first();
                    return Response.json({
                        viewCount: n(stats?.view_count),
                        startCount: n(stats?.start_count),
                        generateCount: n(stats?.generate_count),
                        shareCount: n(stats?.share_count),
                        likeCount: n(stats?.like_count),
                        favoriteCount: 0,
                        reportCount: n(stats?.report_count),
                    }, { headers: corsHeaders });
                }
            }

            // ---- PROTECTED TEMPLATE ENDPOINTS ----
            if (path === "/api/templates" && method === "POST") {
                try {
                    const body: any = await request.json();
                    console.log("Creating template - raw body:", JSON.stringify(body));
                    const formConfigRaw = serializeConfig(body.formConfigRaw, body.formConfig);
                    const resultConfigRaw = serializeConfig(body.resultConfigRaw, body.resultConfig);

                    if (!isTextWithin(body.id, 128) ||
                        !isTextWithin(body.title, 15) ||
                        !isTextWithin(body.description, 120) ||
                        !isValidTemplateFormConfig(formConfigRaw) ||
                        !isValidResultConfig(resultConfigRaw)) {
                        return Response.json({
                            error: "Invalid required fields",
                            details: "id, title, description, form config, or result config is invalid",
                            received: { id: body.id, title: body.title }
                        }, { status: 400, headers: corsHeaders });
                    }

                    const author = await getAuthorProfile(env, safeUserId, body.authorName);
                    await env.DB.prepare(`
                        INSERT INTO templates (id, title, description, cover_image, category, author_id, author_name, status, form_config_raw, result_config_raw)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    `).bind(
                        s(body.id),
                        cleanText(body.title),
                        cleanText(body.description),
                        s(body.coverImage),
                        s(body.category),
                        safeUserId,
                        author.nickname,
                        isAllowedTemplateStatus(body.status) ? s(body.status) : 'draft',
                        formConfigRaw,
                        resultConfigRaw
                    ).run();
                    return Response.json({ success: true }, { headers: corsHeaders });
                } catch (err: any) {
                    console.error("Failed to create template:", err);
                    return Response.json({
                        error: "Failed to create template",
                        details: err.message,
                        stack: err.stack,
                        code: "TEMPLATE_CREATE_FAILED"
                    }, { status: 500, headers: corsHeaders });
                }
            }

            if (templateDetailMatch && method === "PUT") {
                try {
                    const id = s(templateDetailMatch[1]);
                    const body: any = await request.json();
                    const formConfigRaw = serializeConfig(body.formConfigRaw, body.formConfig);
                    const resultConfigRaw = serializeConfig(body.resultConfigRaw, body.resultConfig);
                    if (!isTextWithin(body.title, 15) ||
                        !isTextWithin(body.description, 120) ||
                        !isValidTemplateFormConfig(formConfigRaw) ||
                        !isValidResultConfig(resultConfigRaw)) {
                        return Response.json({ error: "Invalid template fields" }, { status: 400, headers: corsHeaders });
                    }
                    await env.DB.prepare(`
                        UPDATE templates SET title = ?, description = ?, cover_image = ?, category = ?, form_config_raw = ?, result_config_raw = ?
                        WHERE id = ? AND author_id = ?
                    `).bind(
                        cleanText(body.title),
                        cleanText(body.description),
                        s(body.coverImage),
                        s(body.category),
                        formConfigRaw,
                        resultConfigRaw,
                        id,
                        safeUserId
                    ).run();
                    return Response.json({ success: true }, { headers: corsHeaders });
                } catch (err: any) {
                    console.error("Failed to update template:", err);
                    return Response.json({
                        error: "Failed to update template",
                        details: err.message,
                        code: "TEMPLATE_UPDATE_FAILED"
                    }, { status: 500, headers: corsHeaders });
                }
            }

            const templatePublishMatch = path.match(/^\/api\/templates\/([^\/]+)\/publish$/);
            if (templatePublishMatch && method === "POST") {
                const tplId = s(templatePublishMatch[1]);
                if (!tplId) return Response.json({ error: "Missing template id" }, { status: 400, headers: corsHeaders });
                await env.DB.prepare("UPDATE templates SET status = 'published' WHERE id = ? AND author_id = ?").bind(tplId, safeUserId).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }

            // ---- PROTECTED WORKS ENDPOINTS ----
            if (path === "/api/works" && method === "POST") {
                try {
                    const body: any = await request.json();
                    console.log("Publishing work - raw body:", JSON.stringify(body));
                    console.log("Publishing work - userId from auth:", safeUserId);

                    // Validate required fields
                    if (!isTextWithin(body.id, 128) ||
                        !isTextWithin(body.templateId, 128) ||
                        !isTextWithin(body.title, 36) ||
                        !isTextWithin(body.description, 160, true) ||
                        !isTextWithin(body.imageUrl, 2048)) {
                        return Response.json({
                            error: "Invalid required fields",
                            details: "id, templateId, title (1-36), description (0-160), and imageUrl are required",
                            received: {
                                id: body.id,
                                templateId: body.templateId,
                                title: body.title,
                                imageUrl: body.imageUrl
                            }
                        }, { status: 400, headers: corsHeaders });
                    }

                    // Ensure all fields have valid values (no undefined)
                    const workData = {
                        id: s(body.id),
                        templateId: s(body.templateId),
                        title: cleanText(body.title),
                        description: cleanText(body.description),
                        isAnonymous: body.isAnonymous ? 1 : 0,
                        authorId: safeUserId,
                        authorName: '',
                        authorAvatar: '',
                        tags: s(JSON.stringify(body.tags ?? [])),
                        category: s(body.category),
                        imageUrl: s(body.imageUrl)
                    };
                    const author = await getAuthorProfile(env, safeUserId, body.authorName, body.authorAvatar);
                    workData.authorName = author.nickname;
                    workData.authorAvatar = author.avatar;

                    console.log("Publishing work - processed data:", JSON.stringify(workData));

                    await env.DB.prepare(`
                        INSERT INTO works (id, template_id, title, description, is_anonymous, author_id, author_name, author_avatar, tags, category, image_url, like_count)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
                    `).bind(
                        workData.id, workData.templateId, workData.title, workData.description, workData.isAnonymous,
                        workData.authorId, workData.authorName, workData.authorAvatar, workData.tags, workData.category, workData.imageUrl
                    ).run();

                    console.log("Work published successfully:", body.id);
                    return Response.json({
                        id: workData.id,
                        imageUrl: workData.imageUrl,
                        createdAt: new Date().toISOString()
                    }, { headers: corsHeaders });
                } catch (err: any) {
                    console.error("Failed to publish work:", err);
                    return Response.json({
                        error: "Failed to publish work",
                        details: err.message,
                        stack: err.stack,
                        code: "PUBLISH_FAILED"
                    }, { status: 500, headers: corsHeaders });
                }
            }

            if (workDetailMatch && method === "DELETE") {
                const id = s(workDetailMatch[1]);
                const ownedWork: any = await env.DB.prepare("SELECT image_url FROM works WHERE id = ? AND author_id = ?").bind(id, safeUserId).first();
                if (!ownedWork) return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
                await env.DB.prepare("DELETE FROM works WHERE id = ? AND author_id = ?").bind(id, safeUserId).run();
                await ensureWorkLikesTable(env);
                await env.DB.prepare("DELETE FROM work_likes WHERE work_id = ?").bind(id).run();
                const imageUrl = s(ownedWork.image_url);
                const imageKey = imageKeyFromUrl(imageUrl);
                if (imageKey) await env.BUCKET.delete(imageKey);
                return Response.json({ success: true }, { headers: corsHeaders });
            }

            const workActionMatch = path.match(/^\/api\/works\/([^\/]+)\/(like|report)$/);
            if (workActionMatch && method === "POST") {
                const id = s(workActionMatch[1]);
                const action = workActionMatch[2];
                if (!id) return Response.json({ error: "Missing work id" }, { status: 400, headers: corsHeaders });
                if (action === "like") {
                    const work = await env.DB.prepare("SELECT id FROM works WHERE id = ?").bind(id).first();
                    if (!work) return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
                    await ensureWorkLikesTable(env);
                    const inserted = await env.DB.prepare("INSERT OR IGNORE INTO work_likes (work_id, user_id) VALUES (?, ?)").bind(id, safeUserId).run();
                    if (n(inserted.meta?.changes) > 0) {
                        await env.DB.prepare("UPDATE works SET like_count = like_count + 1 WHERE id = ?").bind(id).run();
                    }
                    const current: any = await env.DB.prepare("SELECT like_count FROM works WHERE id = ?").bind(id).first();
                    return Response.json({
                        success: true,
                        likeCount: n(current?.like_count),
                        alreadyLiked: n(inserted.meta?.changes) === 0
                    }, { headers: corsHeaders });
                }
                // Report logic omitted; return success
                return Response.json({ success: true }, { headers: corsHeaders });
            }

            if (path === "/api/upload" && method === "POST") {
                try {
                    const contentType = request.headers.get("Content-Type") || "image/jpeg";
                    const imageData = await request.arrayBuffer();

                    console.log("Uploading image:", { contentType, size: imageData.byteLength });

                    if (imageData.byteLength === 0) {
                        return Response.json({
                            error: "Empty image data",
                            code: "EMPTY_IMAGE"
                        }, { status: 400, headers: corsHeaders });
                    }
                    if (!["image/jpeg", "image/png"].includes(contentType) || imageData.byteLength > 10 * 1024 * 1024) {
                        return Response.json({
                            error: "Invalid image",
                            code: "INVALID_IMAGE"
                        }, { status: 400, headers: corsHeaders });
                    }

                    const timestamp = Date.now();
                    const randomStr = Math.random().toString(36).substring(2, 15);
                    const ext = contentType.includes("png") ? "png" : "jpg";
                    const filename = `works/${timestamp}-${randomStr}.${ext}`;

                    await env.BUCKET.put(filename, imageData, {
                        httpMetadata: { contentType: contentType }
                    });

                    // Serve through this worker (no separate R2 public domain needed).
                    const publicUrl = `${url.origin}/api/images/${filename}`;
                    console.log("Image uploaded successfully:", publicUrl);
                    return new Response(publicUrl, { headers: corsHeaders });
                } catch (err: any) {
                    console.error("Failed to upload image:", err);
                    return Response.json({
                        error: "Failed to upload image",
                        details: err.message,
                        code: "UPLOAD_FAILED"
                    }, { status: 500, headers: corsHeaders });
                }
            }

            return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
        } catch (e: any) {
            console.error("API Error:", e);
            return Response.json({
                error: e.message || "Internal server error",
                details: e.stack || "",
                timestamp: new Date().toISOString()
            }, { status: 500, headers: corsHeaders });
        }
    },
};
