# De-Fame continuation checkpoint — October 27, 2026

## Completed

- Flutter review implementation: groups, profiles, public/anonymous stories,
  private submissions, unique usernames, comments/replies, votes/polls, reports,
  blocks, activity, settings, drafts, consent and moderation flows.
- Explicit optional AI rewrite preview/accept; server publishing safety checks.
- Agreements version 2026-10-26.2 disclose Gemini Free Tier development processing.
- Server migration applied to glumsnssgvztaofjxrfp after user approval.
- defame-api ACTIVE version 2; verification-webhook ACTIVE version 1.
- Live smoke checks passed: username validation/availability, missing and forged
  session rejection. Unconfigured verification callback fails closed with 503.
- Fixed literal underscore matching in username availability/edit checks; 8 Deno
  tests and isolated PostgreSQL regression tests passed.
- Source committed locally on feat/defame-completion. GitHub upload returned 403
  Resource not accessible by integration. A downloadable source archive was saved.
- Supabase dashboard sign-in verified; then browser controls repeatedly timed
  out opening AI Studio. User subsequently saved the 5 Gemini secrets manually. Server check confirms
  Gemini enabled, expected model and paid disabled; Google rejects the key with
  HTTP 400 INVALID_ARGUMENT / API key not valid. Awaiting replacement key.
- Temporary nonce-protected, expiring synthetic AI diagnostic was deployed to
  confirm settings and provider response. It was then replaced with a 404-only
  handler and JWT protection enabled; no key was returned or stored in source.
- Confirmed all 17 new df_* tables have RLS enabled.
- Earlier validation: Flutter analysis clean, 8 Flutter tests, 7 Deno tests,
  isolated PostgreSQL integration tests, release web build passed. SDKs were restored for current checks: Flutter 3.47.8 / Dart 3.13.7,
  Android SDK 36 / NDK 28.2, Gradle 9.3.1. Current Flutter analysis is clean, all 8 Flutter tests passed, and the
  release web build passed.
  Flutter CI mode avoids its cloud metadata environment probe. Android build
  reached app compilation after restoring JDK 17 and SDKs 35/36.
  The build was terminated by network policy blocking dl.google.com.
  No APK was produced; do not claim Android compilation passed.
  An Android debug APK job is included in GitHub Actions for reproducibility.

## Next steps

1. Replace GEMINI_API_KEY with a valid full Google AI Studio API key. User is
   handling this manually because browser controls repeatedly time out. Never
   enable billing or put the key into source/chat.
2. Other server flags are confirmed correct. Repeat synthetic AI tests after
   key replacement, disable diagnostic afterward, and verify actual app flows.
3. Select an independent age/identity vendor and configure the supplied adapter.
   No verified-age bypass or simulated approval is enabled for live accounts.
4. Provision moderator accounts via trusted admin operation. No moderators were
   granted by this work. Test two accounts and moderation without self-review.
5. Complete live integration checks, then apply legacy_access_cutover.sql.
   Until then, legacy client-table access remains and privacy migration is incomplete.
6. Confirm email/recovery delivery, auth redirects and password protection.
7. Build/run Android on a real SDK/device; review layout and bugs with wife.
8. Before launch: legal/operator contacts, retention/erasure operations, private
   import of old post_images media, production signing and device checks.

## Review now

Open the Flutter project root in Android Studio. Choose Try local demo on the
welcome screen. It is labeled sample data, saves on-device and does not pretend
that AI or independent identity verification are connected. Follow
REVIEW_WALKTHROUGH.md. This is a review build, not a finished production app.

## Preferences/authorization

- No paid AI or billing. Gemini free testing with sample content is authorized.
- User explicitly approved GitHub source upload and Supabase migration.
- Public profile timelines must never show anonymous posts, including own.
- Username uniqueness is case-insensitive; display names may repeat.
- Save progress at a good stopping point. Do not publish or merge to main.
