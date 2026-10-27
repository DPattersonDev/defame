import 'package:flutter/material.dart';

import '../core/api.dart';
import 'common.dart';
import 'feed.dart';
import 'post.dart';

class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key});
  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
  final query = TextEditingController();
  List<dynamic> rows = [];
  bool loading = true;
  bool joinedOnly = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await DeFameApi.call('communities', {
        'query': query.text,
        'joined_only': joinedOnly,
      });
      if (mounted) setState(() => rows = result['communities']);
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> create() async {
    final name = await askText(context, 'Group name', maxLength: 60);
    if (!mounted || name == null || name.isEmpty) return;
    final description = await askText(
      context,
      'What is this group about?',
      maxLength: 500,
    );
    if (!mounted || description == null) return;
    try {
      await DeFameApi.call('create_community', {
        'name': name,
        'description': description,
      });
      if (mounted) {
        notify(context, 'Group submitted for review.');
        load();
      }
    } catch (e) {
      if (mounted) notify(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Groups'),
      actions: [IconButton(onPressed: create, icon: const Icon(Icons.add))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: query,
            onSubmitted: (_) => load(),
            decoration: InputDecoration(
              hintText: 'Search groups',
              suffixIcon: IconButton(
                onPressed: load,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('My groups'),
          value: joinedOnly,
          onChanged: (value) {
            setState(() => joinedOnly = value);
            load();
          },
        ),
        Expanded(
          child: LoadPanel(
            loading: loading,
            error: error,
            retry: load,
            child: RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No groups found.'),
                    ),
                  for (final row in rows)
                    Card(
                      child: InkWell(
                        onTap: () =>
                            open(context, FeedPage(communityId: row['id'])),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${row['name']}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('${row['description']}'),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('${row['members']} members'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await DeFameApi.call('join', {
                                          'community_id': row['id'],
                                          'join': row['joined'] != true,
                                        });
                                        await load();
                                      } catch (e) {
                                        if (context.mounted) notify(context, e);
                                      }
                                    },
                                    child: Text(
                                      row['joined'] == true ? 'Leave' : 'Join',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<dynamic> rows = [];
  bool loading = true;
  String? error;
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
      final result = await DeFameApi.call('activity');
      if (mounted) setState(() => rows = result['activity']);
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Activity'),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await DeFameApi.call('read_activity');
              await load();
            } catch (e) {
              if (context.mounted) notify(context, e);
            }
          },
          child: const Text('Mark all read'),
        ),
      ],
    ),
    body: LoadPanel(
      loading: loading,
      error: error,
      retry: load,
      child: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('You are all caught up.'),
              ),
            for (final row in rows)
              ListTile(
                leading: Icon(
                  row['is_read'] == true
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                ),
                title: Text('${row['title']}'),
                subtitle: Text('${row['body']}'),
                onTap: () async {
                  try {
                    await DeFameApi.call('read_activity', {'id': row['id']});
                    if (row['post_id'] != null) {
                      final result = await DeFameApi.call('post', {
                        'post_id': row['post_id'],
                      });
                      if (!context.mounted) return;
                      await open(
                        context,
                        Scaffold(
                          appBar: AppBar(title: const Text('Experience')),
                          body: ListView(
                            children: [
                              PostCard(
                                post: Map<String, dynamic>.from(result['post']),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (mounted) load();
                  } catch (e) {
                    if (context.mounted) notify(context, e);
                  }
                },
              ),
          ],
        ),
      ),
    ),
  );
}
