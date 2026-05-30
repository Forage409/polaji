export interface Env {
    // BUCKET: R2Bucket;
    // DB: D1Database;
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
        
        // Placeholder routing
        if (url.pathname === "/api/works/feed" && request.method === "GET") {
            return Response.json([], { headers: corsHeaders });
        }
        
        if (url.pathname === "/api/uploads/work" && request.method === "POST") {
            // Generates pre-signed URL for R2 upload
            return Response.json({ uploadUrl: "https://r2.zhenghuoju.com/mock-upload-url" }, { headers: corsHeaders });
        }
        
        return new Response("ZhengHuoJu API is running", { headers: corsHeaders });
    },
};
