import 'package:flutter/material.dart';

import '../core/api.dart';

void notify(BuildContext context, Object message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(DeFameApi.message(message))));
}

Future<T?> open<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

class LoadPanel extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback retry;
  final Widget child;
  const LoadPanel({
    super.key,
    required this.loading,
    this.error,
    required this.retry,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error == null) return child;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: retry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

Future<String?> askText(
  BuildContext context,
  String title, {
  String initial = '',
  int maxLength = 500,
  String? hint,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: maxLength,
        minLines: 1,
        maxLines: 5,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  // The dialog's exit transition can still reference its controller.
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  return result;
}
