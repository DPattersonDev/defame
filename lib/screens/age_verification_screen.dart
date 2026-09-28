import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/screens/main_feed_screen.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  State<AgeVerificationScreen> createState() =>
      _AgeVerificationScreenState();
}

class _AgeVerificationScreenState
    extends State<AgeVerificationScreen> {
  // --------------------------------------------------------------
  // LOADING STATE
  // --------------------------------------------------------------
  bool _isVerifying = false;

  // --------------------------------------------------------------
  // ERROR MESSAGE
  // --------------------------------------------------------------
  String? _errorMessage;

  // --------------------------------------------------------------
  // START AGE VERIFICATION
  // --------------------------------------------------------------
  //
  // DEVELOPMENT VERSION:
  // We currently simulate a successful age-verification result.
  //
  // Later, this same method will be connected to the real
  // third-party verification provider.
  Future<void> _startAgeVerification() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // ----------------------------------------------------------
      // SIMULATED PROVIDER DELAY
      // ----------------------------------------------------------
      await Future.delayed(
        const Duration(seconds: 1),
      );

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // DEVELOPMENT RESULT
      // ----------------------------------------------------------
      //
      // TEMPORARY:
      // Pretend the third-party provider says the user passed.
      final bool verificationPassed = true;

      if (!verificationPassed) {
        setState(() {
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Age verification was unsuccessful. '
                  'You must be 18 or older to access De-Fame.',
            ),
          ),
        );

        return;
      }

      // ----------------------------------------------------------
      // GET CURRENT SUPABASE USER
      // ----------------------------------------------------------
      final User? user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception(
          'No signed-in user was found.',
        );
      }

      // ----------------------------------------------------------
      // GET USERNAME FROM AUTH METADATA
      // ----------------------------------------------------------
      //
      // We stored the username in Supabase auth metadata during
      // signup.
      final String? username =
      user.userMetadata?['username'] as String?;

      // ----------------------------------------------------------
      // SAVE PROFILE
      // ----------------------------------------------------------
      //
      // upsert means:
      //
      // If the profile does NOT exist:
      //     create it.
      //
      // If the profile DOES exist:
      //     update it.
      //
      // This is useful because some users may reach this screen
      // before a profile row has been created.
      await Supabase.instance.client
          .from('profiles')
          .upsert(
        {
          'id': user.id,
          'username': username,
          'age_verified': true,
          'updated_at':
          DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'id',
      );

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // VERIFICATION COMPLETE
      // ----------------------------------------------------------
      setState(() {
        _isVerifying = false;
      });

      // ----------------------------------------------------------
      // OPEN MAIN FEED
      // ----------------------------------------------------------
      //
      // Clear all previous signup/login/verification screens.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const MainFeedScreen(),
        ),
            (route) => false,
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isVerifying = false;
        _errorMessage =
        'Could not save verification status: ${error.message}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isVerifying = false;
        _errorMessage =
        'Something went wrong while verifying your account.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // ----------------------------------------------------
              // VERIFICATION ICON
              // ----------------------------------------------------
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppTheme.primaryPurple,
                    size: 58,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ----------------------------------------------------
              // TITLE
              // ----------------------------------------------------
              Text(
                'Verify Your Age',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 14),

              // ----------------------------------------------------
              // MAIN MESSAGE
              // ----------------------------------------------------
              Text(
                'De-Fame is only available to adults '
                    '18 years and older.',
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

              // ----------------------------------------------------
              // ID EXPLANATION
              // ----------------------------------------------------
              Text(
                'To continue, you will be asked to verify your age '
                    'using a government-issued ID.',
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

              const SizedBox(height: 26),

              // ----------------------------------------------------
              // PRIVACY CARD
              // ----------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: AppTheme.primaryPurple,
                      size: 24,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Your ID will be handled by a third-party '
                            'verification provider. De-Fame will only '
                            'receive the verification result and will not '
                            'store your ID document.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ----------------------------------------------------
              // DEVELOPMENT NOTICE
              // ----------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.build_outlined,
                      color: Colors.orange,
                      size: 22,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Development Mode: age verification is '
                            'currently being simulated.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight:
                          FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ----------------------------------------------------
              // ERROR MESSAGE
              // ----------------------------------------------------
              if (_errorMessage != null) ...[
                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ----------------------------------------------------
              // START VERIFICATION BUTTON
              // ----------------------------------------------------
              SizedBox(
                height: 58,
                child: FilledButton(
                  onPressed:
                  _isVerifying
                      ? null
                      : _startAgeVerification,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    AppTheme.primaryPurple,
                    foregroundColor:
                    Colors.white,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                  ),
                  child:
                  _isVerifying
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Start Age Verification',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ----------------------------------------------------
              // ACCESS NOTICE
              // ----------------------------------------------------
              Text(
                'Full access to De-Fame remains locked until '
                    'age verification is completed.',
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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}