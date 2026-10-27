# Backend activation

Target: existing Supabase project `glumsnssgvztaofjxrfp`.

## Activation checkpoint: October 26, 2026

1. `supabase/sql/defame_setup.sql` adds server-only `df_*` tables, private media
   storage, atomic publishing/rate-limit/verification functions and a signup
   trigger that enforces case-insensitive username uniqueness. It copies current
   profiles, stories/posts, comments and reactions without deleting originals.
   Imported content awaits human review; simulated age flags are not trusted.
2. Deploy `defame-api` and `verification-webhook`. The API checks sessions with
   `auth.getUser(token)`; the callback uses timestamped HMAC authentication.
   Public username availability is rate-limited. Client keys cannot read new
   tables, set verification flags or approve content.
3. After testing the new API, `legacy_access_cutover.sql` closes old client-table
   access paths. Older app builds then require updating. Original data stays.
4. Check security/performance advisors and perform a two-account live smoke test.

After explicit user approval, step 1 was applied successfully. All 17 `df_*`
tables have RLS enabled. Both Edge Functions are deployed and ACTIVE: defame-api version 2,
verification-webhook version 1.
The functions implement their own request authentication.

Step 3 is deliberately pending the live smoke test. Original tables still exist
and retain their previous access paths. Do not call the live privacy cutover
complete until the script has been applied and verified.

The security advisor reports two warnings: legacy function
`get_top_experience_comments` has a mutable search path, and leaked-password
protection is disabled. The legacy cutover script addresses the first warning.
The 17 informational RLS-without-policy notices are expected: these new tables
are server-only with client privileges revoked, rather than client-access tables.

## Gemini Free Tier for development

Select `AI_PROVIDER=gemini`, set a server `GEMINI_API_KEY`, and set `AI_ENABLED=true`
only once the key is ready. The configured model is `gemini-3.5-flash-lite`.
Keep the Google project on Free Tier with billing disabled; quotas apply.
The code does not upgrade billing or fall back to paid models. `AI_ALLOW_PAID=false`
independently prevents use of the retained OpenAI adapter, even if an OpenAI key exists.

Google AI Studio previously showed an existing key on the Free Tier project
`gen-lang-client-0182870624`, without billing. The browser session has reset;
no key is retained locally or committed. Supabase dashboard sign-in was verified
on October 27, but browser controls then timed out repeatedly. The user saved the secrets manually. A server-side synthetic test confirmed
Gemini enabled, the selected model and paid AI disabled, but Google returned
HTTP 400 INVALID_ARGUMENT: API key not valid. Replace the GEMINI_API_KEY value
and repeat the AI test before calling this integration functional. The temporary
diagnostic was disabled afterward (404-only handler; gateway JWT required).
Keep the key in Supabase Edge Function secrets, never Dart, GitHub or chat.

Publishing performs contact/threat checks and Gemini text/photo contextual
review. Serious allegations, uncertain content and videos await human review.
Missing keys, quota exhaustion and provider errors also hold content pending.
A policy violation returns an explanation and scrolls the composer to the top.
Optional rewriting sends the draft only when requested and requires Use rewrite
before applying a suggestion. No request runs merely while typing.

The Free Tier may use content to improve Google products, including human
review under its terms. Use sample stories/media for development. Updated Terms,
Privacy Policy and consent version 2026-10-26.2 identify Google and this treatment.
Videos and identity documents are not sent to the AI provider in this build.

Verified references:

- https://ai.google.dev/gemini-api/docs/pricing
- https://ai.google.dev/gemini-api/docs/billing
- https://ai.google.dev/gemini-api/docs/structured-output
- https://ai.google.dev/gemini-api/terms

## Independent verification

An adapter contract is supplied; no specific commercial vendor has been
integrated or purchased. A vendor adapter must validate that vendor's actual
signed callbacks before forwarding normalized results.

Set the server settings listed in `supabase/.env.example`:
`VERIFICATION_PROVIDER_NAME`, `VERIFICATION_PRIVACY_URL` (HTTPS),
`VERIFICATION_START_URL` (HTTPS), `VERIFICATION_API_KEY`, and
`VERIFICATION_WEBHOOK_SECRET`. The app shows the provider/privacy terms before
starting; raw ID documents stay with the provider.

The start adapter receives `{reference,require_age:18,return_url,webhook_url}` and
returns `{reference:<provider reference>,url:<HTTPS session URL>}`. Callback JSON:
`{reference:<De-Fame session UUID>,provider_reference,age_over_18:boolean,identity_verified:boolean}`.
Sign `<unix timestamp>.<exact JSON bytes>` with HMAC-SHA256. Send headers
`x-defame-timestamp` and `x-defame-signature` (hex). The handler rejects signatures
older than five minutes. The database binds the provider reference/session and
makes completed-event retries harmless. Browser redirects never grant approval.

## Auth, moderation and operations

- Enable real email confirmation, delivery and password policy. Allow the auth
  redirect `defame://email-confirmed`; it also handles password recovery.
- Grant moderators through trusted admin SQL using verified account IDs, never
  user-editable metadata. The API disallows reviewing your own content.
- Subject responses need independent identity verification plus a human check
  that the account belongs to the person discussed in the specific post.
- Publish operator/legal/privacy contacts and a final retention schedule. The
  reporting form does not claim a complete statutory DMCA process.
- Account deletion hides/disables the account immediately and logs an operator
  request. Establish actual erasure, legal-hold and backup procedures before
  making public deletion deadlines. Schedule cleanup of unattached media and
  expired rate-limit rows under an approved operations policy.
- Leaked-password protection was disabled on initial inspection; enable it if
  supported by the project plan. No auth settings were changed in this task.

Before calling the connected system ready, test two real verified accounts:
email/recovery links, duplicate/concurrent usernames, agreement acceptance,
public/anonymous/profile behavior, real AI allow/block/pending outcomes, vendor
verification/invalid callbacks, blocks, groups, moderation/audit, media access,
expiry and deletion requests. Local tests do not replace live provider tests.
