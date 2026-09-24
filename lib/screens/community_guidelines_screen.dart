import 'package:flutter/material.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Guidelines',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          22,
          20,
          22,
          40,
        ),
        children: [
          Text(
            'De-Fame Community Guidelines',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 24),

          _section(
            context,
            '1. Adults Only',
            'De-Fame is for users age 18 and older. Do not post content '
                'identifying or targeting minors.',
          ),

          _section(
            context,
            '2. Share Your Experience',
            'Describe what happened from your perspective. Avoid presenting '
                'unsupported assumptions or rumors as established facts.',
          ),

          _section(
            context,
            '3. No Doxxing',
            'Do not publish private home addresses, personal phone numbers, '
                'financial information, government identification numbers, '
                'passwords, or other sensitive personal information.',
          ),

          _section(
            context,
            '4. No Threats or Harassment',
            'Do not threaten violence, encourage others to confront someone, '
                'organize dogpiling, or direct users to harass another person.',
          ),

          _section(
            context,
            '5. No Intimate or Exploitative Content',
            'Do not upload non-consensual intimate images, sexual exploitation '
                'material, or sexual content involving minors.',
          ),

          _section(
            context,
            '6. Respect Copyright and Privacy',
            'Only upload photographs, screenshots, and media that you have '
                'permission or a lawful basis to share.',
          ),

          _section(
            context,
            '7. Anonymous Does Not Mean Unaccountable',
            'Anonymous posts remain linked to your account internally for '
                'moderation, security, abuse prevention, and legal compliance.',
          ),

          _section(
            context,
            '8. Reports and Responses',
            'Users and people discussed in posts may report content, request '
                'review, submit a response, or request correction when they '
                'believe content violates these guidelines.',
          ),

          _section(
            context,
            '9. Repeated Violations',
            'Accounts that repeatedly violate these guidelines may lose '
                'posting privileges or be suspended or removed.',
          ),
        ],
      ),
    );
  }

  static Widget _section(
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