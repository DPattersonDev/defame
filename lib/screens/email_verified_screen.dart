import 'package:flutter/material.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/screens/age_verification_screen.dart';

class EmailVerifiedScreen extends StatelessWidget {
  const EmailVerifiedScreen({super.key});

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
              // SUCCESS ICON
              // ------------------------------------------------------
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.green,
                  size: 58,
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------------
              // TITLE
              // ------------------------------------------------------
              Text(
                'Email Verified',
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
              // SUCCESS MESSAGE
              // ------------------------------------------------------
              Text(
                'Your email address has been successfully confirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.68),
                ),
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------------
              // AGE VERIFICATION MESSAGE
              // ------------------------------------------------------
              Text(
                'One more step. You must verify that you are '
                    '18 or older before you can access De-Fame.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.60),
                ),
              ),

              const Spacer(),

              // ------------------------------------------------------
              // CONTINUE TO AGE VERIFICATION
              // ------------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const AgeVerificationScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue to Age Verification',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------------
              // ACCESS NOTICE
              // ------------------------------------------------------
              Text(
                'De-Fame will not unlock full account access '
                    'until age verification is completed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}