import 'package:flutter/material.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/screens/signup_screen.dart';
import 'package:defame/screens/terms_screen.dart';
import 'package:defame/screens/community_guidelines_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ----------------------------------------------------------
          // BACKGROUND IMAGE
          // ----------------------------------------------------------
          //
          // This fills the entire screen with the De-Fame artwork.
          Positioned.fill(
            child: Image.asset(
              'assets/images/defame_home_mockup.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ----------------------------------------------------------
          // DARK OVERLAY
          // ----------------------------------------------------------
          //
          // Adds a slight dark tint so the buttons and text
          // remain readable over the artwork.
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),

          // ----------------------------------------------------------
          // BOTTOM CONTENT
          // ----------------------------------------------------------
          //
          // This section holds:
          // - 18+ badge
          // - Sign Up button
          // - Sign In button
          // - Terms / Community Guidelines links
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  70,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ------------------------------------------------
                    // 18+ BADGE
                    // ------------------------------------------------
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withValues(
                            alpha: 0.70,
                          ),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Adults 18+ Only',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ------------------------------------------------
                    // SIGN UP BUTTON
                    // ------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const SignUpScreen(),
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ------------------------------------------------
                    // SIGN IN BUTTON
                    // ------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO:
                          // Navigate to the Sign In screen
                          // once we create it.
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                          Colors.black.withValues(alpha: 0.45),
                          side: const BorderSide(
                            color: AppTheme.primaryPurple,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ------------------------------------------------
                    // TERMS + COMMUNITY GUIDELINES
                    // ------------------------------------------------
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'By continuing, you agree to our ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),

                        // --------------------------------------------
                        // TERMS OF SERVICE LINK
                        // --------------------------------------------
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const TermsScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        Text(
                          ' and ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),

                        // --------------------------------------------
                        // COMMUNITY GUIDELINES LINK
                        // --------------------------------------------
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const CommunityGuidelinesScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Community Guidelines',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        Text(
                          '.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}