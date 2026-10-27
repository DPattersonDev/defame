import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import 'common.dart';
import 'account.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onChanged;
  const PostCard({super.key, required this.post, this.onChanged});
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool busy = false;
  late Map<String, dynamic> post;
  @override
  void initState() {
    super.initState();
    post = {...widget.post};
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    post = {...widget.post};
  }

  Future<void> react(String value) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await DeFameApi.call('react', {
        'post_id': post['id'],
        'value': post['my_reaction'] == value ? null : value,
      });
      if (mounted) setState(() => post.addAll(result));
    } catch (e) {
      if (mounted) notify(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> action(String value) async {
    try {
      if (value == 'report' ||
          value == 'respond' ||
          value == 'correction' ||
          value == 'removal') {
        if (value == 'respond') {
          final text = await askText(
            context,
            'Your response',
            maxLength: 3000,
            hint: 'Your identity must be verified before a response is published.',
          );
          if (text == null || text.isEmpty) return;
          await DeFameApi.call('response', {
            'post_id': post['id'],
            'body': text,
          });
          if (mounted) {
            notify(
              context,
              'Response submitted for identity and content review.',
            );
          }
        } else {
          if (!mounted) return;
          await open(
            context,
            ReportPage(postId: post['id'], initialReason: value),
          );
        }
      } else if (value == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove your post?'),
            content: const Text(
              'The post will disappear from the feed. Moderation records may be retained.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
        await DeFameApi.call('delete_post', {'post_id': post['id']});
        widget.onChanged?.call();
      } else if (value == 'block') {
        await DeFameApi.call('block', {'post_id': post['id']});
        widget.onChanged?.call();
        if (mounted) {
          notify(
            context,
            'Author blocked. Their posts and comments are hidden.',
          );
        }
      }
    } catch (e) {
      if (mounted) notify(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map?;
    final expiration = DateTime.tryParse('${post['expires_at']}');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    author == null
                        ? Icons.visibility_off_outlined
                        : Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: author == null
                        ? null
                        : () =>
                              open(context, AccountPage(userId: author['id'])),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author == null
                              ? 'Anonymous'
                              : '@${author['username']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${post['category']} • ${DateTime.tryParse('${post['created_at']}')?.toLocal().toString().substring(0, 16) ?? ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: action,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('Report content'),
                    ),
                    const PopupMenuItem(
                      value: 'respond',
                      child: Text('I am the subject: respond'),
                    ),
                    const PopupMenuItem(
                      value: 'correction',
                      child: Text('Request correction / false information'),
                    ),
                    const PopupMenuItem(
                      value: 'removal',
                      child: Text('Request removal'),
                    ),
                    if (post['is_mine'] != true)
                      const PopupMenuItem(
                        value: 'block',
                        child: Text('Block author'),
                      ),
                    if (post['is_mine'] == true)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Remove my post'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (post['subject_name'] != null &&
                '${post['subject_name']}'.isNotEmpty)
              Text('About: ${post['subject_name']}'),
            Text(
              '${post['title']}',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SelectableText(
              '${post['body']}',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (post['media_url'] != null) ...[
              const SizedBox(height: 12),
              if (post['media_kind'] == 'image')
                post['media_url'].toString().startsWith('data:')
                    ? Image.memory(
                        base64Decode(
                          post['media_url'].toString().split(',').last,
                        ),
                      )
                    : Image.network(
                        post['media_url'],
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Text(
                          'Image could not load. Pull down to refresh.',
                        ),
                      )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    final success = await launchUrl(
                      Uri.parse(post['media_url']),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!success && context.mounted) {
                      notify(context, 'Could not open this video.');
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Watch video'),
                ),
            ],
            if (post['poll'] != null)
              PollPanel(
                postId: post['id'],
                poll: Map<String, dynamic>.from(post['poll']),
              ),
            if (post['region'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Region: ${post['region']}'),
              ),
            if (expiration != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Expires ${expiration.toLocal().toString().substring(0, 16)}',
                ),
              ),
            if (post['moderation_status'] != 'approved')
              Chip(label: Text('Status: ${post['moderation_status']}')),
            if (post['moderation_note'] != null)
              Text('${post['moderation_note']}'),
            for (final response in post['responses'] ?? [])
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verified subject response',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${response['body']}'),
                  ],
                ),
              ),
            const Divider(height: 28),
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: busy ? null : () => react('like'),
                  icon: Icon(
                    post['my_reaction'] == 'like'
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                  ),
                  label: Text('Like ${post['likes'] ?? 0}'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : () => react('dislike'),
                  icon: Icon(
                    post['my_reaction'] == 'dislike'
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                  ),
                  label: Text('Dislike ${post['dislikes'] ?? 0}'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await open(context, CommentsPage(postId: post['id']));
                    widget.onChanged?.call();
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('${post['comment_count'] ?? 0} comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PollPanel extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> poll;
  const PollPanel({super.key, required this.postId, required this.poll});
  @override
  State<PollPanel> createState() => _PollPanelState();
}

class _PollPanelState extends State<PollPanel> {
  Map<String, dynamic> result = {};
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final data = result.isEmpty ? widget.poll : result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '${data['question']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        for (var i = 0; i < (data['options'] as List).length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        final value = await DeFameApi.call('poll_vote', {
                          'post_id': widget.postId,
                          'option': i,
                        });
                        if (mounted) {
                          setState(
                            () => result = Map<String, dynamic>.from(
                              value['poll'],
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) notify(context, e);
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(
                '${data['my_vote'] == i ? '✓ ' : ''}${data['options'][i]} (${(data['counts'] as List?)?[i] ?? 0})',
              ),
            ),
          ),
      ],
    );
  }
}

