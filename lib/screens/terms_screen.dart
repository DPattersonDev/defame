import 'package:flutter/material.dart';

import '../core/agreements.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Terms of service')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: SelectableText(termsText),
    ),
  );
}
