import 'package:flutter/material.dart';

import 'package:defame/theme/app_theme.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Community',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Community search coming later.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.search,
            ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32,
        ),
        children: [
          // --------------------------------------------------------
          // SEARCH BAR
          // --------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(
                alpha: 0.55,
              ),
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: TextField(
              readOnly: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Community search coming later.',
                    ),
                  ),
                );
              },
              decoration: const InputDecoration(
                hintText: 'Search communities',
                prefixIcon: Icon(
                  Icons.search,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 26,
          ),

          // --------------------------------------------------------
          // YOUR COMMUNITIES HEADER
          // --------------------------------------------------------
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Communities',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'All joined communities coming later.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'See All',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // --------------------------------------------------------
          // YOUR COMMUNITIES HORIZONTAL LIST
          // --------------------------------------------------------
          SizedBox(
            height: 190,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _JoinedCommunityCard(
                  title: 'Late Night Talk',
                  category: 'General',
                  members: '34 members',
                  unreadCount: 7,
                  icon: Icons.nightlight_round,
                ),

                SizedBox(
                  width: 12,
                ),

                _JoinedCommunityCard(
                  title: 'Dating Stories',
                  category: 'Dating',
                  members: '49 members',
                  unreadCount: 12,
                  icon: Icons.favorite_outline,
                ),

                SizedBox(
                  width: 12,
                ),

                _JoinedCommunityCard(
                  title: 'Workplace Tea',
                  category: 'Work',
                  members: '28 members',
                  unreadCount: 0,
                  icon: Icons.work_outline,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          // --------------------------------------------------------
          // DISCOVER HEADER
          // --------------------------------------------------------
          const Text(
            'Discover Communities',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Find conversations you want to be part of.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(
                alpha: 0.55,
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // --------------------------------------------------------
          // DISCOVER COMMUNITY CARDS
          // --------------------------------------------------------
          const _DiscoverCommunityCard(
            title: 'Relationship Reality',
            description:
            'Talk relationships, boundaries, breakups, dating, and everything in between.',
            category: 'Relationships',
            members: '42 / 50 members',
            icon: Icons.forum_outlined,
          ),

          const SizedBox(
            height: 14,
          ),

          const _DiscoverCommunityCard(
            title: 'No Filter',
            description:
            'Random conversations, hot takes, funny stories, and whatever is happening today.',
            category: 'General',
            members: '37 / 50 members',
            icon: Icons.chat_bubble_outline,
          ),

          const SizedBox(
            height: 14,
          ),

          const _DiscoverCommunityCard(
            title: 'School Survival',
            description:
            'Classes, professors, group projects, campus stories, and surviving school.',
            category: 'School',
            members: '24 / 50 members',
            icon: Icons.school_outlined,
          ),

          const SizedBox(
            height: 14,
          ),

          const _DiscoverCommunityCard(
            title: 'Friend Group Drama',
            description:
            'Friendships, fallouts, weird group-chat moments, and everything people never say out loud.',
            category: 'Friendship',
            members: '46 / 50 members',
            icon: Icons.groups_outlined,
          ),

          const SizedBox(
            height: 28,
          ),

          // --------------------------------------------------------
          // CREATE COMMUNITY BUTTON
          // --------------------------------------------------------
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Create Community is coming next.',
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                AppTheme.primaryPurple,
                foregroundColor:
                Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Create Community',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// JOINED COMMUNITY CARD
// ==================================================================
class _JoinedCommunityCard
    extends StatelessWidget {
  final String title;
  final String category;
  final String members;
  final int unreadCount;
  final IconData icon;

  const _JoinedCommunityCard({
    required this.title,
    required this.category,
    required this.members,
    required this.unreadCount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          20,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withValues(
              alpha: 0.24,
            ),
            Theme.of(context)
                .colorScheme
                .surface,
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                AppTheme.primaryPurple,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const Spacer(),

              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),

          const Spacer(),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryPurple,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            members,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// DISCOVER COMMUNITY CARD
// ==================================================================
class _DiscoverCommunityCard
    extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final String members;
  final IconData icon;

  const _DiscoverCommunityCard({
    required this.title,
    required this.description,
    required this.category,
    required this.members,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(
            alpha: 0.4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor:
            AppTheme.primaryPurple.withValues(
              alpha: 0.15,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryPurple,
              size: 26,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment:
                  WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                        AppTheme.primaryPurple
                            .withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w800,
                          color:
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),

                    Text(
                      members,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
              ),
            ),
            child: const Text(
              'Join',
            ),
          ),
        ],
      ),
    );
  }
}