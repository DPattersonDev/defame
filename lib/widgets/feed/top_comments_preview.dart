import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/screens/experience_comments_screen.dart';
import 'package:defame/theme/app_theme.dart';

class TopCommentsPreview extends StatefulWidget {
  final String experienceId;

  const TopCommentsPreview({
    super.key,
    required this.experienceId,
  });

  @override
  State<TopCommentsPreview> createState() =>
      _TopCommentsPreviewState();
}

class _TopCommentsPreviewState
    extends State<TopCommentsPreview> {
  List<Map<String, dynamic>> _comments = [];

  int _totalComments = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadTopComments();
  }

  // --------------------------------------------------------------
  // LOAD TOP COMMENTS
  // --------------------------------------------------------------
  Future<void> _loadTopComments() async {
    try {
      // ----------------------------------------------------------
      // GET ONLY THE TOP 2 COMMENTS
      // ----------------------------------------------------------
      //
      // Supabase calculates the ranking for us.
      // We do NOT load every comment onto the phone.
      // ----------------------------------------------------------
      final response =
      await Supabase.instance.client.rpc(
        'get_top_experience_comments',
        params: {
          'p_experience_id': widget.experienceId,
          'p_limit': 2,
        },
      );

      // ----------------------------------------------------------
      // GET TOTAL COMMENT COUNT
      // ----------------------------------------------------------
      //
      // This lets us display:
      // "View all 25 comments"
      // ----------------------------------------------------------
      final countResponse =
      await Supabase.instance.client
          .from('experience_comments')
          .select('id')
          .eq(
        'experience_id',
        widget.experienceId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments =
        List<Map<String, dynamic>>.from(
          response,
        );

        _totalComments = countResponse.length;

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // --------------------------------------------------------------
  // OPEN FULL COMMENTS SCREEN
  // --------------------------------------------------------------
  Future<void> _openComments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExperienceCommentsScreen(
              experienceId: widget.experienceId,
            ),
      ),
    );

    // ------------------------------------------------------------
    // WHEN THE USER COMES BACK
    // ------------------------------------------------------------
    //
    // They may have:
    // - added a comment
    // - green flagged a comment
    // - red flagged a comment
    //
    // So refresh the preview.
    // ------------------------------------------------------------
    await _loadTopComments();
  }

  // --------------------------------------------------------------
  // FORMAT COMMENT TIME
  // --------------------------------------------------------------
  String _formatTime(
      String? createdAtText,
      ) {
    if (createdAtText == null) {
      return '';
    }

    final DateTime? createdAt =
    DateTime.tryParse(
      createdAtText,
    );

    if (createdAt == null) {
      return '';
    }

    final Duration difference =
    DateTime.now()
        .toUtc()
        .difference(
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

  // --------------------------------------------------------------
  // FORMAT LARGE NUMBERS
  // --------------------------------------------------------------
  //
  // 1200 -> 1.2K
  // 10500 -> 10.5K
  // 1200000 -> 1.2M
  // --------------------------------------------------------------
  String _formatCount(
      int count,
      ) {
    if (count >= 1000000) {
      final double value =
          count / 1000000;

      return '${value.toStringAsFixed(
        value >= 10 ? 0 : 1,
      )}M';
    }

    if (count >= 1000) {
      final double value =
          count / 1000;

      return '${value.toStringAsFixed(
        value >= 10 ? 0 : 1,
      )}K';
    }

    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 12,
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    // ------------------------------------------------------------
    // NO COMMENTS YET
    // ------------------------------------------------------------
    if (_comments.isEmpty) {
      return InkWell(
        onTap: _openComments,
        borderRadius:
        BorderRadius.circular(12),
        child: const Padding(
          padding:
          EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Text(
            'Be the first to comment',
            style: TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final String? currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 8,
        ),

        // ----------------------------------------------------------
        // TOP COMMENTS TITLE
        // ----------------------------------------------------------
        Text(
          'Top comments',
          style: TextStyle(
            fontSize: 14,
            fontWeight:
            FontWeight.w900,
            color:
            Theme.of(context)
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

        // ----------------------------------------------------------
        // DISPLAY TOP 2 COMMENTS
        // ----------------------------------------------------------
        ..._comments.map(
              (comment) {
            final bool isMine =
                comment['author_id'] ==
                    currentUserId;

            final int greenFlags =
                int.tryParse(
                  comment['green_flags']
                      ?.toString() ??
                      '0',
                ) ??
                    0;

            final int redFlags =
                int.tryParse(
                  comment['red_flags']
                      ?.toString() ??
                      '0',
                ) ??
                    0;

            return Padding(
              padding:
              const EdgeInsets.only(
                bottom: 10,
              ),
              child: InkWell(
                onTap: _openComments,
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(
                      alpha: 0.55,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                    border:
                    Border.all(
                      color:
                      AppTheme
                          .primaryPurple
                          .withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // --------------------------------------------
                      // USER + TIME
                      // --------------------------------------------
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                            AppTheme
                                .primaryPurple
                                .withValues(
                              alpha: 0.15,
                            ),
                            child:
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color:
                              AppTheme.primaryPurple,
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Expanded(
                            child: Text(
                              isMine
                                  ? 'You'
                                  : 'De-Fame User',
                              style:
                              const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ),

                          Text(
                            _formatTime(
                              comment[
                              'created_at']
                                  ?.toString(),
                            ),
                            style:
                            TextStyle(
                              fontSize: 11,
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
                        height: 8,
                      ),

                      // --------------------------------------------
                      // COMMENT BODY
                      // --------------------------------------------
                      Text(
                        comment['body']
                            ?.toString() ??
                            '',
                        maxLines: 3,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      // --------------------------------------------
                      // SEPARATE GREEN + RED FLAG COUNTS
                      // --------------------------------------------
                      Row(
                        children: [
                          const Icon(
                            Icons.flag,
                            size: 17,
                            color:
                            Colors.green,
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          Text(
                            _formatCount(
                              greenFlags,
                            ),
                            style:
                            const TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          const Icon(
                            Icons.flag,
                            size: 17,
                            color:
                            Colors.red,
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          Text(
                            _formatCount(
                              redFlags,
                            ),
                            style:
                            const TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // ----------------------------------------------------------
        // VIEW ALL COMMENTS
        // ----------------------------------------------------------
        InkWell(
          onTap: _openComments,
          borderRadius:
          BorderRadius.circular(10),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              vertical: 6,
            ),
            child: Text(
              _totalComments == 1
                  ? 'View 1 comment'
                  : 'View all ${_formatCount(_totalComments)} comments',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w800,
                color:
                AppTheme.primaryPurple,
              ),
            ),
          ),
        ),
      ],
    );
  }
}