class CommentsPage extends StatefulWidget {
  final String postId;
  const CommentsPage({super.key, required this.postId});
  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final input = TextEditingController();
  List<dynamic> rows = [];
  String? parentId;
  String? error;
  bool loading = true;
  bool busy = false;
  int page = 0;
  bool more = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> load({bool append = false}) async {
    final next = append ? page + 1 : 0;
    setState(() {
      loading = !append;
      error = null;
      busy = true;
    });
    try {
      final result = await DeFameApi.call('comments', {
        'post_id': widget.postId,
        'page': next,
      });
      if (mounted) {
        setState(() {
          rows = append ? [...rows, ...result['comments']] : result['comments'];
          page = next;
          more = result['has_more'] == true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          busy = false;
        });
      }
    }
  }

  Future<void> submit() async {
    if (busy || input.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final result = await DeFameApi.call('comment', {
        'post_id': widget.postId,
        'parent_id': parentId,
        'body': input.text.trim(),
      });
      input.clear();
      if (!mounted) return;
      setState(() => parentId = null);
      if (result['status'] != 'approved') {
        notify(context, 'Comment submitted for review.');
      }
      await load();
    } catch (e) {
      if (mounted) notify(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Comments & replies')),
    body: Column(
      children: [
        Expanded(
          child: LoadPanel(
            loading: loading,
            error: error,
            retry: load,
            child: RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (rows.isEmpty) const Text('Start the conversation.'),
                  for (final row in rows)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row['parent_id'] == null
                                  ? '@${row['username']}'
                                  : '↳ @${row['username']} replying',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('${row['body']}'),
                            Wrap(
                              children: [
                                for (final value in ['like', 'dislike'])
                                  TextButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () async {
                                            try {
                                              await DeFameApi.call('react', {
                                                'comment_id': row['id'],
                                                'value':
                                                    row['my_reaction'] == value
                                                    ? null
                                                    : value,
                                              });
                                              await load();
                                            } catch (e) {
                                              if (context.mounted) {
                                                notify(context, e);
                                              }
                                            }
                                          },
                                    icon: Icon(
                                      value == 'like'
                                          ? Icons.thumb_up_outlined
                                          : Icons.thumb_down_outlined,
                                    ),
                                    label: Text('${row['${value}s'] ?? 0}'),
                                  ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => parentId = row['id']),
                                  child: const Text('Reply'),
                                ),
                                TextButton(
                                  onPressed: () => open(
                                    context,
                                    ReportPage(
                                      postId: widget.postId,
                                      commentId: row['id'],
                                    ),
                                  ),
                                  child: const Text('Report'),
                                ),
                                if (row['is_mine'] == true)
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await DeFameApi.call('delete_comment', {
                                          'comment_id': row['id'],
                                        });
                                        await load();
                                      } catch (e) {
                                        if (context.mounted) notify(context, e);
                                      }
                                    },
                                    child: const Text('Remove'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (more)
                    TextButton(
                      onPressed: busy ? null : () => load(append: true),
                      child: const Text('Load more'),
                    ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 16,
            ),
            child: Column(
              children: [
                if (parentId != null)
                  Row(
                    children: [
                      const Expanded(child: Text('Replying to a comment')),
                      IconButton(
                        onPressed: () => setState(() => parentId = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 3000,
                  decoration: InputDecoration(
                    hintText: 'Share a respectful response',
                    suffixIcon: IconButton(
                      onPressed: busy ? null : submit,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class ReportPage extends StatefulWidget {
  final String postId;
  final String? commentId;
  final String initialReason;
  const ReportPage({
    super.key,
    required this.postId,
    this.commentId,
    this.initialReason = 'report',
  });
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final details = TextEditingController();
  late String reason;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    reason = ['correction', 'removal'].contains(widget.initialReason)
        ? widget.initialReason
        : 'harassment';
  }

  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request review')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Threats, minors, doxxing, intimate material and copyright reports receive priority review.',
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: reason,
          items: [
            for (final r in [
              'threats',
              'minors',
              'doxxing',
              'intimate',
              'copyright',
              'harassment',
              'false_information',
              'correction',
              'removal',
              'other',
            ])
              DropdownMenuItem(value: r, child: Text(r.replaceAll('_', ' '))),
          ],
          onChanged: (v) => setState(() => reason = v!),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: details,
          minLines: 4,
          maxLines: 8,
          maxLength: 3000,
          decoration: const InputDecoration(
            labelText: 'Explain your concern',
            hintText: 'For copyright, identify the original work and your authority. Do not upload an ID here.',
          ),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  if (details.text.trim().length < 10) {
                    notify(context, 'Please include at least 10 characters.');
                    return;
                  }
                  setState(() => busy = true);
                  try {
                    await DeFameApi.call('report', {
                      'post_id': widget.postId,
                      'comment_id': widget.commentId,
                      'reason': reason,
                      'details': details.text.trim(),
                    });
                    if (context.mounted) {
                      notify(
                        context,
                        'Report submitted. Track it in Activity.',
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) notify(context, e);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Submitting…' : 'Submit request'),
        ),
      ],
    ),
  );
}
