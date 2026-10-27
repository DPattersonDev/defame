import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../features/common.dart';

class AgeVerificationScreen extends StatefulWidget {
  final VoidCallback? onVerified;
  const AgeVerificationScreen({super.key, this.onVerified});
  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen>
    with WidgetsBindingObserver {
  bool busy = false;
  String? error;
  String? providerName;
  String? providerPrivacy;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadProvider();
  }

  Future<void> loadProvider() async {
    try {
      final info = await DeFameApi.call('verification_info');
      if (mounted) {
        setState(() {
          providerName = info['name'];
          providerPrivacy = info['privacy_url'];
        });
      }
    } catch (_) {
      /* Start verification reports configuration errors explicitly. */
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy) check();
  }

  Future<void> check() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await DeFameApi.call('bootstrap');
      if (!mounted) return;
      if (result['age_verified'] == true) {
        widget.onVerified?.call();
      } else {
        setState(
          () => error = 'Verification is pending. Complete the provider’s steps, then check again.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> start() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await DeFameApi.call('verification_start');
      final uri = Uri.parse(result['url'] as String);
      if (uri.scheme != 'https' ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open the verification provider.');
      }
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Verify your age'),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await DeFameApi.client.auth.signOut();
            } catch (e) {
              if (context.mounted) notify(context, e);
            }
          },
          child: const Text('Sign out'),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(28),
          children: [
            const Icon(Icons.verified_user_outlined, size: 72),
            const SizedBox(height: 24),
            Text(
              'An adults-only community',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirm your email, then complete independent 18+ verification. '
              'De-Fame receives the result; identity documents stay with the verification provider.',
            ),
            const SizedBox(height: 20),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (providerName != null)
              Text('Verification provider: $providerName'),
            if (providerPrivacy != null)
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(providerPrivacy!),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Provider privacy policy'),
              ),
            FilledButton(
              onPressed: busy ? null : start,
              child: Text(busy ? 'Please wait…' : 'Start verification'),
            ),
            OutlinedButton(
              onPressed: busy ? null : check,
              child: const Text('I finished — check status'),
            ),
          ],
        ),
      ),
    ),
  );
}
