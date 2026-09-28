import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/age_verification_screen.dart';
import 'screens/main_feed_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // --------------------------------------------------------------
  // FLUTTER INITIALIZATION
  // --------------------------------------------------------------
  WidgetsFlutterBinding.ensureInitialized();

  // --------------------------------------------------------------
  // SUPABASE INITIALIZATION
  // --------------------------------------------------------------
  await Supabase.initialize(
    url: 'https://glumsnssgvztaofjxrfp.supabase.co',
    publishableKey:
    'sb_publishable_jnizKzchP26BH7yJPQ97-g_C7mdUb3H',
  );

  runApp(const DeFameApp());
}

// =================================================================
// DE-FAME APP
// =================================================================

class DeFameApp extends StatefulWidget {
  const DeFameApp({super.key});

  @override
  State<DeFameApp> createState() => _DeFameAppState();
}

class _DeFameAppState extends State<DeFameApp> {
  // --------------------------------------------------------------
  // NAVIGATOR KEY
  // --------------------------------------------------------------
  //
  // We only use this to return to the root screen when Supabase
  // successfully signs a user in.
  //
  // The AuthGate below decides what that root screen should display.
  final GlobalKey<NavigatorState> _navigatorKey =
  GlobalKey<NavigatorState>();

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------------------
    // AUTH LISTENER
    // ------------------------------------------------------------
    //
    // We now have ONE navigation listener.
    //
    // When:
    //   - the email confirmation link signs the user in
    //   - or the user signs in normally
    //
    // we simply return to the first route.
    //
    // We DO NOT manually open Age Verification here.
    //
    // AuthGate handles that decision.
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
              (AuthState data) {
            debugPrint(
              'Supabase auth event: ${data.event}',
            );

            if (data.event == AuthChangeEvent.signedIn &&
                data.session != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final NavigatorState? navigator =
                    _navigatorKey.currentState;

                if (navigator == null) {
                  return;
                }

                // ----------------------------------------------------
                // RETURN TO ROOT
                // ----------------------------------------------------
                //
                // Example:
                //
                // Home
                //   ↓
                // Sign Up
                //   ↓
                // Check Your Email
                //
                // After email confirmation:
                //
                // We remove those extra routes and return to AuthGate.
                //
                // AuthGate then decides:
                //
                // age_verified false → Age Verification
                // age_verified true  → Main Feed
                navigator.popUntil(
                      (route) => route.isFirst,
                );

                // Rebuild DeFameApp/AuthGate after authentication.
                if (mounted) {
                  setState(() {});
                }
              });
            }

            // --------------------------------------------------------
            // SIGN OUT
            // --------------------------------------------------------
            //
            // When we add the Sign Out button later, this returns the
            // user to the Home screen.
            if (data.event == AuthChangeEvent.signedOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final NavigatorState? navigator =
                    _navigatorKey.currentState;

                if (navigator == null) {
                  return;
                }

                navigator.popUntil(
                      (route) => route.isFirst,
                );

                if (mounted) {
                  setState(() {});
                }
              });
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Supabase auth listener error: $error',
            );
          },
        );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ------------------------------------------------------------
      // GLOBAL NAVIGATION
      // ------------------------------------------------------------
      navigatorKey: _navigatorKey,

      // ------------------------------------------------------------
      // APP SETTINGS
      // ------------------------------------------------------------
      debugShowCheckedModeBanner: false,

      title: 'De-Fame',

      // ------------------------------------------------------------
      // THEMES
      // ------------------------------------------------------------
      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,

      themeMode: ThemeMode.system,

      // ------------------------------------------------------------
      // AUTH GATE
      // ------------------------------------------------------------
      //
      // The app ALWAYS starts here.
      //
      // AuthGate decides what the user should see.
      home: const AuthGate(),
    );
  }
}

// =================================================================
// AUTH GATE
// =================================================================
//
// This is the traffic controller for De-Fame.
//
// NO SESSION
//     → HomeScreen
//
// SESSION EXISTS
//     → Check profiles table
//
// age_verified == false
//     → AgeVerificationScreen
//
// age_verified == true
//     → MainFeedScreen
//

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream:
      Supabase.instance.client.auth.onAuthStateChange,

      builder: (context, snapshot) {
        // --------------------------------------------------------
        // GET CURRENT SESSION
        // --------------------------------------------------------
        //
        // Supabase stores the user's session locally.
        //
        // This lets returning users stay signed in after closing
        // and reopening De-Fame.
        final Session? session =
            Supabase.instance.client.auth.currentSession;

        // --------------------------------------------------------
        // NOT SIGNED IN
        // --------------------------------------------------------
        if (session == null) {
          return const HomeScreen();
        }

        // --------------------------------------------------------
        // SIGNED IN
        // --------------------------------------------------------
        //
        // Now determine whether this account already completed
        // age verification.
        return ProfileGate(
          userId: session.user.id,
        );
      },
    );
  }
}

// =================================================================
// PROFILE GATE
// =================================================================
//
// This checks the signed-in user's record in:
//
// public.profiles
//
// Specifically:
//
// age_verified
//

class ProfileGate extends StatefulWidget {
  final String userId;

  const ProfileGate({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileGate> createState() =>
      _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<bool> _ageVerificationFuture;

  @override
  void initState() {
    super.initState();

    _ageVerificationFuture =
        _checkAgeVerification();
  }

  // --------------------------------------------------------------
  // CHECK AGE VERIFICATION STATUS
  // --------------------------------------------------------------
  Future<bool> _checkAgeVerification() async {
    // ------------------------------------------------------------
    // QUERY PROFILE
    // ------------------------------------------------------------
    //
    // maybeSingle() is important here.
    //
    // A brand-new user may be authenticated but may not have a
    // profile row yet.
    //
    // Instead of throwing an error, maybeSingle() allows us to
    // receive null.
    final Map<String, dynamic>? profile =
    await Supabase.instance.client
        .from('profiles')
        .select('age_verified')
        .eq(
      'id',
      widget.userId,
    )
        .maybeSingle();

    // ------------------------------------------------------------
    // NO PROFILE YET
    // ------------------------------------------------------------
    //
    // Brand-new account:
    //
    // no profile
    //     → not age verified
    if (profile == null) {
      return false;
    }

    // ------------------------------------------------------------
    // RETURN STORED RESULT
    // ------------------------------------------------------------
    return profile['age_verified'] == true;
  }

  // --------------------------------------------------------------
  // RETRY
  // --------------------------------------------------------------
  //
  // Useful if Supabase temporarily fails to load the profile.
  void _retry() {
    setState(() {
      _ageVerificationFuture =
          _checkAgeVerification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _ageVerificationFuture,

      builder: (context, snapshot) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------
        //
        // We do NOT allow the user into the main app when we
        // cannot determine their verification status.
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 55,
                        color: Colors.red,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Unable to check your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'De-Fame could not check your '
                            'verification status. Please try again.',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: _retry,
                        child: const Text(
                          'Try Again',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // --------------------------------------------------------
        // AGE VERIFIED
        // --------------------------------------------------------
        final bool ageVerified =
            snapshot.data ?? false;

        if (ageVerified) {
          return const MainFeedScreen();
        }

        // --------------------------------------------------------
        // NOT AGE VERIFIED
        // --------------------------------------------------------
        //
        // This includes:
        //
        // - profile exists with age_verified = false
        // - profile does not exist yet
        return const AgeVerificationScreen();
      },
    );
  }
}