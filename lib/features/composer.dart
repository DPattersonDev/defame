import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../core/agreements.dart';
import '../core/rules.dart';
import 'common.dart';

class ComposerPage extends StatefulWidget {
  final String? communityId;
  const ComposerPage({super.key, this.communityId});
  @override
  State<ComposerPage> createState() => _ComposerPageState();
}

class _ComposerPageState extends State<ComposerPage> {
  final title = TextEditingController();
  final body = TextEditingController();
  final subject = TextEditingController();
  final region = TextEditingController();
  final poll = TextEditingController();
  final options = TextEditingController();
  final scroll = ScrollController();
  bool aiAvailable = false;
  bool anonymous = true;
  bool consent = false;
  bool busy = false;
  bool hasPoll = false;
  bool hasRegion = false;
  String category = 'Dating';
  String kind = 'experience';
  String? mediaId;
  String? mediaName;
  String? error;
  String requestId = DateTime.now().microsecondsSinceEpoch.toString();
  String get draftKey =>
      'draft:${DeFameApi.userId}:${widget.communityId ?? 'main'}';
  @override
  void initState() {
    super.initState();
    restore();
    loadCapabilities();
  }

  Future<void> loadCapabilities() async {
    try {
      final result = await DeFameApi.call('capabilities');
      if (mounted) setState(() => aiAvailable = result['ai_enabled'] == true);
    } catch (_) {
      /* Features stay disabled when status cannot be checked. */
    }
  }

  Future<void> restore() async {
    final saved = (await SharedPreferences.getInstance()).getString(draftKey);
    if (saved == null || !mounted) return;
    try {
      final data = jsonDecode(saved) as Map;
      setState(() {
        title.text = data['title'] ?? '';
        body.text = data['body'] ?? '';
        subject.text = data['subject'] ?? '';
        category = data['category'] ?? 'Dating';
        anonymous = data['anonymous'] != false;
        kind = data['kind'] ?? 'experience';
      });
    } catch (_) {
      /* Ignore a corrupt device draft. */
    }
  }

  Future<void> save() async {
    await (await SharedPreferences.getInstance()).setString(
      draftKey,
      jsonEncode({
        'title': title.text,
        'body': body.text,
        'subject': subject.text,
        'category': category,
        'anonymous': anonymous,
        'kind': kind,
      }),
    );
    if (mounted) notify(context, 'Draft saved on this device.');
  }

