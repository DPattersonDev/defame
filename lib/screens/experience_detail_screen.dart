import 'package:flutter/material.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/widgets/feed/experience_interaction_bar.dart';
import 'package:defame/widgets/feed/top_comments_preview.dart';

class ExperienceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> experience;

  const ExperienceDetailScreen({
    super.key,
    required this.experience,
  });

  String _formatTimeAgo() {
    final String? createdAtText =
    experience['created_at']?.toString();

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

  String? _formatExpiration() {
    final String? expiresAtText =
    experience['expires_at']?.toString();

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

    if (remaining.inDays >= 1) {
      final int days = remaining.inDays;
      final int hours =
      remaining.inHours.remainder(24);

      if (hours > 0) {
        return '${days}d ${hours}h left';
      }

      return '${days}d left';
    }

    if (remaining.inHours >= 1) {
      final int hours = remaining.inHours;
      final int minutes =
      remaining.inMinutes.remainder(60);

      if (minutes > 0) {
        return '${hours}h ${minutes}m left';
      }

      return '${hours}h left';
    }

    return '${remaining.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final String experienceId =
    experience['id'].toString();

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

    final String? expiration =
    _formatExpiration();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Experience',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Experience options coming later.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.more_horiz,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            40,
          ),
          children: [
            // ------------------------------------------------------
            // EXPERIENCE LABEL
            // ------------------------------------------------------
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 11,
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
                child: const Text(
                  'EXPERIENCE',
                  style: TextStyle(
                    color:
                    AppTheme.primaryPurple,
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ------------------------------------------------------
            // CATEGORY + AUTHOR TYPE
            // ------------------------------------------------------
            Row(
              children: [
                Icon(
                  isAnonymous
                      ? Icons.visibility_off_outlined
                      : Icons.person_outline,
                  size: 18,
                  color:
                  AppTheme.primaryPurple,
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    '$category • '
                        '${isAnonymous ? 'Anonymous' : 'Public'}'
                        ' • ${_formatTimeAgo()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ------------------------------------------------------
            // SUBJECT
            // ------------------------------------------------------
            if (subject != null &&
                subject.trim().isNotEmpty) ...[
              const SizedBox(
                height: 18,
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(
                    alpha: 0.45,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 18,
                      color:
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(
                        alpha: 0.55,
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        'Subject: $subject',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(
              height: 22,
            ),

            // ------------------------------------------------------
            // TITLE
            // ------------------------------------------------------
            Text(
              title,
              style: const TextStyle(
                fontSize: 29,
                height: 1.15,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ------------------------------------------------------
            // FULL STORY
            // ------------------------------------------------------
            Text(
              body,
              style: TextStyle(
                fontSize: 17,
                height: 1.6,
                color:
                Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(
                  alpha: 0.9,
                ),
              ),
            ),

            if (expiration != null) ...[
              const SizedBox(
                height: 28,
              ),

              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 17,
                    color:
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.45,
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Text(
                    expiration,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(
              height: 24,
            ),

            const Divider(),

            const SizedBox(
              height: 8,
            ),

            // ------------------------------------------------------
            // FLAGS / COMMENTS / SHARE
            // ------------------------------------------------------
            ExperienceInteractionBar(
              experienceId:
              experienceId,
            ),

            const SizedBox(
              height: 18,
            ),

            // ------------------------------------------------------
            // TOP COMMENTS
            // ------------------------------------------------------
            TopCommentsPreview(
              experienceId:
              experienceId,
            ),
          ],
        ),
      ),
    );
  }
}