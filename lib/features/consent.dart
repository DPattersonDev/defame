import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/agreements.dart';
import 'common.dart';

class ConsentPage extends StatefulWidget {
  final VoidCallback onAccepted;
  const ConsentPage({super.key, required this.onAccepted});
  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool checked = false;
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your privacy and choices')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(aiDisclosure),
        const SizedBox(height: 20),
        for (final entry in {
          'Terms of service': termsText,
          'Privacy policy': privacyText,
          'Community guidelines': guidelinesText,
        }.entries)
          ExpansionTile(
            title: Text(entry.key),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(entry.value),
              ),
            ],
          ),
        CheckboxListTile(
          value: checked,
          onChanged: busy ? null : (v) => setState(() => checked = v == true),
          title: const Text(
            'I am 18+ and agree to the Terms, Privacy Policy and Community Guidelines, including the AI processing described above.',
          ),
        ),
        FilledButton(
          onPressed: !checked || busy
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    await DeFameApi.call('accept_agreements', {
                      'version': agreementVersion,
                    });
                    widget.onAccepted();
                  } catch (e) {
                    if (context.mounted) notify(context, e);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: const Text('Accept and continue'),
        ),
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
  );
}
