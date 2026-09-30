import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentReactionBar extends StatefulWidget {
  final String commentId;

  const CommentReactionBar({
    super.key,
    required this.commentId,
  });

  @override
  State<CommentReactionBar> createState() =>
      _CommentReactionBarState();
}

class _CommentReactionBarState
    extends State<CommentReactionBar> {
  int _greenFlags = 0;
  int _redFlags = 0;

  String? _myReaction;

  bool _isLoading = true;
  bool _isChangingReaction = false;

  @override
  void initState() {
    super.initState();

    _loadReactions();
  }

  // --------------------------------------------------------------
  // LOAD COMMENT REACTIONS
  // --------------------------------------------------------------
  Future<void> _loadReactions() async {
    try {
      final User? user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        return;
      }

      final response =
      await Supabase.instance.client
          .from('experience_comment_reactions')
          .select('user_id, reaction')
          .eq(
        'comment_id',
        widget.commentId,
      );

      int greenFlags = 0;
      int redFlags = 0;

      String? myReaction;

      for (final item in response) {
        final String? reaction =
        item['reaction']?.toString();

        if (reaction == 'like') {
          greenFlags++;
        }

        if (reaction == 'dislike') {
          redFlags++;
        }

        if (item['user_id'] == user.id) {
          myReaction = reaction;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _greenFlags = greenFlags;
        _redFlags = redFlags;
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
  // ADD / REMOVE / SWITCH REACTION
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
      // USER TAPPED THE SAME FLAG AGAIN
      // REMOVE THE REACTION
      // ----------------------------------------------------------
      if (_myReaction == reaction) {
        await Supabase.instance.client
            .from('experience_comment_reactions')
            .delete()
            .eq(
          'comment_id',
          widget.commentId,
        )
            .eq(
          'user_id',
          user.id,
        );
      }

      // ----------------------------------------------------------
      // USER HAS NO REACTION YET
      // CREATE ONE
      // ----------------------------------------------------------
      else if (_myReaction == null) {
        await Supabase.instance.client
            .from('experience_comment_reactions')
            .insert(
          {
            'comment_id': widget.commentId,
            'user_id': user.id,
            'reaction': reaction,
          },
        );
      }

      // ----------------------------------------------------------
      // USER IS SWITCHING FLAGS
      // GREEN -> RED
      // OR
      // RED -> GREEN
      // ----------------------------------------------------------
      else {
        await Supabase.instance.client
            .from('experience_comment_reactions')
            .update(
          {
            'reaction': reaction,
            'updated_at': DateTime.now()
                .toUtc()
                .toIso8601String(),
          },
        )
            .eq(
          'comment_id',
          widget.commentId,
        )
            .eq(
          'user_id',
          user.id,
        );
      }

      await _loadReactions();
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 30,
      );
    }

    return Row(
      children: [
        // ----------------------------------------------------------
        // GREEN FLAG
        // ----------------------------------------------------------
        InkWell(
          onTap: _isChangingReaction
              ? null
              : () {
            _react('like');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 4,
            ),
            child: Row(
              children: [
                Icon(
                  _myReaction == 'like'
                      ? Icons.flag
                      : Icons.outlined_flag,
                  color: Colors.green,
                  size: 20,
                ),

                const SizedBox(
                  width: 4,
                ),

                Text(
                  '$_greenFlags',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _myReaction == 'like'
                        ? Colors.green
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ----------------------------------------------------------
        // RED FLAG
        // ----------------------------------------------------------
        InkWell(
          onTap: _isChangingReaction
              ? null
              : () {
            _react('dislike');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 4,
            ),
            child: Row(
              children: [
                Icon(
                  _myReaction == 'dislike'
                      ? Icons.flag
                      : Icons.outlined_flag,
                  color: Colors.red,
                  size: 20,
                ),

                const SizedBox(
                  width: 4,
                ),

                Text(
                  '$_redFlags',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _myReaction == 'dislike'
                        ? Colors.red
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}