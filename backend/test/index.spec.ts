import {
	env,
	createExecutionContext,
	waitOnExecutionContext,
	SELF,
} from "cloudflare:test";
import { describe, it, expect } from "vitest";
import worker from "../src";

describe("zhenghuoju worker", () => {
	it("returns 404 for an unknown route (unit style)", async () => {
		const request = new Request<unknown, IncomingRequestCfProperties>(
			"http://example.com/unknown"
		);
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(404);
		expect(await response.json()).toEqual({ error: "Not found" });
	});

	it("returns 404 for an unknown route (integration style)", async () => {
		const response = await SELF.fetch("http://example.com/unknown");

		expect(response.status).toBe(404);
		expect(await response.json()).toEqual({ error: "Not found" });
	});

	it("rejects incomplete anonymous device registration", async () => {
		const response = await SELF.fetch("http://example.com/api/auth/device", {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ anonymousUserId: "device-only" }),
		});

		expect(response.status).toBe(400);
		expect(await response.json()).toEqual({ error: "Missing fields" });
	});
});
