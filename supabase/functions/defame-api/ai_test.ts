import { aiReady, generateJson, readAiConfig } from "./ai.ts";
function assert(value: unknown, message = "assertion failed"): void {
  if (!value) throw new Error(message);
}
const free = {
  enabled: true,
  provider: "gemini" as const,
  key: "test-key",
  model: "gemini-3.5-flash-lite",
  allowPaid: false,
};
Deno.test("free provider is selected without activating paid OpenAI", () => {
  const env: Record<string, string> = {
    AI_ENABLED: "true",
    OPENAI_API_KEY: "unused-paid-key",
  };
  const config = readAiConfig((k) => env[k]);
  assert(config.provider === "gemini");
  assert(!aiReady(config));
  assert(!aiReady({ ...free, provider: "openai", allowPaid: false }));
});
Deno.test("disabled or unapproved paid AI never makes a network request", async () => {
  let calls = 0;
  const send: typeof fetch = async () => {
    calls++;
    throw new Error("must not run");
  };
  for (
    const config of [{ ...free, enabled: false }, {
      ...free,
      provider: "openai" as const,
    }]
  ) {
    let blocked = false;
    try {
      await generateJson(config, "Return JSON", "test", send);
    } catch {
      blocked = true;
    }
    assert(blocked);
  }
  assert(calls === 0);
});
Deno.test("Gemini uses a server header, structured JSON, and no paid fallback", async () => {
  let calls = 0;
  const send: typeof fetch = async (url, init) => {
    calls++;
    assert(
      String(url).startsWith("https://generativelanguage.googleapis.com/"),
    );
    assert(!String(url).includes("test-key"));
    assert(new Headers(init?.headers).get("x-goog-api-key") === "test-key");
    const body = JSON.parse(String(init?.body));
    assert(body.generationConfig.responseMimeType === "application/json");
    return new Response(
      JSON.stringify({
        candidates: [{
          content: { parts: [{ text: '{"body":"A clearer sample story."}' }] },
        }],
      }),
    );
  };
  const result = await generateJson(
    free,
    "Return JSON",
    "A sample story.",
    send,
  );
  assert(result.body === "A clearer sample story.");
  assert(calls === 1);
  const quota: typeof fetch = async () => {
    calls++;
    return new Response("", { status: 429 });
  };
  let denied = false;
  try {
    await generateJson(free, "Return JSON", "test", quota);
  } catch (e) {
    denied = e instanceof Error && e.message.includes("quota");
  }
  assert(denied);
  assert(calls === 2, "Quota exhaustion must not call another provider.");
});
Deno.test("photo review sends image bytes, not the private storage URL", async () => {
  const photoUrl = "https://example.invalid/private-photo";
  let calls = 0;
  const send: typeof fetch = async (url, init) => {
    calls++;
    if (String(url) === photoUrl) {
      return new Response(new Uint8Array([255, 216, 255]), {
        headers: { "Content-Type": "image/jpeg" },
      });
    }
    const body = JSON.parse(String(init?.body));
    assert(body.contents[0].parts[1].inlineData.mimeType === "image/jpeg");
    assert(!String(init?.body).includes(photoUrl));
    return new Response(
      JSON.stringify({
        candidates: [{
          content: {
            parts: [{
              text: '{"decision":"review","reason":"Check image rights."}',
            }],
          },
        }],
      }),
    );
  };
  const result = await generateJson(free, "Return JSON", [{
    type: "text",
    text: "Sample photo",
  }, { type: "image_url", image_url: { url: photoUrl } }], send);
  assert(result.decision === "review");
  assert(calls === 2);
});
