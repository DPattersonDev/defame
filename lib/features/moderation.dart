import 'package:flutter/material.dart';

import '../core/api.dart';
import 'common.dart';

/// Role checks happen again on every server action; hiding this page is not authorization.
class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});
  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  List<dynamic> rows = [];
  String? error;
  bool loading = true;
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
      final data = await DeFameApi.call('moderation_queue');
      if (mounted) setState(() => rows = data['items']);
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> decide(Map row, String decision) async {
    bool claimConfirmed = false;
    if (row['type'] == 'response' && decision == 'approve') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm the subject claim'),
          content: const Text(
            'Approve only after independently verifying that this account belongs to the adult described in the post. Identity verification alone does not prove the relationship.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('I verified the claim'),
            ),
          ],
        ),
      );
      if (!mounted || confirm != true) return;
      claimConfirmed = true;
    }
    final note = await askText(
      context,
      'Review reason (required)',
      maxLength: 1000,
    );
    if (!mounted || note == null || note.trim().length < 10) return;
    try {
      await DeFameApi.call('moderate', {
        'type': row['type'],
        'id': row['id'],
        'decision': decision,
        'note': note,
        'claim_confirmed': claimConfirmed,
      });
      await load();
    } catch (e) {
      if (mounted) notify(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Moderation queue')),
    body: LoadPanel(
      loading: loading,
      error: error,
      retry: load,
      child: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (rows.isEmpty) const Text('Queue is clear.'),
            for (final row in rows)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${row['type']} • ${row['priority'] ?? 'normal'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SelectableText(
                        '${row['title'] ?? ''}\n${row['body'] ?? row['details'] ?? ''}',
                      ),
                      if (row['media_url'] != null)
                        SelectableText('Review media: ${row['media_url']}'),
                      if (row['type'] == 'response')
                        const Text(
                          'Approval requires identity verification and a verified subject claim.',
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final decision
                              in (row['type'] == 'report'
                                  ? ['resolve', 'remove_content']
                                  : row['type'] == 'deletion'
                                  ? ['complete']
                                  : ['approve', 'reject']))
                            TextButton(
                              onPressed: () => decide(row, decision),
                              child: Text(decision.replaceAll('_', ' ')),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
