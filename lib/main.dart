import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/api.dart';
import 'core/demo.dart';
import 'core/preferences.dart';
import 'features/common.dart';
import 'features/feed.dart';
import 'features/consent.dart';
import 'screens/home_screen.dart';
import 'screens/age_verification_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.load();
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://glumsnssgvztaofjxrfp.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: 'sb_publishable_jnizKzchP26BH7yJPQ97-g_C7mdUb3H',
    ),
  );
  runApp(const DeFameApp());
}

class DeFameApp extends StatefulWidget {
  const DeFameApp({super.key});
  @override
  State<DeFameApp> createState() => _DeFameAppState();
}

class _DeFameAppState extends State<DeFameApp> {
  final navigator = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? subscription;
  @override
  void initState() {
    super.initState();
    DemoStore.active.addListener(demoChanged);
    subscription = DeFameApi.client.auth.onAuthStateChange.listen(
      (event) {
        if ([
          AuthChangeEvent.signedIn,
          AuthChangeEvent.signedOut,
          AuthChangeEvent.passwordRecovery,
        ].contains(event.event)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            navigator.currentState?.popUntil((route) => route.isFirst);
            if (event.event == AuthChangeEvent.passwordRecovery) {
              navigator.currentState?.push(
                MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
              );
            }
            setState(() {});
          });
        }
      },
      onError: (Object error) {
        debugPrint('Authentication could not refresh.');
      },
    );
  }

  void demoChanged() {
    navigator.currentState?.popUntil((route) => route.isFirst);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DemoStore.active.removeListener(demoChanged);
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: AppPreferences.theme,
    builder: (_, mode, _) => MaterialApp(
      navigatorKey: navigator,
      debugShowCheckedModeBanner: false,
      title: 'De-Fame',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: const AuthGate(),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: DemoStore.active,
    builder: (context, isDemo, _) {
      if (isDemo) return const FeedShell();
      return StreamBuilder<AuthState>(
        stream: DeFameApi.client.auth.onAuthStateChange,
        builder: (context, _) {
          final user = DeFameApi.client.auth.currentUser;
          return user == null
              ? const HomeScreen()
              : AccountGate(key: ValueKey(user.id));
        },
      );
    },
  );
}

class AccountGate extends StatefulWidget {
  const AccountGate({super.key});
  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> {
  bool loading = true;
  String? error;
  bool verified = false;
  bool accepted = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await DeFameApi.call('bootstrap');
      if (mounted) {
        setState(() {
          verified = result['age_verified'] == true;
          accepted = result['agreements_accepted'] == true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => LoadPanel(
    loading: loading,
    error: error,
    retry: load,
    child: !accepted
        ? ConsentPage(onAccepted: load)
        : verified
        ? const FeedShell()
        : AgeVerificationScreen(onVerified: load),
  );
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset password')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  if (password.text.length < 8 ||
                      !RegExp(r'[A-Z]').hasMatch(password.text) ||
                      !RegExp(r'[a-z]').hasMatch(password.text) ||
                      !RegExp(r'[0-9]').hasMatch(password.text) ||
                      !RegExp(r'[^A-Za-z0-9]').hasMatch(password.text)) {
                    notify(
                      context,
                      'Use 8+ characters with uppercase, lowercase, number and special character.',
                    );
                    return;
                  }
                  setState(() => busy = true);
                  try {
                    await DeFameApi.client.auth.updateUser(
                      UserAttributes(password: password.text),
                    );
                    if (context.mounted) {
                      notify(context, 'Password updated.');
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) notify(context, e);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: const Text('Update password'),
        ),
      ],
    ),
  );
}
