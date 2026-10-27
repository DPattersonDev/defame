import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/demo.dart';
import 'common.dart';
import 'composer.dart';
import 'post.dart';
import 'social.dart';
import 'account.dart';

class FeedShell extends StatefulWidget {
  const FeedShell({super.key});
  @override
  State<FeedShell> createState() => _FeedShellState();
}

class _FeedShellState extends State<FeedShell> {
  int tab = 0;
  int revision = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        if (DemoStore.active.value)
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "LOCAL DEMO • Device-only sample data • AI / ID verification inactive",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: tab,
            children: [
              FeedPage(key: ValueKey(revision)),
              const CommunitiesPage(),
              const SizedBox.shrink(),
              ActivityPage(key: ValueKey("activity:$revision")),
              AccountPage(key: ValueKey("profile:$revision")),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (index) async {
        if (index == 2) {
          final result = await open<bool>(context, const ComposerPage());
          if (mounted && result == true) {
            setState(() {
              revision++;
              tab = 0;
            });
          }
        } else {
          setState(() => tab = index);
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          label: 'Groups',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          label: 'Create',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none),
          label: 'Activity',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class FeedPage extends StatefulWidget {
  final String? communityId;
  final String? authorId;
  final bool mine;
  const FeedPage({
    super.key,
    this.communityId,
    this.authorId,
    this.mine = false,
  });
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final search = TextEditingController();
  final scroll = ScrollController();
  List<dynamic> posts = [];
  List<dynamic> people = [];
  String filter = 'Recent';
  String? error;
  bool loading = true;
  bool more = true;
  bool fetching = false;
  int generation = 0;
  int page = 0;
  @override
  void initState() {
    super.initState();
    load();
    scroll.addListener(() {
      if (scroll.position.extentAfter < 400 && more && !fetching && !loading) {
        load(append: true);
      }
    });
  }

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> load({bool append = false}) async {
    if (append && fetching) return;
    final request = append ? generation : ++generation;
    final next = append ? page + 1 : 0;
    setState(() {
      fetching = true;
      error = null;
      if (!append) loading = true;
    });
    try {
      final result = await DeFameApi.call('feed', {
        'filter': filter,
        'query': search.text.trim(),
        'page': next,
        'community_id': widget.communityId,
        'author_id': widget.authorId,
        'mine': widget.mine,
      });
      if (!mounted || generation != request) return;
      setState(() {
        posts = append ? [...posts, ...result['posts']] : result['posts'];
        if (!append) people = result['people'] ?? [];
        more = result['has_more'] == true;
        page = next;
      });
    } catch (e) {
      if (mounted && generation == request) {
        if (append) {
          notify(context, e);
        } else {
          setState(() => error = DeFameApi.message(e));
        }
      }
    } finally {
      if (mounted && generation == request) {
        setState(() {
          loading = false;
          fetching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.mine ? 'My posts' : 'De-Fame'),
      actions: [
        if (widget.communityId != null)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await open(
                context,
                ComposerPage(communityId: widget.communityId),
              );
              if (mounted) load();
            },
          ),
        IconButton(
          onPressed: () => open(context, const ActivityPage()),
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => load(),
            decoration: InputDecoration(
              hintText: 'Search stories, topics, or usernames',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => load(),
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                for (final label in ['Recent', 'Popular', 'Nearby'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: filter == label,
                      onSelected: (_) async {
                        if (label == 'Nearby') {
                          if (!context.mounted) return;
                          final region = await askText(
                            context,
                            'Choose a broad city or region',
                            hint: 'For example: Philadelphia, PA',
                            maxLength: 80,
                          );
                          if (!mounted || region == null || region.isEmpty) {
                            return;
                          }
                          try {
                            await DeFameApi.call('preferences', {
                              'region': region,
                              'nearby_opt_in': true,
                            });
                          } catch (e) {
                            if (context.mounted) notify(context, e);
                            return;
                          }
                          if (!mounted) return;
                        }
                        setState(() => filter = label);
                        load();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: LoadPanel(
            loading: loading,
            error: error,
            retry: () => load(),
            child: RefreshIndicator(
              onRefresh: () => load(),
              child: ListView(
                controller: scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                children: [
                  for (final person in people)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text('@${person['username']}'),
                      subtitle: Text(person['display_name'] ?? ''),
                      onTap: () =>
                          open(context, AccountPage(userId: person['id'])),
                    ),
                  if (posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Text(
                        'No stories here yet. Pull down to refresh.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final post in posts)
                    PostCard(
                      key: ValueKey(post['id']),
                      post: Map<String, dynamic>.from(post),
                      onChanged: () => load(),
                    ),
                  if (fetching)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
