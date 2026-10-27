export type AiConfig = {
  enabled: boolean;
  provider: "gemini" | "openai";
  key?: string;
  model: string;
  allowPaid: boolean;
};
export function aiReady(config: AiConfig) {
  return config.enabled && !!config.key &&
    (config.provider !== "openai" || config.allowPaid);
}
export function readAiConfig(
  env: (key: string) => string | undefined,
): AiConfig {
  const provider = env("AI_PROVIDER") === "openai" ? "openai" : "gemini";
  return {
    enabled: env("AI_ENABLED") === "true",
    provider,
    allowPaid: env("AI_ALLOW_PAID") === "true",
    key: env(provider === "gemini" ? "GEMINI_API_KEY" : "OPENAI_API_KEY"),
    model: env(provider === "gemini" ? "GEMINI_MODEL" : "OPENAI_MODEL") ||
      (provider === "gemini"
        ? "gemini-3.5-flash-lite"
        : "gpt-4.1-mini-2025-04-14"),
  };
}
function encode(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i += 32768) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 32768));
  }
  return btoa(binary);
}
/** No paid-provider fallback. Credentials are server-only and never in a URL. */
export async function generateJson(
  config: AiConfig,
  system: string,
  content: unknown,
  send: typeof fetch = fetch,
): Promise<Record<string, any>> {
  if (!aiReady(config)) {
    throw new Error(
      "AI is not enabled or configured. Revise manually for now.",
    );
  }
  let result: any;
  if (config.provider === "gemini") {
    const items = typeof content === "string"
      ? [{ type: "text", text: content }]
      : content as Array<any>;
    const parts: any[] = [];
    for (const item of items) {
      if (item.type === "text") parts.push({ text: item.text });
      else if (item.type === "image_url") {
        // Only server-issued private-media URLs reach this internal call.
        const photo = await send(item.image_url.url, {
          signal: AbortSignal.timeout(10000),
        });
        if (!photo.ok) throw new Error("Photo is unavailable for review.");
        const bytes = new Uint8Array(await photo.arrayBuffer());
        if (bytes.length > 8388608) throw new Error("Photo is too large.");
        parts.push({
          inlineData: {
            mimeType: photo.headers.get("Content-Type")?.split(";")[0] ||
              "image/jpeg",
            data: encode(bytes),
          },
        });
      }
    }
    const response = await send(
      `https://generativelanguage.googleapis.com/v1beta/models/${
        encodeURIComponent(config.model)
      }:generateContent`,
      {
        method: "POST",
        headers: {
          "x-goog-api-key": config.key!,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: system }] },
          contents: [{ role: "user", parts }],
          generationConfig: {
            temperature: 0.2,
            maxOutputTokens: 3500,
            responseMimeType: "application/json",
          },
        }),
        signal: AbortSignal.timeout(25000),
      },
    );
    if (!response.ok) {
      throw new Error(
        response.status === 429
          ? "Free AI quota reached. Please try again later."
          : "Gemini is temporarily unavailable.",
      );
    }
    const output = await response.json();
    const value = output.candidates?.[0]?.content?.parts?.filter((p: any) =>
      typeof p.text === "string"
    ).map((p: any) => p.text).join("");
    if (!value) {
      throw new Error("Gemini could not safely complete this request.");
    }
    result = JSON.parse(value);
  } else {
    const response = await send("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config.key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: config.model,
        store: false,
        max_completion_tokens: 3500,
        response_format: { type: "json_object" },
        messages: [{ role: "system", content: system }, {
          role: "user",
          content,
        }],
        temperature: 0.2,
      }),
      signal: AbortSignal.timeout(25000),
    });
    if (!response.ok) throw new Error("OpenAI is temporarily unavailable.");
    const output = await response.json();
    result = JSON.parse(output.choices[0].message.content);
  }
  if (!result || typeof result !== "object" || Array.isArray(result)) {
    throw new Error("Invalid AI response.");
  }
  return result;
}
