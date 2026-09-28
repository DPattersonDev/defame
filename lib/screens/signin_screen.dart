import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/screens/signup_screen.dart';
import 'package:defame/screens/main_feed_screen.dart';
import 'package:defame/screens/age_verification_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // --------------------------------------------------------------
  // FORM KEY
  // --------------------------------------------------------------
  //
  // Used to validate the email and password fields before
  // attempting to sign in.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --------------------------------------------------------------
  // TEXT CONTROLLERS
  // --------------------------------------------------------------
  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  // --------------------------------------------------------------
  // UI STATE
  // --------------------------------------------------------------
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  // --------------------------------------------------------------
  // SIGN IN
  // --------------------------------------------------------------
  Future<void> _signIn() async {
    // Clear any previous top-level error.
    setState(() {
      _errorMessage = null;
    });

    // Stop if the form is invalid.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String email =
      _emailController.text.trim();

      final String password =
          _passwordController.text;

      // ----------------------------------------------------------
      // SUPABASE PASSWORD SIGN IN
      // ----------------------------------------------------------
      final AuthResponse response =
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = response.user;

      if (user == null) {
        throw const AuthException(
          'Unable to sign in.',
        );
      }

      // ----------------------------------------------------------
      // TEMPORARY AGE VERIFICATION CHECK
      // ----------------------------------------------------------
      //
      // For right now, we do not yet have the profiles table
      // connected.
      //
      // So after a successful sign in, we send the user to the
      // Age Verification screen.
      //
      // In the next step, we will replace this with:
      //
      // age_verified == true
      //     → MainFeedScreen
      //
      // age_verified == false
      //     → AgeVerificationScreen
      //
      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const AgeVerificationScreen(),
        ),
            (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
        'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --------------------------------------------------------------
  // GO TO SIGN UP
  // --------------------------------------------------------------
  void _openSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const SignUpScreen(),
      ),
    );
  }

  // --------------------------------------------------------------
  // FORGOT PASSWORD
  // --------------------------------------------------------------
  //
  // We will connect Supabase password-reset email later.
  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Forgot Password will be connected next.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 30,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------
                // BACK BUTTON
                // ------------------------------------------------
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // LOGO / ICON
                // ------------------------------------------------
                Center(
                  child: Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_open_outlined,
                      color: AppTheme.primaryPurple,
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Sign in to continue to De-Fame.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.62),
                  ),
                ),

                const SizedBox(height: 32),

                // ------------------------------------------------
                // ERROR MESSAGE
                // ------------------------------------------------
                if (_errorMessage != null) ...[
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

                  const SizedBox(height: 20),
                ],

                // ------------------------------------------------
                // EMAIL FIELD
                // ------------------------------------------------
                TextFormField(
                  controller: _emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  textInputAction:
                  TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.email,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    final String email =
                        value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Enter your email address.';
                    }

                    if (!email.contains('@') ||
                        !email.contains('.') ||
                        email.contains(' ')) {
                      return 'Enter a valid email address.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // PASSWORD FIELD
                // ------------------------------------------------
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction:
                  TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.password,
                  ],
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _signIn();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                          !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons
                            .visibility_off_outlined,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Enter your password.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // ------------------------------------------------
                // FORGOT PASSWORD
                // ------------------------------------------------
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // SIGN IN BUTTON
                // ------------------------------------------------
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed:
                    _isLoading
                        ? null
                        : _signIn,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                      AppTheme.primaryPurple,
                      foregroundColor:
                      Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    child:
                    _isLoading
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
                      'Sign In',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // SIGN UP LINK
                // ------------------------------------------------
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account?',
                    ),

                    TextButton(
                      onPressed: _openSignUp,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // DEVELOPMENT NOTE
                // ------------------------------------------------
                Text(
                  'Age verification status will be remembered '
                      'once we connect the account profile system.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}