import 'package:flutter/material.dart';

import 'package:defame/screens/signup_screen.dart';
import 'package:defame/screens/signin_screen.dart';
import 'package:defame/screens/terms_screen.dart';
import 'package:defame/screens/community_guidelines_screen.dart';
import 'package:defame/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --------------------------------------------------------------
  // OPEN SIGN UP
  // --------------------------------------------------------------
  void _openSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      ),
    );
  }

  // --------------------------------------------------------------
  // OPEN SIGN IN
  // --------------------------------------------------------------
  void _openSignIn(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignInScreen(),
      ),
    );
  }

  // --------------------------------------------------------------
  // OPEN TERMS OF SERVICE
  // --------------------------------------------------------------
  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsScreen(),
      ),
    );
  }

  // --------------------------------------------------------------
  // OPEN COMMUNITY GUIDELINES
  // --------------------------------------------------------------
  void _openCommunityGuidelines(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const CommunityGuidelinesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --------------------------------------------------------
          // BACKGROUND IMAGE
          // --------------------------------------------------------
          Image.asset(
            'assets/images/defame_home_mockup.png',
            fit: BoxFit.cover,
          ),

          // --------------------------------------------------------
          // DARK OVERLAY
          // --------------------------------------------------------
          //
          // Keeps buttons and text readable over the artwork.
          Container(
            color: Colors.black.withValues(
              alpha: 0.28,
            ),
          ),

          // --------------------------------------------------------
          // MAIN CONTENT
          // --------------------------------------------------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 24,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  // ------------------------------------------------
                  // 18+ BADGE
                  // ------------------------------------------------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.70,
                      ),
                      borderRadius:
                      BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.primaryPurple,
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

                        SizedBox(width: 8),

                        Text(
                          'Adults 18+ Only',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // SIGN UP BUTTON
                  // ------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () {
                        _openSignUp(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor:
                        AppTheme.primaryPurple,
                        foregroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.w700,
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
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        _openSignIn(context);
                      },
                      style:
                      OutlinedButton.styleFrom(
                        foregroundColor:
                        Colors.white,
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1.5,
                        ),
                        backgroundColor:
                        Colors.black.withValues(
                          alpha: 0.42,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ------------------------------------------------
                  // POLICY LINKS
                  // ------------------------------------------------
                  Wrap(
                    alignment:
                    WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      TextButton(
                        onPressed: () {
                          _openTerms(context);
                        },
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: Colors.white,
                            decoration:
                            TextDecoration
                                .underline,
                            decorationColor:
                            Colors.white,
                          ),
                        ),
                      ),

                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 13,
                        ),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          _openCommunityGuidelines(
                            context,
                          );
                        },
                        child: const Text(
                          'Community Guidelines',
                          style: TextStyle(
                            color: Colors.white,
                            decoration:
                            TextDecoration
                                .underline,
                            decorationColor:
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ------------------------------------------------
                  // FOOTER TEXT
                  // ------------------------------------------------
                  const Text(
                    'By continuing, you agree to follow '
                        'De-Fame\'s rules and verification requirements.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}