import {
  poll,
  privateInfo,
  publicAuthor,
  subject,
  usernamePattern,
  visible,
} from "./policy.ts";
function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
Deno.test("anonymous projection never includes author identity", () => {
  assert(
    publicAuthor({ is_anonymous: true }, {
      id: "private-id",
      username: "hidden",
    }) === null,
  );
  assert(
    publicAuthor({ is_anonymous: false }, {
      id: "public-id",
      username: "visible",
    })?.id === "public-id",
  );
});
Deno.test("expiration is enforced at the boundary, removed content stays hidden", () => {
  const now = Date.now();
  assert(
    !visible({
      moderation_status: "approved",
      expires_at: new Date(now).toISOString(),
    }, now),
  );
  assert(!visible({ moderation_status: "approved", deleted_at: "today" }, now));
  assert(!visible({ moderation_status: "pending" }, now));
  assert(
    visible({
      moderation_status: "approved",
      expires_at: new Date(now + 1).toISOString(),
    }, now),
  );
});
Deno.test("subject labels and poll choices reject identifying names and duplicate options", () => {
  assert(subject("David P.") === "David P.");
  let rejected = 0;
  try {
    subject("David Patterson");
  } catch {
    rejected++;
  }
  try {
    poll({ question: "How was it?", options: ["Yes", "yes"] });
  } catch {
    rejected++;
  }
  assert(rejected === 2);
  assert(privateInfo("Call 215-555-1234"));
  assert(privateInfo("Write to private@example.com"));
});

Deno.test("username underscores match literally, never as SQL wildcards", () => {
  assert(usernamePattern("David_P") === "David\\_P");
  assert(usernamePattern("David") === "David");
});
