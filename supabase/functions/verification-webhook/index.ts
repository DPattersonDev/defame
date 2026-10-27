import { createClient } from "npm:@supabase/supabase-js@2.57.4";

// Provider adapter contract: sign "<unix timestamp>.<exact request body>" with
// HMAC-SHA256. The callback is server-to-server; there is no client success flag.
Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return new Response("Use POST", { status: 405 });
  const secret = Deno.env.get("VERIFICATION_WEBHOOK_SECRET");
  if (!secret) return new Response("Verification unavailable", { status: 503 });
  try {
    const timestamp = req.headers.get("x-defame-timestamp") ?? "";
    const signature = req.headers.get("x-defame-signature") ?? "";
    if (
      !/^\d{10}$/.test(timestamp) ||
      Math.abs(Date.now() / 1000 - Number(timestamp)) > 300 ||
      !/^[a-f0-9]{64}$/i.test(signature)
    ) {
      return new Response("Invalid signature", { status: 401 });
    }
    const raw = await req.text();
    if (raw.length > 64000) return new Response("Too large", { status: 413 });
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["verify"],
    );
    const bytes = Uint8Array.from(
      signature.match(/.{2}/g)!,
      (v) => parseInt(v, 16),
    );
    const valid = await crypto.subtle.verify(
      "HMAC",
      key,
      bytes,
      new TextEncoder().encode(`${timestamp}.${raw}`),
    );
    if (!valid) return new Response("Invalid signature", { status: 401 });
    const event = JSON.parse(raw);
    if (
      !/^[0-9a-f-]{36}$/i.test(event.reference) ||
      typeof event.provider_reference !== "string" ||
      typeof event.age_over_18 !== "boolean" ||
      typeof event.identity_verified !== "boolean"
    ) {
      return new Response("Invalid event", { status: 400 });
    }
    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { error } = await db.rpc("df_complete_verification", {
      session_id: event.reference,
      provider_id: event.provider_reference,
      over_18: event.age_over_18,
      identity_checked: event.identity_verified,
    });
    if (error) {
      return new Response("Could not record verification", { status: 503 });
    }
    // Replayed completed events are harmless and return the same success status.
    return new Response("ok");
  } catch {
    return new Response("Invalid callback", { status: 400 });
  }
});
