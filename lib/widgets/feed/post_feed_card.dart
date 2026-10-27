import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/screens/post_detail_screen.dart';
import 'package:defame/theme/app_theme.dart';

class PostFeedCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostFeedCard({
    super.key,
    required this.post,
  });

  @override
  State<PostFeedCard> createState() =>
      _PostFeedCardState();
}

class _PostFeedCardState
    extends State<PostFeedCard> {
  String? _coverImageUrl;

  bool _isLoadingImage = true;

  bool _isLoadingReaction = true;

  bool _isUpdatingReaction = false;

  String? _currentReaction;

  int _likeCount = 0;

  int _dislikeCount = 0;

  int _commentCount = 0;

  @override
  void initState() {
    super.initState();

    _likeCount =
        widget.post['like_count'] as int? ??
            0;

    _dislikeCount =
        widget.post['dislike_count'] as int? ??
            0;

    _commentCount =
        widget.post['comment_count'] as int? ??
            0;

    _loadCoverImage();

    _loadReactionState();
  }

  // ----------------------------------------------------------------
  // LOAD COVER IMAGE
  // ----------------------------------------------------------------
  Future<void> _loadCoverImage() async {
    try {
      final dynamic imagesData =
      widget.post['post_images'];

      if (imagesData is! List ||
          imagesData.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingImage = false;
        });

        return;
      }

      Map<String, dynamic>? coverImage;

      for (final dynamic image in imagesData) {
        if (image is Map &&
            image['image_order'] == 0) {
          coverImage =
          Map<String, dynamic>.from(
            image,
          );

          break;
        }
      }

      coverImage ??=
      Map<String, dynamic>.from(
        imagesData.first,
      );

      final String? storagePath =
      coverImage['image_url']
          ?.toString();

      if (storagePath == null ||
          storagePath.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingImage = false;
        });

        return;
      }

      final String signedUrl =
      await Supabase.instance.client.storage
          .from(
        'post-images',
      )
          .createSignedUrl(
        storagePath,
        3600,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _coverImageUrl =
            signedUrl;

        _isLoadingImage = false;
      });
    } catch (error) {
      debugPrint(
        'Could not load post cover image: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  // ----------------------------------------------------------------
  // LOAD CURRENT USER REACTION
  // ----------------------------------------------------------------
  Future<void> _loadReactionState() async {
    try {
      final SupabaseClient supabase =
          Supabase.instance.client;

      final User? user =
          supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingReaction = false;
        });

        return;
      }

      final String postId =
      widget.post['id']
          .toString();

      final List<dynamic> response =
      await supabase
          .from(
        'post_reactions',
      )
          .select(
        'reaction',
      )
          .eq(
        'post_id',
        postId,
      )
          .eq(
        'user_id',
        user.id,
      )
          .limit(
        1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (response.isNotEmpty) {
          _currentReaction =
              response.first['reaction']
                  ?.toString();
        } else {
          _currentReaction = null;
        }

        _isLoadingReaction = false;
      });
    } catch (error) {
      debugPrint(
        'Could not load post reaction: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingReaction = false;
      });
    }
  }

  // ----------------------------------------------------------------
  // HANDLE REACTION
  // ----------------------------------------------------------------
  Future<void> _handleReaction(
      String reaction,
      ) async {
    if (_isUpdatingReaction) {
      return;
    }

    final SupabaseClient supabase =
        Supabase.instance.client;

    final User? user =
        supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need to be signed in to react.',
          ),
        ),
      );

      return;
    }

    final String postId =
    widget.post['id']
        .toString();

    setState(() {
      _isUpdatingReaction = true;
    });

    try {
      // ------------------------------------------------------------
      // TAP SAME REACTION AGAIN = REMOVE
      // ------------------------------------------------------------
      if (_currentReaction == reaction) {
        await supabase
            .from(
          'post_reactions',
        )
            .delete()
            .eq(
          'post_id',
          postId,
        )
            .eq(
          'user_id',
          user.id,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          if (reaction == 'like') {
            _likeCount =
                (_likeCount - 1)
                    .clamp(
                  0,
                  999999999,
                );
          } else {
            _dislikeCount =
                (_dislikeCount - 1)
                    .clamp(
                  0,
                  999999999,
                );
          }

          _currentReaction = null;
        });
      }

      // ------------------------------------------------------------
      // NO EXISTING REACTION = INSERT
      // ------------------------------------------------------------
      else if (_currentReaction == null) {
        await supabase
            .from(
          'post_reactions',
        )
            .insert(
          {
            'post_id':
            postId,
            'user_id':
            user.id,
            'reaction':
            reaction,
          },
        );

        if (!mounted) {
          return;
        }

        setState(() {
          if (reaction == 'like') {
            _likeCount++;
          } else {
            _dislikeCount++;
          }

          _currentReaction = reaction;
        });
      }

      // ------------------------------------------------------------
      // SWITCH REACTION
      // ------------------------------------------------------------
      else {
        final String previousReaction =
        _currentReaction!;

        await supabase
            .from(
          'post_reactions',
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
          'post_id',
          postId,
        )
            .eq(
          'user_id',
          user.id,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          if (previousReaction == 'like') {
            _likeCount =
                (_likeCount - 1)
                    .clamp(
                  0,
                  999999999,
                );

            _dislikeCount++;
          } else {
            _dislikeCount =
                (_dislikeCount - 1)
                    .clamp(
                  0,
                  999999999,
                );

            _likeCount++;
          }

          _currentReaction = reaction;
        });
      }

      // ------------------------------------------------------------
      // KEEP POSTS TABLE COUNTS IN SYNC
      // ------------------------------------------------------------
      await supabase
          .from(
        'posts',
      )
          .update(
        {
          'like_count':
          _likeCount,
          'dislike_count':
          _dislikeCount,
        },
      )
          .eq(
        'id',
        postId,
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'Reaction database error: ${error.message}',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update reaction: ${error.message}',
          ),
        ),
      );

      // Reload in case local counts changed
      // before the database operation failed.
      await _reloadCounts();
    } catch (error) {
      debugPrint(
        'Reaction error: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update your reaction.',
          ),
        ),
      );

      await _reloadCounts();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingReaction = false;
        });
      }
    }
  }

  // ----------------------------------------------------------------
  // RELOAD COUNTS
  // ----------------------------------------------------------------
  Future<void> _reloadCounts() async {
    try {
      final String postId =
      widget.post['id']
          .toString();

      final Map<String, dynamic> response =
      await Supabase.instance.client
          .from(
        'posts',
      )
          .select(
        'like_count, dislike_count, comment_count',
      )
          .eq(
        'id',
        postId,
      )
          .single();

      if (!mounted) {
        return;
      }

      setState(() {
        _likeCount =
            response['like_count'] as int? ??
                0;

        _dislikeCount =
            response['dislike_count'] as int? ??
                0;

        _commentCount =
            response['comment_count'] as int? ??
                0;
      });
    } catch (error) {
      debugPrint(
        'Could not reload post counts: $error',
      );
    }
  }

  // ----------------------------------------------------------------
  // OPEN POST DETAIL
  // ----------------------------------------------------------------
  Future<void> _openPostDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PostDetailScreen(
              post:
              widget.post,
            ),
      ),
    );

    await _loadReactionState();

    await _reloadCounts();
  }

  // ----------------------------------------------------------------
  // SHARE
  // ----------------------------------------------------------------
  void _sharePost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Post sharing will be connected next.',
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // RELATIVE TIME
  // ----------------------------------------------------------------
  String _timeAgo() {
    final DateTime? createdAt =
    DateTime.tryParse(
      widget.post['created_at']
          ?.toString() ??
          '',
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

    if (difference.inSeconds < 60) {
      return 'just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    if (difference.inDays < 30) {
      final int weeks =
          difference.inDays ~/ 7;

      return '${weeks}w ago';
    }

    final int months =
        difference.inDays ~/ 30;

    return '${months}mo ago';
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final bool isAnonymous =
        widget.post['is_anonymous'] ==
            true;

    final String? caption =
    widget.post['caption']
        ?.toString();

    return Card(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      clipBehavior:
      Clip.antiAlias,
      child: InkWell(
        onTap:
        _openPostDetail,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            // ------------------------------------------------------
            // HEADER
            // ------------------------------------------------------
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                12,
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal:
                      10,
                      vertical:
                      5,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      AppTheme.primaryPurple
                          .withValues(
                        alpha:
                        0.12,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child:
                    const Text(
                      'POST',
                      style:
                      TextStyle(
                        color:
                        AppTheme.primaryPurple,
                        fontSize:
                        11,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Icon(
                    isAnonymous
                        ? Icons
                        .visibility_off_outlined
                        : Icons
                        .person_outline,
                    size:
                    17,
                    color:
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha:
                      0.5,
                    ),
                  ),

                  const SizedBox(
                    width:
                    5,
                  ),

                  Text(
                    isAnonymous
                        ? 'Anonymous'
                        : 'Public',
                    style:
                    TextStyle(
                      fontSize:
                      12,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(
                        alpha:
                        0.5,
                      ),
                    ),
                  ),

                  if (_timeAgo().isNotEmpty) ...[
                    const SizedBox(
                      width:
                      6,
                    ),

                    Text(
                      '•',
                      style:
                      TextStyle(
                        color:
                        Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(
                          alpha:
                          0.35,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                      6,
                    ),

                    Text(
                      _timeAgo(),
                      style:
                      TextStyle(
                        fontSize:
                        11,
                        fontWeight:
                        FontWeight.w600,
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
                ],
              ),
            ),

            // ------------------------------------------------------
            // COVER IMAGE
            // ------------------------------------------------------
            Expanded(
              child:
              _buildCoverArea(),
            ),

            // ------------------------------------------------------
            // CAPTION
            // ------------------------------------------------------
            if (caption != null &&
                caption.trim().isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  0,
                ),
                child:
                Text(
                  caption,
                  maxLines:
                  2,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize:
                    14,
                    fontWeight:
                    FontWeight.w600,
                    height:
                    1.35,
                  ),
                ),
              ),

            // ------------------------------------------------------
            // INTERACTION BAR
            // ------------------------------------------------------
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                10,
                8,
                8,
                8,
              ),
              child: Row(
                children: [
                  // ------------------------------------------------
                  // GREEN FLAG
                  // ------------------------------------------------
                  IconButton(
                    onPressed:
                    _isLoadingReaction ||
                        _isUpdatingReaction
                        ? null
                        : () {
                      _handleReaction(
                        'like',
                      );
                    },
                    tooltip:
                    'Green flag',
                    icon:
                    Icon(
                      _currentReaction ==
                          'like'
                          ? Icons.flag
                          : Icons
                          .outlined_flag,
                      color:
                      Colors.green,
                    ),
                    visualDensity:
                    VisualDensity.compact,
                  ),

                  Text(
                    _likeCount.toString(),
                    style:
                    TextStyle(
                      fontSize:
                      13,
                      fontWeight:
                      _currentReaction ==
                          'like'
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    width:
                    8,
                  ),

                  // ------------------------------------------------
                  // RED FLAG
                  // ------------------------------------------------
                  IconButton(
                    onPressed:
                    _isLoadingReaction ||
                        _isUpdatingReaction
                        ? null
                        : () {
                      _handleReaction(
                        'dislike',
                      );
                    },
                    tooltip:
                    'Red flag',
                    icon:
                    Icon(
                      _currentReaction ==
                          'dislike'
                          ? Icons.flag
                          : Icons
                          .outlined_flag,
                      color:
                      Colors.red,
                    ),
                    visualDensity:
                    VisualDensity.compact,
                  ),

                  Text(
                    _dislikeCount.toString(),
                    style:
                    TextStyle(
                      fontSize:
                      13,
                      fontWeight:
                      _currentReaction ==
                          'dislike'
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    width:
                    14,
                  ),

                  // ------------------------------------------------
                  // COMMENTS
                  // ------------------------------------------------
                  Icon(
                    Icons
                        .chat_bubble_outline,
                    size:
                    21,
                    color:
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha:
                      0.75,
                    ),
                  ),

                  const SizedBox(
                    width:
                    5,
                  ),

                  Text(
                    _commentCount.toString(),
                    style:
                    const TextStyle(
                      fontSize:
                      13,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const Spacer(),

                  // ------------------------------------------------
                  // SHARE
                  // ------------------------------------------------
                  IconButton(
                    onPressed:
                    _sharePost,
                    icon:
                    const Icon(
                      Icons.share_outlined,
                    ),
                    tooltip:
                    'Share',
                    visualDensity:
                    VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // COVER AREA
  // ----------------------------------------------------------------
  Widget _buildCoverArea() {
    if (_isLoadingImage) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_coverImageUrl == null) {
      return Container(
        color:
        Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(
          alpha: 0.4,
        ),
        alignment:
        Alignment.center,
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .image_not_supported_outlined,
              size:
              48,
              color:
              Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(
                alpha:
                0.35,
              ),
            ),

            const SizedBox(
              height:
              8,
            ),

            const Text(
              'No photo',
            ),
          ],
        ),
      );
    }

    return Image.network(
      _coverImageUrl!,
      width:
      double.infinity,
      height:
      double.infinity,
      fit:
      BoxFit.cover,
      loadingBuilder:
          (
          context,
          child,
          loadingProgress,
          ) {
        if (loadingProgress ==
            null) {
          return child;
        }

        return const Center(
          child:
          CircularProgressIndicator(),
        );
      },
      errorBuilder:
          (
          context,
          error,
          stackTrace,
          ) {
        return Center(
          child:
          Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .broken_image_outlined,
                size:
                48,
              ),

              const SizedBox(
                height:
                8,
              ),

              Text(
                'Could not load photo',
                style:
                TextStyle(
                  color:
                  Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(
                    alpha:
                    0.55,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}