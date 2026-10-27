import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/agreements.dart';
import '../core/preferences.dart';
import '../screens/legal_screen.dart';
import '../screens/community_guidelines_screen.dart';
import 'common.dart';
import 'feed.dart';
import 'moderation.dart';
import 'post.dart';

class AccountPage extends StatefulWidget {
  final String? userId;
  const AccountPage({super.key, this.userId});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? profile;
  String? error;
  bool loading = true;
  bool get mine => widget.userId == null || widget.userId == DeFameApi.userId;
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
      final result = await DeFameApi.call('profile', {
        'user_id': widget.userId,
      });
      if (mounted) {
        setState(() => profile = Map<String, dynamic>.from(result['profile']));
      }
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit() async {
    final username = await askText(
      context,
      'Username',
      initial: profile?['username'] ?? '',
      maxLength: 24,
    );
    if (!mounted || username == null) return;
    final name = await askText(
      context,
      'Display name',
      initial: profile?['display_name'] ?? '',
      maxLength: 60,
    );
    if (!mounted || name == null) return;
    final bio = await askText(
      context,
      'Bio',
      initial: profile?['bio'] ?? '',
      maxLength: 500,
    );
    if (!mounted || bio == null) return;
    try {
      await DeFameApi.call('edit_profile', {
        'username': username,
        'display_name': name,
        'bio': bio,
      });
      await load();
    } catch (e) {
      if (mounted) notify(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: LoadPanel(
      loading: loading,
      error: error,
      retry: load,
      child: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              profile?['display_name'] ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Text('@${profile?['username'] ?? ''}', textAlign: TextAlign.center),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(profile?['bio'] ?? ''),
            ),
            if (mine) ...[
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Manage my submissions'),
                subtitle: const Text(
                  'Private: includes anonymous posts and review status.',
                ),
                onTap: () => open(context, const FeedPage(mine: true)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit profile'),
                onTap: edit,
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings & privacy'),
                onTap: () => open(context, const SettingsPage()),
              ),
              if (profile?['is_moderator'] == true)
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Moderation queue'),
                  onTap: () => open(context, const ModerationPage()),
                ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  try {
                    await DeFameApi.signOut();
                  } catch (e) {
                    if (context.mounted) notify(context, e);
                  }
                },
              ),
            ],
            const Divider(),
            const Text(
              'Public posts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if ((profile?['posts'] as List? ?? []).isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No public posts yet.'),
              ),
            for (final post in profile?['posts'] ?? [])
              PostCard(post: Map<String, dynamic>.from(post), onChanged: load),
            TextButton(
              onPressed: () =>
                  open(context, FeedPage(authorId: profile?['id'])),
              child: const Text('View all public posts'),
            ),
          ],
        ),
      ),
    ),
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<dynamic> blocks = [];
  Map<String, dynamic> settings = {};
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await DeFameApi.call('settings');
      if (mounted) {
        setState(() {
          settings = result['settings'];
          blocks = result['blocks'];
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = DeFameApi.message(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> preference(Map<String, dynamic> values) async {
    try {
      await DeFameApi.call('preferences', values);
      await load();
    } catch (e) {
      if (mounted) notify(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings & privacy')),
    body: LoadPanel(
      loading: loading,
      error: error,
      retry: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppPreferences.theme,
            builder: (context, value, _) => DropdownButtonFormField<ThemeMode>(
              initialValue: value,
              decoration: const InputDecoration(labelText: 'Appearance'),
              items: [
                for (final mode in ThemeMode.values)
                  DropdownMenuItem(value: mode, child: Text(mode.name)),
              ],
              onChanged: (mode) {
                if (mode != null) AppPreferences.setTheme(mode);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Nearby feed'),
            subtitle: Text(
              'Opt-in broad region: ${settings['region'] ?? 'None selected'}',
            ),
            value: settings['nearby_opt_in'] == true,
            onChanged: (v) => preference({'nearby_opt_in': v}),
          ),
          ListTile(
            title: const Text('Change broad region'),
            onTap: () async {
              final text = await askText(
                context,
                'City or region',
                initial: settings['region'] ?? '',
                maxLength: 80,
              );
              if (text != null && mounted) preference({'region': text});
            },
          ),
          SwitchListTile(
            title: const Text('In-app engagement notifications'),
            value: settings['notifications'] != false,
            onChanged: (v) => preference({'notifications': v}),
          ),
          const Divider(),
          const Text(
            'Blocked accounts',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (blocks.isEmpty)
            const ListTile(title: Text('No blocked accounts.')),
          for (final block in blocks)
            ListTile(
              title: Text(
                'Blocked account • ${block['created_at'].toString().substring(0, 10)}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  try {
                    await DeFameApi.call('unblock', {'block_id': block['id']});
                    await load();
                  } catch (e) {
                    if (context.mounted) notify(context, e);
                  }
                },
                child: const Text('Unblock'),
              ),
            ),
          const Divider(),
          ListTile(
            title: const Text('Terms of service'),
            onTap: () => open(context, const LegalScreen()),
          ),
          ListTile(
            title: const Text('Community guidelines'),
            onTap: () => open(context, const CommunityGuidelinesScreen()),
          ),
          ListTile(
            title: const Text('Privacy & retention'),
            onTap: () => open(context, const PrivacyPage()),
          ),
          ListTile(
            title: const Text('Export my data'),
            subtitle: const Text(
              'Copy account data as JSON to your clipboard.',
            ),
            onTap: () async {
              try {
                final data = await DeFameApi.call('export');
                await Clipboard.setData(
                  ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert(data),
                  ),
                );
                if (context.mounted) {
                  notify(
                    context,
                    'Account data copied. Paste it into a private file.',
                  );
                }
              } catch (e) {
                if (context.mounted) notify(context, e);
              }
            },
          ),
          ListTile(
            title: const Text('Delete my account'),
            subtitle: const Text(
              'Requires confirmation. Your posts will be hidden immediately.',
            ),
            onTap: () async {
              final text = await askText(
                context,
                'Type DELETE to request account deletion',
                maxLength: 6,
              );
              if (text != 'DELETE') return;
              try {
                await DeFameApi.call('delete_account');
                await DeFameApi.signOut();
              } catch (e) {
                if (context.mounted) notify(context, e);
              }
            },
          ),
        ],
      ),
    ),
  );
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy & retention')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: SelectableText(privacyText),
    ),
  );
}
