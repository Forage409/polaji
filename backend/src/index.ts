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
    
    if (!userId || !authHeader || !authHeader.startsWith("Bearer ")) {
        return null;
    }
    
    const token = authHeader.substring(7);
    const tokenHash = await hashToken(token);
    
    const user: any = await env.DB.prepare("SELECT * FROM users WHERE id = ?").bind(userId).first();
    
    if (!user || user.install_token_hash !== tokenHash) {
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
        
        if (method === "OPTIONS") {
            return new Response(null, { headers: corsHeaders });
        }
        
        try {
            // Public Device Registration
            if (path === "/api/auth/device" && method === "POST") {
                const body: any = await request.json();
                if (!body.anonymousUserId || !body.installToken) {
                    return Response.json({ error: "Missing fields" }, { status: 400, headers: corsHeaders });
                }
                const tokenHash = await hashToken(body.installToken);
                await env.DB.prepare(`
                    INSERT OR REPLACE INTO users (id, install_token_hash, created_at)
                    VALUES (?, ?, CURRENT_TIMESTAMP)
                `).bind(body.anonymousUserId, tokenHash).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            // Public Endpoints
            if (path === "/api/works/feed" && method === "GET") {
                const { results } = await env.DB.prepare("SELECT * FROM works ORDER BY created_at DESC LIMIT 20").all();
                return Response.json(results, { headers: corsHeaders });
            }
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
            
            // Require Authentication for below
            const userId = await verifyAuth(request, env);
            if (!userId) {
                return Response.json({ error: "Unauthorized" }, { status: 401, headers: corsHeaders });
            }
            
            // Protected Endpoints
            if (path === "/api/creator/dashboard" && method === "GET") {
                const publishedCount = await env.DB.prepare("SELECT COUNT(*) as c FROM templates WHERE author_id = ? AND status = 'published'").bind(userId).first("c") || 0;
                const stats: any = await env.DB.prepare("SELECT SUM(view_count) as v, SUM(generate_count) as g, SUM(share_count) as s, SUM(like_count) as l FROM template_stats ts JOIN templates t ON ts.template_id = t.id WHERE t.author_id = ?").bind(userId).first();
                return Response.json({
                    publishedCount,
                    totalViewCount: stats?.v || 0,
                    totalGenerateCount: stats?.g || 0,
                    totalShareCount: stats?.s || 0,
                    totalLikeCount: stats?.l || 0
                }, { headers: corsHeaders });
            }
            
            if (path === "/api/creator/templates" && method === "GET") {
                const { results } = await env.DB.prepare("SELECT * FROM templates WHERE author_id = ? ORDER BY created_at DESC").bind(userId).all();
                return Response.json(results, { headers: corsHeaders });
            }
            
            if (path === "/api/works" && method === "POST") {
                const body: any = await request.json();
                await env.DB.prepare(`
                    INSERT INTO works (id, template_id, title, description, is_anonymous, author_id, author_name, image_url, like_count, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, CURRENT_TIMESTAMP)
                `).bind(
                    body.id, body.templateId, body.title, body.description, body.isAnonymous ? 1 : 0,
                    userId, body.authorName, body.imageUrl || ''
                ).run();
                return Response.json({ success: true }, { headers: corsHeaders });
            }
            
            if (path === "/api/upload" && method === "POST") {
                // Mock upload, should use R2
                return new Response("https://r2.zhenghuoju.com/mock-upload-url", { headers: corsHeaders });
            }
            
            // Basic regex matching for ID routes
            const templateIdMatch = path.match(/^\/api\/templates\/([^\/]+)$/);
            if (templateIdMatch) {
                const id = templateIdMatch[1];
                if (method === "GET") {
                    const template = await env.DB.prepare("SELECT * FROM templates WHERE id = ?").bind(id).first();
                    if (!template) return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
                    return Response.json(template, { headers: corsHeaders });
                }
                if (method === "PUT") {
                    const body: any = await request.json();
                    await env.DB.prepare("UPDATE templates SET title = ?, description = ? WHERE id = ? AND author_id = ?").bind(body.title, body.description, id, userId).run();
                    return Response.json({ success: true }, { headers: corsHeaders });
                }
                if (method === "DELETE") {
                    await env.DB.prepare("DELETE FROM templates WHERE id = ? AND author_id = ?").bind(id, userId).run();
                    return Response.json({ success: true }, { headers: corsHeaders });
                }
            }
            
            // Template Stats
            const templateStatsMatch = path.match(/^\/api\/creator\/templates\/([^\/]+)\/stats$/);
            if (templateStatsMatch && method === "GET") {
                const id = templateStatsMatch[1];
                const stats = await env.DB.prepare("SELECT * FROM template_stats WHERE template_id = ?").bind(id).first();
                return Response.json(stats || { viewCount: 0, startCount: 0, generateCount: 0, shareCount: 0, likeCount: 0 }, { headers: corsHeaders });
            }
            
            return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
        } catch (e: any) {
            return Response.json({ error: e.message }, { status: 500, headers: corsHeaders });
        }
    },
};

