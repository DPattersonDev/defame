export const categories = [
  "Dating",
  "Relationship",
  "Friendship",
  "Family",
  "Work",
  "School",
  "Social",
  "Other",
];
export const priorityReasons = [
  "threats",
  "minors",
  "doxxing",
  "intimate",
  "copyright",
];
export const reportReasons = [
  ...priorityReasons,
  "harassment",
  "false_information",
  "correction",
  "removal",
  "other",
];
export function text(value: unknown, max: number, min = 0): string {
  if (
    typeof value !== "string" || value.trim().length < min ||
    value.trim().length > max
  ) {
    throw new Error(`Use between ${min} and ${max} characters.`);
  }
  return value.trim();
}
export function id(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      value,
    )
  ) {
    throw new Error("Invalid reference.");
  }
  return value;
}
export function visible(post: Record<string, any>, now = Date.now()): boolean {
  return post.moderation_status === "approved" && !post.deleted_at &&
    (!post.expires_at || new Date(post.expires_at).getTime() > now);
}
export function privateInfo(value: string): boolean {
  return /\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b/.test(value) ||
    /[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/.test(value);
}
export function subject(value: unknown): string | null {
  const label = text(value ?? "", 40);
  if (label && !/^[A-Za-z][A-Za-z-]{0,28}( [A-Za-z]\.)?$/.test(label)) {
    throw new Error("Use a first name or first name and last initial.");
  }
  return label || null;
}
export function poll(value: unknown) {
  if (value == null) return null;
  const p = value as { question: unknown; options: unknown };
  const question = text(p.question, 200, 3);
  if (
    !Array.isArray(p.options) || p.options.length < 2 || p.options.length > 6
  ) throw new Error("Use 2–6 poll options.");
  const options = p.options.map((v) => text(v, 100, 1));
  if (new Set(options.map((v) => v.toLowerCase())).size !== options.length) {
    throw new Error("Poll options must be different.");
  }
  return { question, options };
}
export function publicAuthor(
  post: Record<string, any>,
  account: Record<string, any> | null,
) {
  return post.is_anonymous ? null : account && {
    id: account.id,
    username: account.username,
    display_name: account.display_name,
  };
}

/** Escape SQL pattern characters so usernames match literally under ILIKE. */
export function usernamePattern(value: string): string {
  return value.replace(/[\\%_]/g, "\\$&");
}
