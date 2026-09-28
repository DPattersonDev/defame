import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/screens/email_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // --------------------------------------------------------------
  // FORM KEY
  // --------------------------------------------------------------
  //
  // Lets us validate all form fields when Create Account is pressed.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --------------------------------------------------------------
  // SCROLL CONTROLLER
  // --------------------------------------------------------------
  //
  // Lets us scroll to the top when an important error appears.
  final ScrollController _scrollController = ScrollController();

  // --------------------------------------------------------------
  // TEXT CONTROLLERS
  // --------------------------------------------------------------
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _usernameController =
  TextEditingController();

  final TextEditingController _birthDateController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  // --------------------------------------------------------------
  // DATE OF BIRTH
  // --------------------------------------------------------------
  DateTime? _selectedBirthDate;

  // --------------------------------------------------------------
  // CHECKBOXES
  // --------------------------------------------------------------
  bool _isAdultConfirmed = false;
  bool _termsAccepted = false;

  // --------------------------------------------------------------
  // PASSWORD VISIBILITY
  // --------------------------------------------------------------
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  // --------------------------------------------------------------
  // LOADING STATE
  // --------------------------------------------------------------
  //
  // Prevents users from submitting the signup form multiple times
  // while Supabase is still processing the request.
  bool _isCreatingAccount = false;

  // --------------------------------------------------------------
  // ERROR MESSAGE
  // --------------------------------------------------------------
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // --------------------------------------------------------------
  // CALCULATE AGE
  // --------------------------------------------------------------
  //
  // Calculates the user's exact age based on today's date.
  int _calculateAge(DateTime birthDate) {
    final DateTime today = DateTime.now();

    int age = today.year - birthDate.year;

    final bool birthdayHasNotHappenedYet =
        today.month < birthDate.month ||
            (today.month == birthDate.month &&
                today.day < birthDate.day);

    if (birthdayHasNotHappenedYet) {
      age--;
    }

    return age;
  }

  // --------------------------------------------------------------
  // EMAIL VALIDATION
  // --------------------------------------------------------------
  //
  // This validates whether the email LOOKS properly structured.
  //
  // It does not prove the mailbox exists.
  //
  // Supabase confirmation proves the user can actually receive
  // email at that address.
  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email address.';
    }

    if (email.contains(' ')) {
      return 'Email addresses cannot contain spaces.';
    }

    final RegExp emailPattern = RegExp(
      r'^[A-Za-z0-9.!#$%&''*+/=?^_`{|}~-]+'
      r'@[A-Za-z0-9-]+'
      r'(\.[A-Za-z0-9-]+)+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    final List<String> emailParts = email.split('@');

    if (emailParts.length != 2) {
      return 'Please enter a valid email address.';
    }

    final String domain = emailParts[1];
    final String topLevelDomain = domain.split('.').last;

    if (domain.length < 4) {
      return 'Please enter a valid email domain.';
    }

    if (topLevelDomain.length < 2) {
      return 'Please enter a valid email domain.';
    }

    return null;
  }

  // --------------------------------------------------------------
  // PASSWORD VALIDATION
  // --------------------------------------------------------------
  //
  // De-Fame password requirements:
  //
  // • At least 8 characters
  // • At least 1 uppercase letter
  // • At least 1 lowercase letter
  // • At least 1 number
  // • At least 1 special character
  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Please create a password.';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include at least one uppercase letter.';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include at least one lowercase letter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must include at least one number.';
    }

    if (!RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\];~`]',
    ).hasMatch(password)) {
      return 'Password must include at least one special character.';
    }

    return null;
  }

  // --------------------------------------------------------------
  // SHOW TOP ERROR
  // --------------------------------------------------------------
  //
  // Displays the red warning banner and scrolls the user to the top.
  void _showTopError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --------------------------------------------------------------
  // CREATE ACCOUNT
  // --------------------------------------------------------------
  Future<void> _handleCreateAccount() async {
    // Prevent duplicate signup requests.
    if (_isCreatingAccount) {
      return;
    }

    // Clear previous error.
    setState(() {
      _errorMessage = null;
    });

    // ------------------------------------------------------------
    // VALIDATE FORM FIELDS
    // ------------------------------------------------------------
    final bool formIsValid =
        _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    // ------------------------------------------------------------
    // DOB CHECK
    // ------------------------------------------------------------
    if (_selectedBirthDate == null) {
      _showTopError(
        'Please select your date of birth.',
      );

      return;
    }

    // ------------------------------------------------------------
    // AGE CHECK
    // ------------------------------------------------------------
    final int age = _calculateAge(_selectedBirthDate!);

    if (age < 18) {
      _showTopError(
        'You must be 18 years or older to use De-Fame.',
      );

      return;
    }

    // ------------------------------------------------------------
    // 18+ CHECKBOX
    // ------------------------------------------------------------
    if (!_isAdultConfirmed) {
      _showTopError(
        'Please confirm that you are at least 18 years old.',
      );

      return;
    }

    // ------------------------------------------------------------
    // TERMS CHECKBOX
    // ------------------------------------------------------------
    if (!_termsAccepted) {
      _showTopError(
        'You must agree to the Terms of Service and '
            'Community Guidelines before creating an account.',
      );

      return;
    }

    // ------------------------------------------------------------
    // ACCOUNT VALUES
    // ------------------------------------------------------------
    final String email = _emailController.text.trim();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;

    // ------------------------------------------------------------
    // START LOADING
    // ------------------------------------------------------------
    setState(() {
      _isCreatingAccount = true;
    });

    try {
      // ----------------------------------------------------------
      // CREATE SUPABASE ACCOUNT
      // ----------------------------------------------------------
      //
      // Supabase will:
      //
      // 1. Create the pending user.
      // 2. Send the confirmation email.
      // 3. Store the username in user metadata.
      //
      // After the user confirms the email, Supabase will redirect
      // them to:
      //
      // defame://email-confirmed
      //
      // Android will later recognize that link and reopen De-Fame.
      //
      // We are NOT starting age verification here.
      final AuthResponse response =
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,

        // --------------------------------------------------------
        // EMAIL DEEP-LINK REDIRECT
        // --------------------------------------------------------
        //
        // This replaces the default localhost redirect.
        emailRedirectTo: 'defame://email-confirmed',

        // --------------------------------------------------------
        // USER METADATA
        // --------------------------------------------------------
        data: {
          'username': username,
        },
      );

      // ----------------------------------------------------------
      // MAKE SURE SUPABASE RETURNED A USER
      // ----------------------------------------------------------
      if (response.user == null) {
        _showTopError(
          'We could not create your account. Please try again.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // GO TO CHECK EMAIL SCREEN
      // ----------------------------------------------------------
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: email,
          ),
        ),
      );
    }

    // ------------------------------------------------------------
    // SUPABASE AUTH ERROR
    // ------------------------------------------------------------
    on AuthException catch (error) {
      _showTopError(
        error.message,
      );
    }

    // ------------------------------------------------------------
    // UNKNOWN ERROR
    // ------------------------------------------------------------
    catch (error) {
      _showTopError(
        'Something went wrong while creating your account. '
            'Please try again.',
      );
    }

    // ------------------------------------------------------------
    // STOP LOADING
    // ------------------------------------------------------------
    finally {
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ------------------------------------------------------------
      // FORM
      // ------------------------------------------------------------
      body: Form(
        key: _formKey,

        child: ListView(
          controller: _scrollController,

          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            40,
          ),

          children: [
            // --------------------------------------------------------
            // RED ERROR BANNER
            // --------------------------------------------------------
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(
                    color: Colors.red,
                    width: 1,
                  ),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 22,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],

            // --------------------------------------------------------
            // TITLE
            // --------------------------------------------------------
            Text(
              'Join De-Fame',
              style:
              Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Create your account to share experiences and '
                  'join the conversation.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,

                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
              ),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------------
            // EMAIL
            // --------------------------------------------------------
            TextFormField(
              controller: _emailController,

              keyboardType: TextInputType.emailAddress,

              textInputAction: TextInputAction.next,

              autocorrect: false,

              enableSuggestions: false,

              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),

              validator: _validateEmail,
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------------
            // USERNAME
            // --------------------------------------------------------
            TextFormField(
              controller: _usernameController,

              textInputAction: TextInputAction.next,

              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a username',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),

              validator: (String? value) {
                final String username = value?.trim() ?? '';

                if (username.isEmpty) {
                  return 'Please choose a username.';
                }

                if (username.length < 3) {
                  return 'Username must be at least 3 characters.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------------
            // DATE OF BIRTH
            // --------------------------------------------------------
            TextFormField(
              controller: _birthDateController,

              readOnly: true,

              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Select your birth date',
                prefixIcon: Icon(Icons.cake_outlined),
                suffixIcon: Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(),
              ),

              validator: (String? value) {
                if (_selectedBirthDate == null) {
                  return 'Please select your date of birth.';
                }

                return null;
              },

              onTap: () async {
                final DateTime? selectedDate =
                await showDatePicker(
                  context: context,

                  initialDate: DateTime(2000),

                  firstDate: DateTime(1900),

                  lastDate: DateTime.now(),
                );

                if (selectedDate != null) {
                  setState(() {
                    _selectedBirthDate = selectedDate;

                    _birthDateController.text =
                    '${selectedDate.month}/'
                        '${selectedDate.day}/'
                        '${selectedDate.year}';
                  });
                }
              },
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------------
            // PASSWORD
            // --------------------------------------------------------
            TextFormField(
              controller: _passwordController,

              obscureText: _hidePassword,

              textInputAction: TextInputAction.next,

              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),

                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },

                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),

              validator: _validatePassword,
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------------
            // PASSWORD REQUIREMENTS
            // --------------------------------------------------------
            Padding(
              padding: const EdgeInsets.only(left: 4),

              child: Text(
                'Password must contain:\n'
                    '• At least 8 characters\n'
                    '• At least 1 uppercase letter\n'
                    '• At least 1 lowercase letter\n'
                    '• At least 1 number\n'
                    '• At least 1 special character',

                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,

                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.60),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------------
            // CONFIRM PASSWORD
            // --------------------------------------------------------
            TextFormField(
              controller: _confirmPasswordController,

              obscureText: _hideConfirmPassword,

              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),

                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _hideConfirmPassword =
                      !_hideConfirmPassword;
                    });
                  },

                  icon: Icon(
                    _hideConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),

              validator: (String? value) {
                final String confirmPassword = value ?? '';

                if (confirmPassword.isEmpty) {
                  return 'Please confirm your password.';
                }

                if (confirmPassword !=
                    _passwordController.text) {
                  return 'Passwords do not match.';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------------
            // 18+ CONFIRMATION
            // --------------------------------------------------------
            CheckboxListTile(
              value: _isAdultConfirmed,

              contentPadding: EdgeInsets.zero,

              controlAffinity:
              ListTileControlAffinity.leading,

              activeColor: AppTheme.primaryPurple,

              title: const Text(
                'I confirm that I am at least 18 years old.',
              ),

              onChanged: (bool? value) {
                setState(() {
                  _isAdultConfirmed = value ?? false;
                });
              },
            ),

            // --------------------------------------------------------
            // TERMS AGREEMENT
            // --------------------------------------------------------
            CheckboxListTile(
              value: _termsAccepted,

              contentPadding: EdgeInsets.zero,

              controlAffinity:
              ListTileControlAffinity.leading,

              activeColor: AppTheme.primaryPurple,

              title: const Text(
                'I agree to the Terms of Service and '
                    'Community Guidelines.',
              ),

              onChanged: (bool? value) {
                setState(() {
                  _termsAccepted = value ?? false;
                });
              },
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------------
            // CREATE ACCOUNT BUTTON
            // --------------------------------------------------------
            SizedBox(
              height: 58,

              child: FilledButton(
                onPressed:
                _isCreatingAccount
                    ? null
                    : _handleCreateAccount,

                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                child:
                _isCreatingAccount
                    ? const SizedBox(
                  width: 24,
                  height: 24,

                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}