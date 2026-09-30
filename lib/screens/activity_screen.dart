import 'package:flutter/material.dart';

import 'package:defame/theme/app_theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Activity',
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
                    'Activity settings coming later.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.tune,
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
          // FILTER CHIPS
          // --------------------------------------------------------
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _ActivityFilterChip(
                  label: 'All',
                  selected: true,
                ),

                SizedBox(
                  width: 8,
                ),

                _ActivityFilterChip(
                  label: 'Reactions',
                  selected: false,
                ),

                SizedBox(
                  width: 8,
                ),

                _ActivityFilterChip(
                  label: 'Comments',
                  selected: false,
                ),

                SizedBox(
                  width: 8,
                ),

                _ActivityFilterChip(
                  label: 'Communities',
                  selected: false,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // --------------------------------------------------------
          // TODAY
          // --------------------------------------------------------
          const Text(
            'Today',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const _ActivityCard(
            icon: Icons.flag,
            iconColor: Colors.green,
            title: 'Your Experience got a green flag',
            description:
            'Someone reacted positively to “This is a test.”',
            time: '2m',
          ),

          const SizedBox(
            height: 10,
          ),

          const _ActivityCard(
            icon: Icons.chat_bubble_outline,
            iconColor: AppTheme.primaryPurple,
            title: 'New comment on your Experience',
            description:
            'Someone commented: “I had the same thing happen.”',
            time: '11m',
          ),

          const SizedBox(
            height: 10,
          ),

          const _ActivityCard(
            icon: Icons.groups_outlined,
            iconColor: AppTheme.primaryPurple,
            title: 'New activity in Dating Stories',
            description:
            '5 new messages were posted in a community you joined.',
            time: '34m',
          ),

          const SizedBox(
            height: 28,
          ),

          // --------------------------------------------------------
          // EARLIER
          // --------------------------------------------------------
          const Text(
            'Earlier',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const _ActivityCard(
            icon: Icons.flag,
            iconColor: Colors.red,
            title: 'Your comment got a red flag',
            description:
            'Someone reacted to a comment you left on an Experience.',
            time: '3h',
          ),

          const SizedBox(
            height: 10,
          ),

          const _ActivityCard(
            icon: Icons.reply,
            iconColor: AppTheme.primaryPurple,
            title: 'Someone replied to you',
            description:
            'A user replied to your comment in Workplace Tea.',
            time: '5h',
          ),

          const SizedBox(
            height: 10,
          ),

          const _ActivityCard(
            icon: Icons.alternate_email,
            iconColor: AppTheme.primaryPurple,
            title: 'You were mentioned',
            description:
            '@DeFameUser mentioned you in a community conversation.',
            time: '1d',
          ),

          const SizedBox(
            height: 28,
          ),

          // --------------------------------------------------------
          // SYSTEM / SAFETY
          // --------------------------------------------------------
          const Text(
            'De-Fame',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _ActivityCard(
            icon: Icons.shield_outlined,
            iconColor: AppTheme.primaryPurple,
            title: 'Welcome to De-Fame',
            description:
            'Your account is ready. Remember: tell your story, not label the person.',
            time: '2d',
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// FILTER CHIP
// ==================================================================
class _ActivityFilterChip
    extends StatelessWidget {
  final String label;
  final bool selected;

  const _ActivityFilterChip({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
      ),
      selected: selected,
      onSelected: (_) {},
    );
  }
}

// ==================================================================
// ACTIVITY CARD
// ==================================================================
class _ActivityCard
    extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String time;
  final bool emphasized;

  const _ActivityCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.time,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized
          ? AppTheme.primaryPurple.withValues(
        alpha: 0.08,
      )
          : Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha: 0.35,
      ),
      borderRadius: BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Activity details coming later.',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            15,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // ICON
              // ----------------------------------------------------
              CircleAvatar(
                radius: 23,
                backgroundColor:
                iconColor.withValues(
                  alpha: 0.13,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              // ----------------------------------------------------
              // ACTIVITY TEXT
              // ----------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}