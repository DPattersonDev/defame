import 'package:flutter/material.dart';

import '../core/agreements.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Community guidelines')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: SelectableText(guidelinesText),
    ),
  );
}
