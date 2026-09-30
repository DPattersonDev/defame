import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/screens/experience_comments_screen.dart';

class ExperienceInteractionBar
    extends StatefulWidget {
  final String experienceId;

  const ExperienceInteractionBar({
    super.key,
    required this.experienceId,
  });

  @override
  State<ExperienceInteractionBar> createState() =>
      _ExperienceInteractionBarState();
}

class _ExperienceInteractionBarState
    extends State<ExperienceInteractionBar> {
  int _greenFlags = 0;
  int _redFlags = 0;
  int _comments = 0;

  String? _myReaction;

  bool _isLoading = true;
  bool _isChangingReaction = false;

  @override
  void initState() {
    super.initState();

    _loadInteractionState();
  }

  // --------------------------------------------------------------
  // LOAD REACTIONS + COMMENTS
  // --------------------------------------------------------------
  Future<void> _loadInteractionState() async {
    try {
      final User? user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        return;
      }

      // ----------------------------------------------------------
      // GET ALL REACTIONS FOR THIS EXPERIENCE
      // ----------------------------------------------------------
      final List<dynamic> reactions =
      await Supabase.instance.client
          .from(
        'experience_reactions',
      )
          .select(
        'user_id, reaction',
      )
          .eq(
        'experience_id',
        widget.experienceId,
      );

      int greenFlags = 0;
      int redFlags = 0;

      String? myReaction;

      for (final dynamic item in reactions) {
        final Map<String, dynamic> reaction =
        Map<String, dynamic>.from(
          item as Map,
        );

        final String? type =
        reaction['reaction']?.toString();

        if (type == 'like') {
          greenFlags++;
        }

        if (type == 'dislike') {
          redFlags++;
        }

        if (reaction['user_id'] ==
            user.id) {
          myReaction = type;
        }
      }

      // ----------------------------------------------------------
      // GET COMMENT COUNT
      // ----------------------------------------------------------
      final List<dynamic> comments =
      await Supabase.instance.client
          .from(
        'experience_comments',
      )
          .select('id')
          .eq(
        'experience_id',
        widget.experienceId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _greenFlags = greenFlags;
        _redFlags = redFlags;
        _comments = comments.length;

        _myReaction = myReaction;

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
  // REACT
  // --------------------------------------------------------------
  Future<void> _react(
      String reaction,
      ) async {
    if (_isChangingReaction) {
      return;
    }

    final User? user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isChangingReaction = true;
    });

    try {
      // ----------------------------------------------------------
      // SAME REACTION
      // ----------------------------------------------------------
      //
      // Example:
      //
      // Green selected
      // → tap Green again
      // → remove Green
      if (_myReaction == reaction) {
        await Supabase.instance.client
            .from(
          'experience_reactions',
        )
            .delete()
            .eq(
          'experience_id',
          widget.experienceId,
        )
            .eq(
          'user_id',
          user.id,
        );
      }

      // ----------------------------------------------------------
      // NO REACTION YET
      // ----------------------------------------------------------
      else if (_myReaction == null) {
        await Supabase.instance.client
            .from(
          'experience_reactions',
        )
            .insert(
          {
            'experience_id':
            widget.experienceId,
            'user_id':
            user.id,
            'reaction':
            reaction,
          },
        );
      }

      // ----------------------------------------------------------
      // SWITCH REACTION
      // ----------------------------------------------------------
      //
      // Green → Red
      //
      // OR
      //
      // Red → Green
      //
      // We UPDATE the existing row instead of inserting another.
      else {
        await Supabase.instance.client
            .from(
          'experience_reactions',
        )
            .update(
          {
            'reaction':
            reaction,
            'updated_at':
            DateTime.now()
                .toUtc()
                .toIso8601String(),
          },
        )
            .eq(
          'experience_id',
          widget.experienceId,
        )
            .eq(
          'user_id',
          user.id,
        );
      }

      await _loadInteractionState();
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error.message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingReaction = false;
        });
      }
    }
  }

  // --------------------------------------------------------------
  // OPEN COMMENTS
  // --------------------------------------------------------------
  Future<void> _openComments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExperienceCommentsScreen(
              experienceId:
              widget.experienceId,
            ),
      ),
    );

    // Someone may have added comments.
    await _loadInteractionState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 32,
        child: Align(
          alignment:
          Alignment.centerLeft,
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

    return Row(
      children: [
        // ----------------------------------------------------------
        // GREEN FLAG
        // ----------------------------------------------------------
        Tooltip(
          message: 'Green flag',
          child: InkWell(
            onTap:
            _isChangingReaction
                ? null
                : () {
              _react(
                'like',
              );
            },
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            child: Padding(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    _myReaction == 'like'
                        ? Icons.flag
                        : Icons
                        .outlined_flag,
                    // Actual green flag.
                    color:
                    Colors.green,
                    size: 27,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    '$_greenFlags',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w800,
                      color:
                      _myReaction ==
                          'like'
                          ? Colors
                          .green
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 18),

        // ----------------------------------------------------------
        // RED FLAG
        // ----------------------------------------------------------
        Tooltip(
          message: 'Red flag',
          child: InkWell(
            onTap:
            _isChangingReaction
                ? null
                : () {
              _react(
                'dislike',
              );
            },
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            child: Padding(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    _myReaction ==
                        'dislike'
                        ? Icons.flag
                        : Icons
                        .outlined_flag,
                    // Actual red flag.
                    color: Colors.red,
                    size: 27,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    '$_redFlags',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w800,
                      color:
                      _myReaction ==
                          'dislike'
                          ? Colors.red
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 18),

        // ----------------------------------------------------------
        // COMMENTS
        // ----------------------------------------------------------
        Tooltip(
          message: 'Comments',
          child: InkWell(
            onTap:
            _openComments,
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            child: Padding(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .chat_bubble_outline,
                    size: 24,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    '$_comments',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight
                          .w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        // ----------------------------------------------------------
        // SHARE
        // ----------------------------------------------------------
        IconButton(
          onPressed: () {
            // Native sharing will come later.
          },
          tooltip: 'Share',
          icon: const Icon(
            Icons.share_outlined,
          ),
        ),
      ],
    );
  }
}