import 'package:flutter/material.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/widgets/feed/experience_interaction_bar.dart';
import 'package:defame/widgets/feed/top_comments_preview.dart';

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

  // --------------------------------------------------------------
  // FORMAT EXPIRATION
  // --------------------------------------------------------------
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
        return 'Expires in ${days}d ${hours}h';
      }

      return 'Expires in ${days}d';
    }

    if (remaining.inHours >= 1) {
      final int hours =
          remaining.inHours;

      final int minutes =
      remaining.inMinutes.remainder(60);

      if (minutes > 0) {
        return 'Expires in ${hours}h ${minutes}m';
      }

      return 'Expires in ${hours}h';
    }

    return 'Expires in ${remaining.inMinutes}m';
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
        experience['title']?.toString() ??
            '';

    final String body =
        experience['body']?.toString() ??
            '';

    final String? subject =
    experience['subject_name']?.toString();

    final String? expiration =
    _formatExpiration();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(26),
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
            alpha: 0.28,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(26),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            22,
          ),
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
                          : Icons
                          .person_outline,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

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

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          '$category • ${_formatTimeAgo()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ------------------------------------------------
                  // MORE BUTTON
                  // ------------------------------------------------
                  IconButton(
                    onPressed: () {
                      // Report / save / author controls later.
                    },
                    icon: const Icon(
                      Icons.more_horiz,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

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
                  color: AppTheme.primaryPurple,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
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
                const SizedBox(
                  height: 18,
                ),

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

              const SizedBox(
                height: 18,
              ),

              // ----------------------------------------------------
              // TITLE
              // ----------------------------------------------------
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w900,
                  height: 1.2,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ----------------------------------------------------
              // BODY
              // ----------------------------------------------------
              Text(
                body,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.55,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),

              // ----------------------------------------------------
              // EXPIRATION
              // ----------------------------------------------------
              if (expiration != null) ...[
                const SizedBox(
                  height: 28,
                ),

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

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      expiration,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w600,
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

              const SizedBox(
                height: 22,
              ),

              const Divider(),

              const SizedBox(
                height: 6,
              ),

              // ----------------------------------------------------
              // EXPERIENCE FLAGS + COMMENTS + SHARE
              // ----------------------------------------------------
              ExperienceInteractionBar(
                experienceId:
                experienceId,
              ),

              const SizedBox(
                height: 8,
              ),

              // ----------------------------------------------------
              // TOP 2 COMMENTS
              // ----------------------------------------------------
              TopCommentsPreview(
                experienceId:
                experienceId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}