export interface Env {
    BUCKET: R2Bucket;
    DB: D1Database;
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
            "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Anonymous-User-Id",
        };

        if (method === "OPTIONS") return new Response(null, { headers: corsHeaders });

        try {
            // ---- PUBLIC ENDPOINTS ----

            // 1. Auth Device
            if (path === "/api/auth/device" && method === "POST") {
                const body: any = await request.json();
                if (!isTextWithin(body.anonymousUserId, 128) || !isTextWithin(body.installToken, 128)) {
                    return Response.json({ error: "Missing fields" }, { status: 400, headers: corsHeaders });
                }
                const tokenHash = await hashToken(body.installToken);
                await env.DB.prepare(`INSERT OR REPLACE INTO users (id, install_token_hash, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)`).bind(s(body.anonymousUserId), s(tokenHash)).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }

            // 2. Templates Feed & Trending
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
                const check = await env.DB.prepare("SELECT id FROM templates WHERE id = ? AND author_id = ?").bind(id, safeUserId).first();
                if (!check) return Response.json({ error: "Forbidden" }, { status: 403, headers: corsHeaders });

                if (method === "DELETE" && !action) {
                    await env.DB.prepare("DELETE FROM templates WHERE id = ?").bind(id).run();
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
                        s(body.authorName),
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
                        authorName: s(body.authorName),
                        authorAvatar: s(body.authorAvatar),
                        tags: s(JSON.stringify(body.tags ?? [])),
                        category: s(body.category),
                        imageUrl: s(body.imageUrl)
                    };

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
