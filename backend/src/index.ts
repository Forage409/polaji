export interface Env {
    BUCKET: R2Bucket;
    DB: D1Database;
}

export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
        const url = new URL(request.url);
        
        // CORS Headers
        const corsHeaders = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,HEAD,POST,OPTIONS,PUT,DELETE",
            "Access-Control-Allow-Headers": "Content-Type",
        };
        
        if (request.method === "OPTIONS") {
            return new Response(null, { headers: corsHeaders });
        }
        
        if (url.pathname === "/api/works/feed" && request.method === "GET") {
            // Fetch from D1
            try {
                const { results } = await env.DB.prepare("SELECT * FROM works ORDER BY created_at DESC LIMIT 20").all();
                return Response.json(results, { headers: corsHeaders });
            } catch (e: any) {
                return Response.json({ error: e.message }, { status: 500, headers: corsHeaders });
            }
        }
        
        if (url.pathname === "/api/uploads/work" && request.method === "POST") {
            // Basic presigned URL generation mock for now, requires AWS SDK or Cloudflare specific approach in a real app
            // We just return a mock URL here to keep things simple for the frontend
            return Response.json({ uploadUrl: "https://r2.zhenghuoju.com/mock-upload-url" }, { headers: corsHeaders });
        }
        
        return new Response("ZhengHuoJu API is running with D1 and R2 bindings", { headers: corsHeaders });
    },
};