  @override
  void dispose() {
    for (final controller in [title, body, subject, region, poll, options]) {
      controller.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  void showError(Object e) {
    setState(() => error = DeFameApi.message(e));
    if (scroll.hasClients) {
      scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> upload(bool video) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final picker = ImagePicker();
      final file = video
          ? await picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: const Duration(seconds: 30),
            )
          : await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1600,
              maxHeight: 1600,
              imageQuality: 85,
            );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        throw Exception('Choose a file smaller than 8 MB.');
      }
      final result = await DeFameApi.call('upload', {
        'data': base64Encode(bytes),
        'video': video,
        'extension': file.name.split('.').last.toLowerCase(),
      });
      if (mounted) {
        setState(() {
          mediaId = result['id'];
          mediaName = file.name;
        });
      }
    } catch (e) {
      if (mounted) showError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> rewrite() async {
    if (body.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await DeFameApi.call('rewrite', {'body': body.text});
      if (!mounted) return;
      final text = result['body'] as String;
      final use = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Review the suggested rewrite'),
          content: SingleChildScrollView(child: SelectableText(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep original'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Use rewrite'),
            ),
          ],
        ),
      );
      if (mounted && use == true) setState(() => body.text = text);
    } catch (e) {
      if (mounted) showError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> publish() async {
    if (busy) return;
    final issue = DraftRules.validate(title.text, body.text, subject.text);
    if (issue != null) {
      showError(issue);
      return;
    }
    if (!consent) {
      showError('Confirm the sharing guidelines below.');
      return;
    }
    final choices = options.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (hasPoll &&
        (poll.text.trim().isEmpty ||
            choices.length < 2 ||
            choices.length > 6 ||
            choices.toSet().length != choices.length)) {
      showError('Add a poll question and 2–6 different options, one per line.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await DeFameApi.call('publish', {
        'request_id': requestId,
        'title': title.text.trim(),
        'body': body.text.trim(),
        'subject_name': subject.text.trim(),
        'is_anonymous': anonymous,
        'category': category,
        'kind': kind,
        'region': hasRegion ? region.text.trim() : null,
        'community_id': widget.communityId,
        'media_id': mediaId,
        'poll': hasPoll
            ? {'question': poll.text.trim(), 'options': choices}
            : null,
        'attested': consent,
      });
      await (await SharedPreferences.getInstance()).remove(draftKey);
      if (!mounted) return;
      notify(
        context,
        result['status'] == 'approved'
            ? 'Published.'
            : 'Submitted for review. Check My posts for its status.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError('$e Revise manually or use Rewrite my draft.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    int length = 120,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      enabled: !busy,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 8,
      maxLength: length,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Share your story'),
        actions: [
          TextButton(
            onPressed: busy ? null : save,
            child: const Text('Save draft'),
          ),
        ],
      ),
      body: ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'experience', label: Text('Experience')),
              ButtonSegment(value: 'post', label: Text('Post')),
            ],
            selected: {kind},
            onSelectionChanged: busy
                ? null
                : (v) => setState(() => kind = v.first),
          ),
          const SizedBox(height: 20),
          field(title, 'Title'),
          field(
            subject,
            'Subject (optional)',
            length: 40,
            hint: 'First name or first name + last initial',
          ),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final item in DraftRules.categories)
                DropdownMenuItem(value: item, child: Text(item)),
            ],
            onChanged: busy ? null : (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 20),
          field(body, 'What happened?', lines: 6, length: 10000),
          OutlinedButton.icon(
            onPressed: busy || !aiAvailable ? null : rewrite,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              aiAvailable
                  ? 'Rewrite my draft (optional)'
                  : 'AI rewrite — not enabled yet',
            ),
          ),
          const Text(
            'Review every suggestion. Your wording changes only when you choose Use rewrite.',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Post anonymously'),
            subtitle: const Text(
              'Hidden from other users; linked internally to your account. Expires after 72 hours.',
            ),
            value: anonymous,
            onChanged: busy ? null : (v) => setState(() => anonymous = v),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : () => upload(false),
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Photo'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => upload(true),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Video'),
              ),
            ],
          ),
          if (mediaId != null)
            ListTile(
              title: Text(mediaName ?? 'Media attached'),
              subtitle: const Text('Media stays private until approved.'),
              trailing: IconButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        mediaId = null;
                        mediaName = null;
                      }),
                icon: const Icon(Icons.close),
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add a poll'),
            value: hasPoll,
            onChanged: busy ? null : (v) => setState(() => hasPoll = v),
          ),
          if (hasPoll) ...[
            field(poll, 'Poll question', length: 200),
            field(options, 'Options, one per line', lines: 3, length: 600),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add broad location'),
            subtitle: const Text(
              'City or region only. Never share a private address.',
            ),
            value: hasRegion,
            onChanged: busy ? null : (v) => setState(() => hasRegion = v),
          ),
          if (hasRegion) field(region, 'City or region', length: 80),
          if (!aiAvailable)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'AI is currently off. Your writing stays under your control; submissions await human review when automated checks are unavailable.',
              ),
            ),
          const Text(aiDisclosure),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: busy ? null : (v) => setState(() => consent = v == true),
            title: const Text(
              'This is my firsthand experience. Everyone described is 18+. I have permission '
              'to share any media. No private contact details, intimate material, harassment, or secret recordings.',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : publish,
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )
                : const Text('Share Experience'),
          ),
        ],
      ),
    ),
  );
}
