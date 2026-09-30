import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/widgets/feed/comment_reaction_bar.dart';

class ExperienceCommentsScreen extends StatefulWidget {
  final String experienceId;

  const ExperienceCommentsScreen({
    super.key,
    required this.experienceId,
  });

  @override
  State<ExperienceCommentsScreen> createState() =>
      _ExperienceCommentsScreenState();
}

class _ExperienceCommentsScreenState
    extends State<ExperienceCommentsScreen> {
  // ----------------------------------------------------------------
  // HOW MANY COMMENTS TO LOAD AT A TIME
  // ----------------------------------------------------------------
  static const int _pageSize = 20;

  final TextEditingController _commentController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  List<Map<String, dynamic>> _comments = [];

  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isPosting = false;

  bool _hasMoreComments = true;

  String? _errorMessage;

  // ----------------------------------------------------------------
  // CURSOR
  // ----------------------------------------------------------------
  //
  // Instead of asking Supabase for:
  //
  // comments 1-20
  // comments 21-40
  //
  // we remember the oldest comment we currently have.
  //
  // Then we ask:
  // "Give me comments older than this one."
  //
  // This works better when new comments are being added while
  // somebody is scrolling.
  // ----------------------------------------------------------------
  DateTime? _oldestLoadedCommentTime;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(
      _handleScroll,
    );

    _loadInitialComments();
  }

  // ----------------------------------------------------------------
  // WATCH SCROLL POSITION
  // ----------------------------------------------------------------
  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    // When the user gets close to the bottom,
    // load the next batch.
    final double remainingScroll =
        _scrollController.position.extentAfter;

    if (remainingScroll < 300) {
      _loadMoreComments();
    }
  }

  // ----------------------------------------------------------------
  // LOAD FIRST 20 COMMENTS
  // ----------------------------------------------------------------
  Future<void> _loadInitialComments() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;

      _comments = [];

      _oldestLoadedCommentTime = null;

      _hasMoreComments = true;
    });

    try {
      final response =
      await Supabase.instance.client
          .from('experience_comments')
          .select()
          .eq(
        'experience_id',
        widget.experienceId,
      )

      // Newest comments first.
          .order(
        'created_at',
        ascending: false,
      )

      // Only request 20.
          .limit(_pageSize);

      final List<Map<String, dynamic>>
      loadedComments =
      List<Map<String, dynamic>>.from(
        response,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = loadedComments;

        // If fewer than 20 came back,
        // there are no more comments to load.
        _hasMoreComments =
            loadedComments.length == _pageSize;

        if (loadedComments.isNotEmpty) {
          final String? createdAtText =
          loadedComments.last['created_at']
              ?.toString();

          if (createdAtText != null) {
            _oldestLoadedCommentTime =
                DateTime.tryParse(
                  createdAtText,
                );
          }
        }

        _isLoadingInitial = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingInitial = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingInitial = false;

        _errorMessage =
        'Something went wrong while loading comments.';
      });
    }
  }

  // ----------------------------------------------------------------
  // LOAD NEXT 20 COMMENTS
  // ----------------------------------------------------------------
  Future<void> _loadMoreComments() async {
    // Don't make duplicate requests.
    if (_isLoadingInitial ||
        _isLoadingMore ||
        !_hasMoreComments) {
      return;
    }

    final DateTime? oldestTime =
        _oldestLoadedCommentTime;

    if (oldestTime == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // ------------------------------------------------------------
      // GET COMMENTS OLDER THAN THE LAST COMMENT WE HAVE
      // ------------------------------------------------------------
      final response =
      await Supabase.instance.client
          .from('experience_comments')
          .select()
          .eq(
        'experience_id',
        widget.experienceId,
      )
          .lt(
        'created_at',
        oldestTime
            .toUtc()
            .toIso8601String(),
      )
          .order(
        'created_at',
        ascending: false,
      )
          .limit(_pageSize);

      final List<Map<String, dynamic>>
      loadedComments =
      List<Map<String, dynamic>>.from(
        response,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        // Add older comments underneath
        // the comments already loaded.
        _comments.addAll(
          loadedComments,
        );

        // If Supabase returned fewer than 20,
        // we've reached the end.
        _hasMoreComments =
            loadedComments.length == _pageSize;

        if (loadedComments.isNotEmpty) {
          final String? createdAtText =
          loadedComments.last['created_at']
              ?.toString();

          if (createdAtText != null) {
            _oldestLoadedCommentTime =
                DateTime.tryParse(
                  createdAtText,
                );
          }
        }

        _isLoadingMore = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // ----------------------------------------------------------------
  // POST COMMENT
  // ----------------------------------------------------------------
  Future<void> _postComment() async {
    final String comment =
    _commentController.text.trim();

    if (comment.isEmpty) {
      return;
    }

    final User? user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await Supabase.instance.client
          .from('experience_comments')
          .insert(
        {
          'experience_id':
          widget.experienceId,
          'author_id':
          user.id,
          'body':
          comment,
        },
      );

      _commentController.clear();

      // ------------------------------------------------------------
      // REFRESH THE FIRST PAGE
      // ------------------------------------------------------------
      //
      // Since newest comments appear first,
      // the new comment will now be at the top.
      // ------------------------------------------------------------
      await _loadInitialComments();

      if (!mounted) {
        return;
      }

      // Move back to the newest comment.
      WidgetsBinding.instance.addPostFrameCallback(
            (_) {
          if (!_scrollController.hasClients) {
            return;
          }

          _scrollController.animateTo(
            0,
            duration:
            const Duration(
              milliseconds: 300,
            ),
            curve:
            Curves.easeOut,
          );
        },
      );
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
          _isPosting = false;
        });
      }
    }
  }

  // ----------------------------------------------------------------
  // FORMAT COMMENT TIME
  // ----------------------------------------------------------------
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

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    final int weeks =
    (difference.inDays / 7).floor();

    return '${weeks}w';
  }

  @override
  void dispose() {
    _scrollController.removeListener(
      _handleScroll,
    );

    _commentController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------
      appBar: AppBar(
        title: const Text(
          'Comments',
          style: TextStyle(
            fontWeight:
            FontWeight.w900,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
            _loadInitialComments,
            tooltip:
            'Refresh comments',
            icon:
            const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // ------------------------------------------------------------
      // BODY
      // ------------------------------------------------------------
      body: Column(
        children: [
          Expanded(
            child: _buildCommentsArea(
              currentUserId,
            ),
          ),

          // --------------------------------------------------------
          // COMMENT COMPOSER
          // --------------------------------------------------------
          SafeArea(
            top: false,
            child: Container(
              padding:
              const EdgeInsets.fromLTRB(
                14,
                10,
                10,
                10,
              ),
              decoration:
              BoxDecoration(
                color:
                Theme.of(context)
                    .colorScheme
                    .surface,
                border:
                Border(
                  top:
                  BorderSide(
                    color:
                    Theme.of(context)
                        .dividerColor,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  // ------------------------------------------------
                  // COMMENT FIELD
                  // ------------------------------------------------
                  Expanded(
                    child:
                    TextField(
                      controller:
                      _commentController,
                      minLines:
                      1,
                      maxLines:
                      5,
                      textCapitalization:
                      TextCapitalization
                          .sentences,
                      decoration:
                      InputDecoration(
                        hintText:
                        'Add a comment...',
                        filled:
                        true,
                        fillColor:
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(
                          alpha:
                          0.45,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            22,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          16,
                          vertical:
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  // ------------------------------------------------
                  // SEND BUTTON
                  // ------------------------------------------------
                  IconButton.filled(
                    onPressed:
                    _isPosting
                        ? null
                        : _postComment,
                    style:
                    IconButton.styleFrom(
                      backgroundColor:
                      AppTheme.primaryPurple,
                      foregroundColor:
                      Colors.white,
                    ),
                    icon:
                    _isPosting
                        ? const SizedBox(
                      width:
                      18,
                      height:
                      18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // BUILD COMMENTS AREA
  // ----------------------------------------------------------------
  Widget _buildCommentsArea(
      String? currentUserId,
      ) {
    // --------------------------------------------------------------
    // FIRST LOAD
    // --------------------------------------------------------------
    if (_isLoadingInitial) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    // --------------------------------------------------------------
    // ERROR
    // --------------------------------------------------------------
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color:
                Colors.red,
                size:
                48,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                _errorMessage!,
                textAlign:
                TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              FilledButton(
                onPressed:
                _loadInitialComments,
                child:
                const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --------------------------------------------------------------
    // NO COMMENTS
    // --------------------------------------------------------------
    if (_comments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size:
              58,
            ),

            SizedBox(
              height:
              14,
            ),

            Text(
              'No comments yet',
              style:
              TextStyle(
                fontSize:
                20,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            SizedBox(
              height:
              6,
            ),

            Text(
              'Start the conversation.',
            ),
          ],
        ),
      );
    }

    // --------------------------------------------------------------
    // COMMENT LIST
    // --------------------------------------------------------------
    return RefreshIndicator(
      onRefresh:
      _loadInitialComments,
      child:
      ListView.separated(
        controller:
        _scrollController,

        physics:
        const AlwaysScrollableScrollPhysics(),

        padding:
        const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),

        // Add one extra row at the bottom
        // while loading another page.
        itemCount:
        _comments.length +
            (_isLoadingMore ? 1 : 0),

        separatorBuilder:
            (
            context,
            index,
            ) {
          // Don't draw a divider after
          // the loading spinner.
          if (index >=
              _comments.length - 1) {
            return const SizedBox();
          }

          return const Divider(
            height:
            26,
          );
        },

        itemBuilder:
            (
            context,
            index,
            ) {
          // --------------------------------------------------------
          // BOTTOM LOADING INDICATOR
          // --------------------------------------------------------
          if (index >=
              _comments.length) {
            return const Padding(
              padding:
              EdgeInsets.symmetric(
                vertical:
                18,
              ),
              child:
              Center(
                child:
                SizedBox(
                  width:
                  24,
                  height:
                  24,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                  ),
                ),
              ),
            );
          }

          final Map<String, dynamic>
          comment =
          _comments[index];

          final bool isMine =
              comment['author_id'] ==
                  currentUserId;

          return Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // AVATAR
              // ----------------------------------------------------
              CircleAvatar(
                radius:
                20,
                backgroundColor:
                AppTheme.primaryPurple
                    .withValues(
                  alpha:
                  0.15,
                ),
                child:
                const Icon(
                  Icons.person_outline,
                  color:
                  AppTheme.primaryPurple,
                ),
              ),

              const SizedBox(
                width:
                12,
              ),

              // ----------------------------------------------------
              // COMMENT CONTENT
              // ----------------------------------------------------
              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // USER + TIME
                    // ------------------------------------------------
                    Row(
                      children: [
                        Expanded(
                          child:
                          Text(
                            isMine
                                ? 'You'
                                : 'De-Fame User',
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ),

                        Text(
                          _formatTime(
                            comment['created_at']
                                ?.toString(),
                          ),
                          style:
                          TextStyle(
                            fontSize:
                            12,
                            color:
                            Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(
                              alpha:
                              0.45,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                      6,
                    ),

                    // ------------------------------------------------
                    // COMMENT BODY
                    // ------------------------------------------------
                    Text(
                      comment['body']
                          ?.toString() ??
                          '',
                      style:
                      const TextStyle(
                        fontSize:
                        15,
                        height:
                        1.4,
                      ),
                    ),

                    const SizedBox(
                      height:
                      8,
                    ),

                    // ------------------------------------------------
                    // GREEN + RED FLAGS
                    // ------------------------------------------------
                    CommentReactionBar(
                      commentId:
                      comment['id']
                          .toString(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}