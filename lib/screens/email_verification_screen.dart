import 'package:flutter/material.dart';

import 'package:defame/theme/app_theme.dart';

class EmailVerificationScreen extends StatelessWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 32,
          ),

          child: Column(
            children: [
              const Spacer(),

              // ------------------------------------------------------
              // EMAIL ICON
              // ------------------------------------------------------
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppTheme.primaryPurple,
                  size: 58,
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------------
              // MAIN TITLE
              // ------------------------------------------------------
              Text(
                'Check Your Email',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------------
              // EMAIL MESSAGE
              // ------------------------------------------------------
              Text(
                'We sent a verification link to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.68),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryPurple,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Confirm your email address to continue to the '
                    '18+ age verification process.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
              ),

              const Spacer(),

              // ------------------------------------------------------
              // OPEN EMAIL BUTTON
              // ------------------------------------------------------
              //
              // This is a placeholder for now.
              // Later we can either open the user's email app or
              // simply let them leave De-Fame and return after
              // clicking the verification link.
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () {
                    // TODO: Open email application.
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Open Email',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------------
              // RESEND EMAIL
              // ------------------------------------------------------
              TextButton(
                onPressed: () {
                  // TODO: Resend verification email.
                },
                child: const Text(
                  'Resend Verification Email',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'You will not be able to access the full De-Fame '
                    'experience until your email and age are verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}