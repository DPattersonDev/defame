# De-Fame review build

Flutter/Dart app for firsthand stories, based on the existing De-Fame project.

## Run in Android Studio

1. Open the project root containing `pubspec.yaml`, rather than only `android/`.
2. Use Flutter with Dart 3.13.4 or later; run `flutter pub get`.
3. Start your Android emulator and use Run, or run `flutter run` in the terminal.
4. Choose **Try local demo** on the welcome screen for the walkthrough.

The labeled local demo saves sample data on that device and never touches
Supabase. Stories, public/anonymous profiles, groups, comments/replies, reactions,
polls, photos, reporting and activity can be reviewed. It does not pretend to
run OpenAI or independently verify identity. Local publication/moderation is
sample behavior; live submissions require real server checks. Sign out to return
to real accounts. Delete the demo account in Settings to reset local sample data.

## Implemented

- Signup/signin, email resend, password recovery deep links and saved sessions.
- Case-insensitive unique usernames, atomically enforced in PostgreSQL at signup
  and profile editing. Display names can be shared.
- Public and anonymous stories/posts, saved device drafts, reviewed optional AI
  rewriting, publishing checks, optional photos/video/polls/broad location.
- Recent/Popular/Nearby, search, refresh and pagination. Popular uses likes minus
  dislikes. Nearby is opt-in and matches manually entered regions, without GPS.
- Public profile timelines exclude every anonymous post, including on your own
  profile. **Manage my submissions** is private and includes anonymous, expired
  and pending content. Username, display name and bio can be edited.
- Groups: create/search/join/leave and group-scoped stories. Live groups need
  moderation approval before becoming discoverable.
- Comments/replies, separate Like/Dislike controls on stories and comments,
  reporting, blocking/unblocking and persistent activity.
- Human review queue, priority reports, audited decisions, subject responses,
  correction/removal requests, account export and account deletion requests.
- Versioned Terms, Privacy Policy, Community Guidelines and explicit AI consent.

## Live activation status

The server-only database migration is installed in Supabase project
`glumsnssgvztaofjxrfp`. Both `defame-api` and `verification-webhook` are deployed
and active (API version 2; webhook version 1). The API authenticates its own requests; the webhook
requires signed provider callbacks. The legacy table-access cutover has not
been applied; run the live smoke checks before switching older builds off.
See [backend setup](docs/BACKEND_SETUP.md).

**Gemini Free Tier is selected for development. The server recognizes its settings, but Google rejected the saved key as invalid.
Replace GEMINI_API_KEY and repeat the real sample-content AI tests.
Paid OpenAI is separately disabled (`AI_ALLOW_PAID=false`), with no automatic fallback.**

The Google Gemini adapter uses `gemini-3.5-flash-lite` for contextual text/photo
review and optional rewriting. Use a Free Tier project with billing disabled;
account quotas apply and free-tier content can be used to improve Google products.
A server `GEMINI_API_KEY` is required. A successful AI generation has not been verified.
The prior OpenAI integration is retained but disabled.
Independent age verification requires a
selected vendor, adapter and credentials. Never put secrets in Flutter or chat.

This is a review build, not a claim of production readiness. Public launch also
needs provider setup, moderator provisioning, operator/legal contacts, final
retention/deletion procedures, production signing and physical-device checks.
Deletion requests immediately disable/hide the account and log operator review;
they do not claim immediate permanent erasure. Original records are retained;
existing `post_images` media needs a reviewed import into private storage.

## Validation

```sh
flutter analyze
flutter test
flutter test test/visual_smoke_test.dart
flutter build web --release
deno check supabase/functions/defame-api/index.ts supabase/functions/verification-webhook/index.ts
deno test supabase/functions/defame-api/ai_test.ts supabase/functions/defame-api/policy_test.ts
npm ci --prefix supabase/tests
npm test --prefix supabase/tests
```

Database tests use isolated PostgreSQL (PGlite), never the live project.
[Review walkthrough](docs/REVIEW_WALKTHROUGH.md).
[Known blockers and bug-review checklist](docs/BUG_REVIEW.md).
