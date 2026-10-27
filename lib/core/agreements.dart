/// Increment when the processing purposes or providers materially change.
const agreementVersion = '2026-10-26.2';
const aiDisclosure =
    'When enabled for this development build, De-Fame uses Google Gemini for automated text and photo safety checks and optional draft rewriting. Google free-tier inputs may be used to improve its products. Use sample content during testing. '
    'Submission sends the story, title, subject label, poll text, broad region and attached photo for review. '
    'Rewrite my draft sends only the draft text and runs only when you request it. '
    'Videos are held for human review. AI does not verify truth or identity, and it can make mistakes. '
    'If automated review is unavailable, submissions wait for human review.';
const termsText = '''De-Fame Terms of Service
Effective October 26, 2026 · Version 2026-10-26.2

1. Adults and account access
You must be at least 18, confirm your email and complete independent age verification. Do not identify or discuss minors as subjects. Keep your credentials secure. Public profiles may use a pseudonym. Anonymous posts remain linked to your account internally.

2. Sharing experiences
Describe your own firsthand experience truthfully, distinguish facts from opinion and uncertainty, and do not invent events or present guesses as facts. Do not post defamatory labels, private contact details, home addresses, sensitive identifiers, threats, harassment, coordinated dogpiling, intimate or exploitative material, or secret audio/video recordings. Use a first name or first name and last initial for an optional subject label. Do not use the platform to locate or confront someone.

3. Media and permission
You retain ownership of your content. You grant De-Fame permission to host, display, format and process it as necessary to operate and moderate the service. Only share media you have authority to use and permission to share. Do not scrape galleries, impersonate someone or publish intimate images. You are responsible for permissions and the accuracy of what you submit.

4. AI and human moderation
AI features remain unavailable until configured. The development provider is Google Gemini (free tier), used for text/photo contextual policy review. Submitted story text, title, optional subject label, poll text, broad region and attached photo can be sent to Google when these checks are enabled. Free-tier submissions may be used to improve Google products; use invented test stories and appropriate test media. OpenAI integration is retained for a later optional paid setup, but is disabled and receives no content while Gemini is selected. A provider switch is disclosed through updated agreements. Optional Rewrite my draft sends the draft text only when you request it. You see the suggestion and choose whether to use it; the app does not silently replace your wording. Review it for accuracy before sharing.
AI is not a fact checker, identity verifier, legal adviser or guarantee of safety. It can misinterpret context or miss harmful content. Automated decisions may block submission with an explanation or hold it for human review. Serious allegations, videos and uncertain cases require human review. If automated checks are unavailable, content remains pending rather than automatically publishing. Human reviewers may also review reports, appeals, subject claims and repeat violations. Authorized moderation actions are recorded.

5. Visibility and retention
Anonymous posts expire from public feeds 72 hours after submission, including time spent in review. Public posts remain until removed, moderated or deleted. Expiration is not immediate erasure from internal records, audit logs or backups. Reporting, legal holds and account deletion are handled under the Privacy Policy. Do not treat anonymous posting as untraceable or a way to avoid responsibility.

6. Reports, corrections, removal and right to respond
Use the content menu to report threats, minors, doxxing, intimate content, harassment, copyright or false information, request correction/removal, or submit a subject response. Priority concerns enter an urgent review queue; no particular response time is guaranteed. Published subject responses require independent identity verification, human confirmation that you are the person discussed, and content review. Verification does not establish whether an allegation is true. You can explain disagreement or an appeal through a report. Abusive reporting is prohibited.
For copyright concerns, identify the original work, the content at issue, your authority, your concern, and a way for the operator to respond through your account. The operator must provide a designated legal contact and any applicable formal notice/counter-notice process before public launch; the in-app report form is not a claim of statutory compliance.

7. Enforcement and service limits
De-Fame may limit, remove or hold content, restrict accounts, investigate repeat violations, and preserve relevant evidence for safety or legal obligations. User posts are user statements, not De-Fame endorsements. The service does not guarantee that every story is accurate, complete or independently verified. Nothing here removes rights you have under applicable law or promises blanket immunity from liability.

8. Changes and your choices
Material agreement updates require a new acceptance. You can edit your public profile, opt out of Nearby, block accounts, export your account data and request account deletion in Settings. Do not use the service if you do not accept these terms and the associated Privacy Policy and Community Guidelines.
''';
const privacyText = '''De-Fame Privacy Policy
Effective October 26, 2026 · Version 2026-10-26.2

Information we process
Supabase provides authentication, database storage, private media storage and server functions. We process account/email information, chosen profile fields, your posts and attachments, comments, reactions, poll votes, memberships, blocks, reports, subject responses, agreement acceptance, verification results and operational/moderation records. We use these to operate accounts, deliver feeds, prevent abuse and handle requests. Signup uses a date of birth on your device to check adulthood; this version does not send that date to De-Fame. Independent verification is still required.

Public and anonymous content
Your chosen username and public profile appear on public posts and comments. Anonymous posts omit your account identifier and profile in responses sent to other users. De-Fame still retains the author relationship internally. Authorized operators and service providers may process necessary information for operation, security, moderation and legal obligations. Anonymous does not mean untraceable. People can copy content they see; deleting a post cannot retract others’ copies.

AI provider processing
For this development build, Google Gemini is the selected provider. When automated review is enabled, Gemini receives submitted title/story text, optional subject label, poll text, optional broad region and attached photo for safety checks and contextual policy review. It does not receive your password, identity documents or an account profile as part of those requests. Optional rewriting sends your draft text when you press Rewrite my draft. Nothing is sent merely because you type; submission and an explicit rewrite request trigger processing. Videos are not sent to an AI provider in this version and are held for human review.
Google’s Gemini API Free Tier can use inputs and outputs to improve its products and can involve human review under its terms. Do not submit sensitive real-user information to this development setup. Read https://ai.google.dev/gemini-api/terms . Free usage has quotas; quota failures hold submissions for human review or make rewriting unavailable. The app never automatically switches to a paid provider. De-Fame stores the review result/explanation, not a chat history.
OpenAI is a retained optional integration for later use and is disabled while Gemini is selected. No request is sent to OpenAI without a separate explicit operator activation of paid AI. Any change to the selected provider requires updated disclosures and acceptance.

Verification
The configured independent provider handles identity documents directly and sends De-Fame the result and reference identifier. Do not attach ID documents to posts or reports. The provider must be identified and its privacy terms shown before you start a verification session. De-Fame stores adulthood/identity result flags and session references, not ID document images. No provider is treated as active until it is configured.

Location and preferences
Nearby is optional. You enter a broad city or region; the app does not request GPS or a private address. Nearby compares matching region labels. Turn it off or clear your region in Settings. Your post’s region can be visible with that post if you chose to add it.

Retention and deletion
Anonymous content becomes inaccessible to other users after 72 hours. That visibility deadline is separate from internal retention. Account deletion requests immediately disable account access and hide associated stories, then enter the operator’s deletion/retention process. Moderation, reports, evidence subject to legal hold and backups can remain as needed for their purposes or applicable obligations. The operator must publish its final retention schedule and legal/privacy contact before public release. This development policy does not promise a deletion deadline the service cannot currently enforce.

Your controls
Use Settings to edit your profile, disable optional Nearby/notifications, manage blocks, export account data and request deletion. Use the content menu to report privacy issues or ask for correction/removal. Exports contain private account information: store them securely. Material changes to the purposes or providers described here require renewed acceptance.
''';
const guidelinesText = '''De-Fame Community Guidelines
Adults 18+ only. No minors as subjects.

• Tell your firsthand story; do not invent facts, post defamatory labels or present speculation as certainty.
• No threats, harassment, dogpiling, attempts to locate/confront someone or requests to contact their family/employer.
• No doxxing, private phone/email/address information, financial details, credentials or government identifiers.
• No intimate imagery, sexual exploitation, secretly recorded audio/video or unauthorized media. Share only rights-cleared, appropriate photos/video.
• Use a first name or first name and last initial as a subject label. Serious allegations and uncertain cases require human review.
• AI suggestions are optional and can be wrong. Review every rewrite and preserve the truth of your experience.
• Respect verified subject responses, corrections and review outcomes. Report concerns rather than escalating conflict.
• Use Like/Dislike for a story or comment, not as a rating of a person. Do not coordinate votes or evade blocks/suspensions.
• Abuse and repeat violations can lead to removal or account restrictions. Reports and moderation actions are recorded.

Use a post or comment’s report action for safety, privacy, false information, copyright, correction/removal or a response request. Priority reports are reviewed first; the app is not an emergency service.
''';
