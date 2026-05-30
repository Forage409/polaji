export interface Env {
    BUCKET: R2Bucket;
    DB: D1Database;
}

async function hashToken(token: string): Promise<string> {
    const encoder = new TextEncoder();
    const data = encoder.encode(token);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

async function verifyAuth(request: Request, env: Env): Promise<string | null> {
    const userId = request.headers.get("X-Anonymous-User-Id");
    const authHeader = request.headers.get("Authorization");
    
    if (!userId || !authHeader || !authHeader.startsWith("Bearer ")) return null;
    
    const token = authHeader.substring(7);
    const tokenHash = await hashToken(token);
    const user: any = await env.DB.prepare("SELECT * FROM users WHERE id = ?").bind(userId).first();
    
    if (!user || user.install_token_hash !== tokenHash) return null;
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
                if (!body.anonymousUserId || !body.installToken) return Response.json({ error: "Missing fields" }, { status: 400, headers: corsHeaders });
                const tokenHash = await hashToken(body.installToken);
                await env.DB.prepare(`INSERT OR REPLACE INTO users (id, install_token_hash, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)`).bind(body.anonymousUserId, tokenHash).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            // 2. Templates Feed & Trending
            if (path === "/api/templates" && method === "GET") {
                const { results } = await env.DB.prepare("SELECT * FROM templates WHERE status = 'published' ORDER BY created_at DESC LIMIT 20").all();
                return Response.json(results, { headers: corsHeaders });
            }
            if (path === "/api/templates/featured" && method === "GET") {
                const { results } = await env.DB.prepare("SELECT * FROM templates WHERE status = 'published' LIMIT 5").all();
                return Response.json(results, { headers: corsHeaders });
            }
            if (path === "/api/templates/trending" && method === "GET") {
                const { results } = await env.DB.prepare("SELECT * FROM templates WHERE status = 'published' LIMIT 10").all();
                return Response.json(results, { headers: corsHeaders });
            }
            
            // 3. Works Feed
            if (path === "/api/works/feed" && method === "GET") {
                const { results } = await env.DB.prepare("SELECT * FROM works ORDER BY created_at DESC LIMIT 20").all();
                return Response.json(results, { headers: corsHeaders });
            }
            
            // 4. Template & Work Details (Public)
            const templateDetailMatch = path.match(/^\/api\/templates\/([^\/]+)$/);
            if (templateDetailMatch && method === "GET") {
                const template = await env.DB.prepare("SELECT * FROM templates WHERE id = ?").bind(templateDetailMatch[1]).first();
                if (!template) return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
                return Response.json(template, { headers: corsHeaders });
            }
            
            const workDetailMatch = path.match(/^\/api\/works\/([^\/]+)$/);
            if (workDetailMatch && method === "GET") {
                const work = await env.DB.prepare("SELECT * FROM works WHERE id = ?").bind(workDetailMatch[1]).first();
                if (!work) return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
                return Response.json(work, { headers: corsHeaders });
            }
            
            // ---- EVENTS (Public / Unauthenticated Tracking) ----
            const templateEventMatch = path.match(/^\/api\/templates\/([^\/]+)\/events$/);
            if (templateEventMatch && method === "POST") {
                const id = templateEventMatch[1];
                const body: any = await request.json();
                const type = body.eventType;
                // Upsert template_stats
                await env.DB.prepare(`INSERT OR IGNORE INTO template_stats (template_id) VALUES (?)`).bind(id).run();
                if (type === "template_view") await env.DB.prepare(`UPDATE template_stats SET view_count = view_count + 1 WHERE template_id = ?`).bind(id).run();
                if (type === "template_start") await env.DB.prepare(`UPDATE template_stats SET start_count = start_count + 1 WHERE template_id = ?`).bind(id).run();
                if (type === "template_generate") await env.DB.prepare(`UPDATE template_stats SET generate_count = generate_count + 1, usage_count = usage_count + 1 WHERE template_id = ?`).bind(id).run();
                if (type === "template_share") await env.DB.prepare(`UPDATE template_stats SET share_count = share_count + 1 WHERE template_id = ?`).bind(id).run();
                if (type === "template_like") await env.DB.prepare(`UPDATE template_stats SET like_count = like_count + 1 WHERE template_id = ?`).bind(id).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            // ---- REQUIRE AUTHENTICATION ----
            const userId = await verifyAuth(request, env);
            if (!userId) {
                return Response.json({ error: "Unauthorized" }, { status: 401, headers: corsHeaders });
            }
            
            // ---- PROTECTED CREATOR ENDPOINTS ----
            if (path === "/api/creator/dashboard" && method === "GET") {
                const publishedCount = await env.DB.prepare("SELECT COUNT(*) as c FROM templates WHERE author_id = ? AND status = 'published'").bind(userId).first("c") || 0;
                const stats: any = await env.DB.prepare("SELECT SUM(view_count) as v, SUM(generate_count) as g, SUM(share_count) as s, SUM(like_count) as l FROM template_stats ts JOIN templates t ON ts.template_id = t.id WHERE t.author_id = ?").bind(userId).first();
                return Response.json({
                    publishedCount, totalViewCount: stats?.v || 0, totalGenerateCount: stats?.g || 0, totalShareCount: stats?.s || 0, totalLikeCount: stats?.l || 0
                }, { headers: corsHeaders });
            }
            
            if (path === "/api/creator/templates" && method === "GET") {
                const { results } = await env.DB.prepare("SELECT * FROM templates WHERE author_id = ? ORDER BY created_at DESC").bind(userId).all();
                return Response.json(results, { headers: corsHeaders });
            }
            
            // Creator Actions on Specific Templates
            const creatorActionMatch = path.match(/^\/api\/creator\/templates\/([^\/]+)(?:\/(hide|status|stats))?$/);
            if (creatorActionMatch) {
                const id = creatorActionMatch[1];
                const action = creatorActionMatch[2];
                
                // Ensure owner
                const check = await env.DB.prepare("SELECT id FROM templates WHERE id = ? AND author_id = ?").bind(id, userId).first();
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
                    await env.DB.prepare("UPDATE templates SET status = ? WHERE id = ?").bind(body.status, id).run();
                    return Response.json({ success: true }, { headers: corsHeaders });
                }
                if (method === "GET" && action === "stats") {
                    const stats = await env.DB.prepare("SELECT * FROM template_stats WHERE template_id = ?").bind(id).first();
                    return Response.json(stats || { view_count: 0, start_count: 0, generate_count: 0, share_count: 0, like_count: 0 }, { headers: corsHeaders });
                }
            }
            
            // ---- PROTECTED TEMPLATE ENDPOINTS ----
            if (path === "/api/templates" && method === "POST") {
                const body: any = await request.json();
                await env.DB.prepare(`
                    INSERT INTO templates (id, title, description, cover_image, category, author_id, author_name, status, form_config_raw, result_config_raw)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                `).bind(
                    body.id, body.title, body.description, body.coverImage, body.category,
                    userId, body.authorName, body.status || 'draft',
                    JSON.stringify(body.formConfig), JSON.stringify(body.resultConfig)
                ).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            if (templateDetailMatch && method === "PUT") {
                const id = templateDetailMatch[1];
                const body: any = await request.json();
                await env.DB.prepare(`
                    UPDATE templates SET title = ?, description = ?, cover_image = ?, category = ?, form_config_raw = ?, result_config_raw = ?
                    WHERE id = ? AND author_id = ?
                `).bind(
                    body.title, body.description, body.coverImage, body.category, JSON.stringify(body.formConfig), JSON.stringify(body.resultConfig), id, userId
                ).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            const templatePublishMatch = path.match(/^\/api\/templates\/([^\/]+)\/publish$/);
            if (templatePublishMatch && method === "POST") {
                await env.DB.prepare("UPDATE templates SET status = 'published' WHERE id = ? AND author_id = ?").bind(templatePublishMatch[1], userId).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            // ---- PROTECTED WORKS ENDPOINTS ----
            if (path === "/api/works" && method === "POST") {
                const body: any = await request.json();
                const tagsStr = JSON.stringify(body.tags || []);
                await env.DB.prepare(`
                    INSERT INTO works (id, template_id, title, description, is_anonymous, author_id, author_name, author_avatar, tags, category, image_url, like_count)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
                `).bind(
                    body.id, body.templateId, body.title, body.description, body.isAnonymous ? 1 : 0,
                    userId, body.authorName, body.authorAvatar || '', tagsStr, body.category || '', body.imageUrl || ''
                ).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            if (workDetailMatch && method === "DELETE") {
                await env.DB.prepare("DELETE FROM works WHERE id = ? AND author_id = ?").bind(workDetailMatch[1], userId).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            const workActionMatch = path.match(/^\/api\/works\/([^\/]+)\/(like|report)$/);
            if (workActionMatch && method === "POST") {
                const id = workActionMatch[1];
                const action = workActionMatch[2];
                if (action === "like") await env.DB.prepare("UPDATE works SET like_count = like_count + 1 WHERE id = ?").bind(id).run();
                // We omit report logic for brevity, returning success
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            if (path === "/api/upload" && method === "POST") {
                return new Response("https://r2.zhenghuoju.com/mock-upload-url", { headers: corsHeaders });
            }
            
            return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
        } catch (e: any) {
            return Response.json({ error: e.message }, { status: 500, headers: corsHeaders });
        }
    },
};

