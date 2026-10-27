# De-Fame review checklist — October 27, 2026

This distinguishes confirmed blockers from areas to investigate. Untested items
are not claims that a bug exists. Recheck after each relevant fix.

## Confirmed blockers

| Priority | Finding | Impact / next action |
|---|---|---|
| High | Google rejects the configured Gemini key as invalid (400 INVALID_ARGUMENT). | Replace only GEMINI_API_KEY with the complete valid key; rerun real synthetic requests. Paid AI remains disabled. |
| High | Independent age/identity provider is not configured. | A new real account cannot finish verified onboarding. Choose/configure vendor; never simulate verification success. |
| High | Moderator accounts are not provisioned. | Pending stories, new groups and reports cannot complete live review. Provision trusted verified moderators; self-review is denied. |
| High | Legacy client-table access cutover remains pending. | Old access paths remain. Complete connected checks and apply legacy_access_cutover.sql before claiming privacy cutover complete. |
| High | Android APK build is unverified. | Compilation progressed, then workspace policy blocked dl.google.com. Build on Android Studio or CI with required network access. |
| Medium | Existing post_images media has not been migrated into private storage. | Old images may not display through the new API; review and import deliberately. |
| Medium | GitHub source upload returned 403 Resource not accessible by integration. | Local branch commits and source ZIP are saved; remote branch/PR still needed. |
| Medium | Leaked-password protection is disabled; legacy function has mutable search_path. | Review auth configuration; legacy cutover addresses the function search path. |
| Before launch | Legal/operator contacts, final retention and actual erasure operations are unfinished. | Account deletion currently hides/disables and creates an operator request. |

## Fixed during this pass

- Case-insensitive username uniqueness is enforced atomically by PostgreSQL.
- Escaped underscores in availability/edit checks so they cannot act as wildcards.
- Anonymous posts are excluded from all public profile timelines, including own.
- Separate private submissions retain pending, anonymous and expired entries.
- Group-card layout overlap was fixed and mobile light/dark layouts passed tests.

## Likely areas for bugs: investigate, do not assume failure

| Area | Test | Expected behavior |
|---|---|---|
| Signup | Two accounts claim the same name concurrently; vary case and underscores. | Exactly one succeeds; clear duplicate message; no partial signup. |
| Email and recovery | Open confirmation/reset link from Android email app, background or terminated. | Correct app route; recovery changes password; session restores safely. |
| Consent | Fresh account, old consent version, cancel, relaunch. | Required current agreements appear and persist only after acceptance. |
| Verification | Vendor unavailable, cancellation, invalid signature, callback replay. | Clear state; no unverified approval or duplicate grants. |
| Feed/profile | Public and anonymous posts, other account, expired entries, blocked authors. | Public timelines show public entries only; private manager remains private. |
| Publishing | Slow network, double tap, retry, saved draft, failed media upload. | No duplicate posts; draft retained; attachment claimed once. |
| AI | Valid sample, disallowed content, quota, invalid key, timeout, rewrite cancel/accept. | Clear errors; failures go to human review; rewrite applies only after acceptance; no paid fallback. |
| Groups | Pending group, approved group, join/leave, post from group, return to feed. | Correct membership and group context; pending groups require moderation. |
| Reactions/polls | Switch/clear reactions rapidly; vote from two accounts; reload. | One vote per user; consistent counts; no duplicate submissions. |
| Comments | Replies, removed parent, blocked author, return from details. | Safe visibility and correct refreshed counts. |
| Media | Photo picker permissions, cancel, large/invalid files, video, expired signed URL. | Helpful errors; private access; video waits for human review. |
| Settings | Toggle theme/nearby/notifications, edit profile, relaunch. | Preferences persist and screens refresh correctly. |
| Moderation | Approve/reject others, attempt own review, subject response identity check. | Audited decisions; self-review denied; subject claim needs human confirmation. |
| Deletion/export | Request deletion then try protected actions; inspect export. | Account hidden/disabled; export belongs only to requesting user. |
| Devices | Small phone, keyboard visible, rotation, large font, offline then reconnect. | Usable controls, no overflow/crash, clear retry behavior. |

## Validation completed

- Flutter analysis: no issues.
- Flutter tests: 8 passed, including navigation and light/dark mobile layout.
- Backend tests: 8 passed; both deployed entrypoints passed TypeScript checking.
- Isolated PostgreSQL integration/regression tests: passed.
- Release web build: passed.
- Live API: username validation/availability and missing/forged-token rejection passed.
- Real AI: settings recognized; provider rejected invalid key. No successful generation claimed.
- Android: no completed APK or physical-device test.

## New-user review after blockers are resolved

Use a fresh test account and sample content only. Walk through signup, email,
consent, verification, profile, public story, anonymous story, groups, comments,
reactions, reports, settings and sign-out/sign-in. Record exact steps, expected
result, actual result, device/build and screenshots without secrets. Then repeat
with a second account for privacy, blocking, moderation and concurrency checks.
The local demo is useful for UI review but does not replace live onboarding or
cross-account security tests.
