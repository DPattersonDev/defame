import 'package:flutter/material.dart';

import 'package:defame/screens/experience_detail_screen.dart';
import 'package:defame/theme/app_theme.dart';
import 'package:defame/widgets/feed/experience_interaction_bar.dart';

class ExperienceFeedCard extends StatelessWidget {
  final Map<String, dynamic> experience;

  const ExperienceFeedCard({
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
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    return '${difference.inDays}d';
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
      return '${remaining.inDays}d left';
    }

    if (remaining.inHours >= 1) {
      return '${remaining.inHours}h left';
    }

    return '${remaining.inMinutes}m left';
  }

  String _buildPreview(
      String body,
      ) {
    const int maxCharacters = 180;

    final String cleanBody =
    body.trim();

    if (cleanBody.length <=
        maxCharacters) {
      return cleanBody;
    }

    return '${cleanBody.substring(
      0,
      maxCharacters,
    ).trim()}...';
  }

  void _openExperience(
      BuildContext context,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExperienceDetailScreen(
              experience: experience,
            ),
      ),
    );
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

    final String preview =
    _buildPreview(
      body,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openExperience(
            context,
          );
        },
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        child: Container(
          margin:
          const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          padding:
          const EdgeInsets.all(
            20,
          ),
          decoration:
          BoxDecoration(
            color:
            Theme.of(context)
                .colorScheme
                .surface,
            borderRadius:
            BorderRadius.circular(
              22,
            ),
            border: Border.all(
              color:
              Theme.of(context)
                  .dividerColor
                  .withValues(
                alpha: 0.35,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // TOP ROW
              // ----------------------------------------------------
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      AppTheme.primaryPurple
                          .withValues(
                        alpha: 0.11,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child:
                    const Text(
                      'EXPERIENCE',
                      style:
                      TextStyle(
                        color:
                        AppTheme.primaryPurple,
                        fontSize:
                        10,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing:
                        0.7,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    _formatTimeAgo(),
                    style:
                    TextStyle(
                      fontSize:
                      12,
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

              const SizedBox(
                height: 16,
              ),

              // ----------------------------------------------------
              // CATEGORY / ANONYMOUS
              // ----------------------------------------------------
              Text(
                '$category • '
                    '${isAnonymous ? 'Anonymous' : 'Public'}',
                style:
                TextStyle(
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

              // ----------------------------------------------------
              // SUBJECT
              // ----------------------------------------------------
              if (subject != null &&
                  subject.trim().isNotEmpty) ...[
                const SizedBox(
                  height: 10,
                ),

                Text(
                  'Subject: $subject',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.72,
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
                maxLines: 3,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  fontSize: 25,
                  height: 1.18,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // ----------------------------------------------------
              // PREVIEW
              // ----------------------------------------------------
              Text(
                preview,
                maxLines: 5,
                overflow:
                TextOverflow.ellipsis,
                style:
                TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color:
                  Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(
                    alpha: 0.78,
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ----------------------------------------------------
              // READ EXPERIENCE
              // ----------------------------------------------------
              Row(
                children: [
                  const Text(
                    'Read the experience',
                    style:
                    TextStyle(
                      color:
                      AppTheme.primaryPurple,
                      fontSize:
                      14,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  const Icon(
                    Icons.arrow_forward,
                    size: 17,
                    color:
                    AppTheme.primaryPurple,
                  ),
                ],
              ),

              if (expiration != null) ...[
                const SizedBox(
                  height: 18,
                ),

                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 15,
                      color:
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(
                        alpha: 0.4,
                      ),
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Text(
                      expiration,
                      style:
                      TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              const Divider(),

              const SizedBox(
                height: 4,
              ),

              // ----------------------------------------------------
              // GREEN FLAG / RED FLAG / COMMENT COUNTS
              // ----------------------------------------------------
              //
              // The reaction bar stays visible so users can
              // still quickly react from the Home feed.
              // ----------------------------------------------------
              GestureDetector(
                onTap: () {
                  // Prevent the outer card tap from interfering
                  // with reaction controls.
                },
                child:
                ExperienceInteractionBar(
                  experienceId:
                  experienceId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}