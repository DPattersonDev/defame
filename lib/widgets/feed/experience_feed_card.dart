import 'package:flutter/material.dart';

import 'package:defame/theme/app_theme.dart';

class ExperienceFeedCard extends StatelessWidget {
  final Map<String, dynamic> experience;

  const ExperienceFeedCard({
    super.key,
    required this.experience,
  });

  // --------------------------------------------------------------
  // FORMAT CREATED TIME
  // --------------------------------------------------------------
  String _formatTimeAgo() {
    final String? createdAtText =
    experience['created_at'] as String?;

    if (createdAtText == null) {
      return '';
    }

    final DateTime? createdAt =
    DateTime.tryParse(createdAtText);

    if (createdAt == null) {
      return '';
    }

    final Duration difference =
    DateTime.now().toUtc().difference(
      createdAt.toUtc(),
    );

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    return '${difference.inDays}d ago';
  }

  // --------------------------------------------------------------
  // FORMAT EXPIRATION
  // --------------------------------------------------------------
  String? _formatExpiration() {
    final String? expiresAtText =
    experience['expires_at'] as String?;

    if (expiresAtText == null) {
      return null;
    }

    final DateTime? expiresAt =
    DateTime.tryParse(expiresAtText);

    if (expiresAt == null) {
      return null;
    }

    final Duration remaining =
    expiresAt.toUtc().difference(
      DateTime.now().toUtc(),
    );

    if (remaining.isNegative) {
      return 'Expired';
    }

    if (remaining.inHours >= 1) {
      return 'Expires in ${remaining.inHours} hours';
    }

    return 'Expires in ${remaining.inMinutes} minutes';
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnonymous =
        experience['is_anonymous'] == true;

    final String category =
        experience['category']?.toString() ??
            'Other';

    final String title =
        experience['title']?.toString() ?? '';

    final String body =
        experience['body']?.toString() ?? '';

    final String? subject =
    experience['subject_name']?.toString();

    final int likes =
        experience['like_count'] as int? ?? 0;

    final int dislikes =
        experience['dislike_count'] as int? ?? 0;

    final int comments =
        experience['comment_count'] as int? ?? 0;

    final String? expiration =
    _formatExpiration();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
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
          color:
          AppTheme.primaryPurple.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // HEADER
              // ----------------------------------------------------
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                    AppTheme.primaryPurple,
                    child: Icon(
                      isAnonymous
                          ? Icons
                          .visibility_off_outlined
                          : Icons.person_outline,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnonymous
                              ? 'Anonymous Experience'
                              : 'Public Experience',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '$category • ${_formatTimeAgo()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      // Report / save / delete menu later.
                    },
                    icon: const Icon(
                      Icons.more_horiz,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ----------------------------------------------------
              // EXPERIENCE BADGE
              // ----------------------------------------------------
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                  AppTheme.primaryPurple,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: const Text(
                  'EXPERIENCE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // ----------------------------------------------------
              // SUBJECT
              // ----------------------------------------------------
              if (subject != null &&
                  subject.trim().isNotEmpty) ...[
                const SizedBox(height: 18),

                Text(
                  'About: $subject',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.58,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ----------------------------------------------------
              // TITLE
              // ----------------------------------------------------
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 20),

              // ----------------------------------------------------
              // BODY
              // ----------------------------------------------------
              Text(
                body,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // ----------------------------------------------------
              // EXPIRATION
              // ----------------------------------------------------
              if (expiration != null) ...[
                const SizedBox(height: 28),

                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(
                        alpha: 0.5,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      expiration,
                      style: TextStyle(
                        fontSize: 13,
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

              const SizedBox(height: 22),

              const Divider(),

              const SizedBox(height: 10),

              // ----------------------------------------------------
              // INTERACTIONS
              // ----------------------------------------------------
              Row(
                children: [
                  _InteractionButton(
                    icon: Icons
                        .thumb_up_alt_outlined,
                    count: likes,
                  ),

                  const SizedBox(width: 20),

                  _InteractionButton(
                    icon: Icons
                        .thumb_down_alt_outlined,
                    count: dislikes,
                  ),

                  const SizedBox(width: 20),

                  _InteractionButton(
                    icon:
                    Icons.chat_bubble_outline,
                    count: comments,
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.share_outlined,
                    size: 23,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// INTERACTION BUTTON
// =================================================================

class _InteractionButton
    extends StatelessWidget {
  final IconData icon;
  final int count;

  const _InteractionButton({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 23,
        ),

        const SizedBox(width: 6),

        Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}