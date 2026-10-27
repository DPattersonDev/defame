import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/common.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});
  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool busy = false;
  DateTime? lastSent;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Check your email')),
    body: ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Icon(Icons.mark_email_unread_outlined, size: 72),
        const SizedBox(height: 24),
        Text(
          'Confirm ${widget.email}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Text(
          'Use the confirmation link, then return to De-Fame. Email confirmation comes before age verification.',
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () async {
            final ok = await launchUrl(
              Uri.parse('mailto:'),
              mode: LaunchMode.externalApplication,
            );
            if (!ok && context.mounted) {
              notify(
                context,
                'Open your email app and look for the De-Fame confirmation.',
              );
            }
          },
          child: const Text('Open email'),
        ),
        OutlinedButton(
          onPressed: busy
              ? null
              : () async {
                  if (lastSent != null &&
                      DateTime.now().difference(lastSent!).inSeconds < 60) {
                    notify(
                      context,
                      'Wait a minute before requesting another email.',
                    );
                    return;
                  }
                  setState(() => busy = true);
                  try {
                    await Supabase.instance.client.auth.resend(
                      type: OtpType.signup,
                      email: widget.email,
                      emailRedirectTo: 'defame://email-confirmed',
                    );
                    lastSent = DateTime.now();
                    if (context.mounted) {
                      notify(
                        context,
                        'Confirmation email requested. Check spam too.',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) notify(context, e);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: const Text('Resend verification email'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Back to sign in'),
        ),
      ],
    ),
  );
}
