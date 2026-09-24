import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------------------
      // TOP APP BAR
      // ------------------------------------------------------------
      //
      // Gives the user a title and a back button.
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ------------------------------------------------------------
      // SCROLLABLE TERMS CONTENT
      // ------------------------------------------------------------
      //
      // Terms can be long, so we allow the whole page to scroll.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          22,
          20,
          22,
          40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'De-Fame Terms of Service',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Last updated: September 2026',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),

            const SizedBox(height: 24),

            _section(
              context,
              '1. Eligibility',
              'You must be at least 18 years old to create or use a '
                  'De-Fame account. By using the service, you confirm '
                  'that you meet this requirement.',
            ),

            _section(
              context,
              '2. Your Account',
              'You are responsible for maintaining the security of your '
                  'account and for activity that occurs through your account. '
                  'You must provide accurate information during registration.',
            ),

            _section(
              context,
              '3. User Content',
              'You are responsible for the stories, comments, photographs, '
                  'and other material you submit. You should only post '
                  'content that you reasonably believe is truthful and that '
                  'you have the right to share.',
            ),

            _section(
              context,
              '4. Anonymous Posting',
              'De-Fame may allow you to hide your public identity when '
                  'posting. Anonymous posts remain associated with your '
                  'account internally for moderation, security, abuse '
                  'prevention, and legal compliance.',
            ),

            _section(
              context,
              '5. Prohibited Conduct',
              'You may not use De-Fame to threaten others, organize '
                  'harassment, publish private personal information, exploit '
                  'minors, distribute non-consensual intimate material, '
                  'impersonate others, or otherwise violate applicable law.',
            ),

            _section(
              context,
              '6. Moderation',
              'De-Fame may use automated systems and human review to '
                  'evaluate content. Content may be restricted, removed, '
                  'held for review, or otherwise moderated when necessary.',
            ),

            _section(
              context,
              '7. Reports and Disputes',
              'Users and people discussed in posts may report content, '
                  'request review, submit responses, or request correction '
                  'when they believe content violates De-Fame policies.',
            ),

            _section(
              context,
              '8. Intellectual Property',
              'You should only upload photographs, screenshots, or other '
                  'material that you have permission or a lawful basis to '
                  'submit. De-Fame may remove content in response to valid '
                  'copyright or privacy complaints.',
            ),

            _section(
              context,
              '9. Account Suspension or Termination',
              'De-Fame may restrict or terminate accounts that repeatedly '
                  'violate these Terms, the Community Guidelines, or '
                  'applicable law.',
            ),

            _section(
              context,
              '10. Changes to These Terms',
              'These Terms may be updated from time to time. Material '
                  'changes may be communicated through the app or other '
                  'appropriate means.',
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.50),
              ),
              child: Text(
                'This is currently a development draft for the De-Fame '
                    'prototype and should be reviewed by qualified legal counsel '
                    'before a public launch.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // REUSABLE TERMS SECTION
  // --------------------------------------------------------------
  Widget _section(
      BuildContext context,
      String title,
      String body,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}