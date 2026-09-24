import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------------------
      // TOP APP BAR
      // ------------------------------------------------------------
      //
      // Gives the user a clear way to return to the De-Fame
      // home screen after reading the legal information.
      appBar: AppBar(
        title: const Text(
          'Terms & Community Guidelines',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ------------------------------------------------------------
      // SCROLLABLE LEGAL CONTENT
      // ------------------------------------------------------------
      //
      // Legal documents can become very long, so we use a
      // SingleChildScrollView to make the entire page scrollable.
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
            // --------------------------------------------------------
            // INTRODUCTION
            // --------------------------------------------------------
            Text(
              'Welcome to De-Fame',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'De-Fame is a community platform for adults to share '
                  'personal experiences, discuss interactions, and participate '
                  'in conversations with other users.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // AGE REQUIREMENT
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '1. Adults Only',
            ),

            Text(
              'You must be at least 18 years old to create or use a '
                  'De-Fame account. Posts identifying or discussing minors '
                  'are not permitted.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // USER RESPONSIBILITY
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '2. You Are Responsible for What You Post',
            ),

            Text(
              'You are responsible for the stories, comments, photographs, '
                  'and other content you submit to De-Fame. You should only '
                  'share information that you reasonably believe is truthful '
                  'and that you have the right to share.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 12),

            Text(
              'De-Fame does not endorse every statement posted by users '
                  'and does not independently verify every personal experience.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // FIRSTHAND EXPERIENCES
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '3. Share Experiences, Not Attacks',
            ),

            Text(
              'De-Fame is designed for users to describe their own '
                  'experiences. Posts should explain what happened rather '
                  'than use the platform to organize harassment, threats, '
                  'dogpiling, or targeted abuse.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // ANONYMOUS POSTS
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '4. Anonymous Posting',
            ),

            Text(
              'You may choose to hide your public profile when posting. '
                  'Anonymous posts are hidden from other users, but they are '
                  'still associated with your De-Fame account internally for '
                  'security, moderation, abuse prevention, and legal compliance.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // PERSONAL INFORMATION
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '5. No Doxxing or Sensitive Personal Information',
            ),

            Text(
              'Do not publish another person\'s private home address, '
                  'personal phone number, financial information, government '
                  'identification numbers, passwords, private account '
                  'information, or precise private location.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // INTIMATE CONTENT
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '6. No Intimate or Exploitative Content',
            ),

            Text(
              'De-Fame does not permit non-consensual intimate imagery, '
                  'sexual exploitation material, or sexual content involving '
                  'minors. Prohibited material may be removed immediately and '
                  'reported when required by law.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // THREATS AND HARASSMENT
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '7. No Threats or Coordinated Harassment',
            ),

            Text(
              'Do not threaten violence, encourage others to confront '
                  'someone, publish information for the purpose of harassment, '
                  'or direct users to contact another person\'s family, '
                  'employer, school, or home.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // PHOTOS / COPYRIGHT
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '8. Photos and Copyright',
            ),

            Text(
              'Only upload photographs, screenshots, or other media that '
                  'you are authorized to submit or that you otherwise have '
                  'a lawful basis to use. De-Fame may remove material in '
                  'response to valid copyright or privacy complaints.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // MODERATION
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '9. Moderation',
            ),

            Text(
              'De-Fame may use automated systems and human review to '
                  'identify potentially harmful or prohibited content. '
                  'Content may be allowed, restricted, held for review, '
                  'or removed depending on the circumstances.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // RIGHT TO RESPOND
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '10. Reports, Corrections, and Responses',
            ),

            Text(
              'A person discussed in a post may report the post, request '
                  'review, submit a response, or request correction or removal '
                  'when they believe the content violates De-Fame policies.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // ACCOUNT ACTION
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '11. Account Enforcement',
            ),

            Text(
              'Accounts that repeatedly violate these rules may lose '
                  'posting privileges or be suspended or removed from De-Fame.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------------
            // AGREEMENT
            // --------------------------------------------------------
            _sectionTitle(
              context,
              '12. Agreement',
            ),

            Text(
              'By creating an account or continuing to use De-Fame, '
                  'you agree to follow these Terms of Service and Community '
                  'Guidelines.',
              style: _bodyStyle(context),
            ),

            const SizedBox(height: 32),

            // --------------------------------------------------------
            // DRAFT NOTICE
            // --------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'These policies are currently part of the De-Fame '
                    'development prototype and may be updated before launch.',
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
  // REUSABLE SECTION TITLE
  // --------------------------------------------------------------
  //
  // Instead of repeating the same TextStyle for every legal
  // heading, this method gives all sections a consistent look.
  Widget _sectionTitle(
      BuildContext context,
      String text,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // REUSABLE BODY TEXT STYLE
  // --------------------------------------------------------------
  //
  // This keeps all legal paragraphs consistent and readable.
  TextStyle _bodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: 15,
      height: 1.6,
      color: Theme.of(context)
          .colorScheme
          .onSurface
          .withValues(alpha: 0.78),
    );
  }
}