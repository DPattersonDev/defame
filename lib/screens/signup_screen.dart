import 'package:flutter/material.dart';

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
  // Allows us to validate every TextFormField when the user
  // presses Create Account.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --------------------------------------------------------------
  // SCROLL CONTROLLER
  // --------------------------------------------------------------
  //
  // Used to automatically scroll to the red warning banner
  // when an important account-level error occurs.
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
  // CHECKBOX VALUES
  // --------------------------------------------------------------
  bool _isAdultConfirmed = false;
  bool _termsAccepted = false;

  // --------------------------------------------------------------
  // PASSWORD VISIBILITY
  // --------------------------------------------------------------
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  // --------------------------------------------------------------
  // TOP ERROR MESSAGE
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
  // Calculates the user's actual age while accounting for whether
  // their birthday has already happened this year.
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
  // IMPORTANT:
  //
  // This validates whether an email LOOKS structurally legitimate.
  //
  // It cannot determine whether the mailbox really exists.
  //
  // Real ownership will eventually be proven by requiring the user
  // to click an email confirmation link BEFORE De-Fame starts the
  // paid third-party age-verification process.
  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email address.';
    }

    // Prevent spaces.
    if (email.contains(' ')) {
      return 'Email addresses cannot contain spaces.';
    }

    // Basic but stricter email structure.
    final RegExp emailPattern = RegExp(
      r'^[A-Za-z0-9.!#$%&''*+/=?^_`{|}~-]+'
      r'@[A-Za-z0-9-]+'
      r'(\.[A-Za-z0-9-]+)+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    // Split into local name and domain.
    final List<String> emailParts = email.split('@');

    if (emailParts.length != 2) {
      return 'Please enter a valid email address.';
    }

    final String localPart = emailParts[0];
    final String domain = emailParts[1];

    // Example:
    // @gmail.com is okay.
    // @x.c is probably not something we want accepting.
    final String topLevelDomain = domain.split('.').last;

    if (localPart.length < 1) {
      return 'Please enter a valid email address.';
    }

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
  // De-Fame passwords require:
  //
  // • 8+ characters
  // • 1 uppercase letter
  // • 1 lowercase letter
  // • 1 number
  // • 1 special character
  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Please create a password.';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    // At least one uppercase letter.
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include at least one uppercase letter.';
    }

    // At least one lowercase letter.
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include at least one lowercase letter.';
    }

    // At least one number.
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must include at least one number.';
    }

    // At least one special character.
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
  // Displays the red account-level warning banner and scrolls
  // the user back to the top so they cannot miss it.
  void _showTopError(String message) {
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
  void _handleCreateAccount() {
    // Remove an old banner before checking the form again.
    setState(() {
      _errorMessage = null;
    });

    // ------------------------------------------------------------
    // FIELD VALIDATION
    // ------------------------------------------------------------
    //
    // Runs:
    // email validation
    // username validation
    // DOB validation
    // password validation
    // confirm-password validation
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
    // TEMPORARY EMAIL VERIFICATION FLOW
    // ------------------------------------------------------------
    //
    // IMPORTANT:
    //
    // Right now this screen is only SIMULATING an email being sent.
    //
    // Once we connect our authentication backend this section will:
    //
    // 1. Create a pending account.
    //
    // 2. Send a real confirmation email.
    //
    // 3. Keep:
    //
    //      email_verified = false
    //      age_verified = false
    //
    // 4. User clicks their email confirmation link.
    //
    // 5. Backend changes:
    //
    //      email_verified = true
    //
    // 6. ONLY THEN will De-Fame create an age-verification session.
    //
    // This keeps fake/unreachable emails from consuming our
    // third-party age-verification resources.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailVerificationScreen(
          email: _emailController.text.trim(),
        ),
      ),
    );
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
            // RED ACCOUNT WARNING
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
            // CREATE ACCOUNT
            // --------------------------------------------------------
            SizedBox(
              height: 58,

              child: FilledButton(
                onPressed: _handleCreateAccount,

                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                child: const Text(
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