import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/theme/app_theme.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState
    extends State<PostDetailScreen> {
  // ----------------------------------------------------------------
  // IMAGES
  // ----------------------------------------------------------------
  bool _isLoadingImages = true;

  final List<String> _signedImageUrls = [];

  int _selectedImageIndex = 0;

  // ----------------------------------------------------------------
  // REACTIONS
  // ----------------------------------------------------------------
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

    _loadImages();

    _loadReactionState();

    _reloadCounts();
  }

  // ----------------------------------------------------------------
  // LOAD ALL POST IMAGES
  // ----------------------------------------------------------------
  Future<void> _loadImages() async {
    try {
      final dynamic imagesData =
      widget.post['post_images'];

      if (imagesData is! List ||
          imagesData.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingImages = false;
        });

        return;
      }

      final List<Map<String, dynamic>>
      images =
      imagesData.map(
            (dynamic image) {
          return Map<String, dynamic>.from(
            image as Map,
          );
        },
      ).toList();

      images.sort(
            (
            first,
            second,
            ) {
          final int firstOrder =
              first['image_order'] as int? ??
                  0;

          final int secondOrder =
              second['image_order'] as int? ??
                  0;

          return firstOrder.compareTo(
            secondOrder,
          );
        },
      );

      final List<String> signedUrls = [];

      for (
      final Map<String, dynamic> image
      in images
      ) {
        final String? storagePath =
        image['image_url']
            ?.toString();

        if (storagePath == null ||
            storagePath.isEmpty) {
          continue;
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

        signedUrls.add(
          signedUrl,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _signedImageUrls
          ..clear()
          ..addAll(
            signedUrls,
          );

        _isLoadingImages = false;
      });
    } catch (error) {
      debugPrint(
        'Could not load Post Detail images: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingImages = false;
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
        'Could not load detail reaction: $error',
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
  // RELOAD COUNTS FROM POSTS TABLE
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
        'Could not reload post detail counts: $error',
      );
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
      // SAME REACTION AGAIN = REMOVE IT
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
      // NO REACTION YET = INSERT
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
      // UPDATE CACHED COUNTS
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
        'Post detail reaction database error: '
            '${error.message}',
      );

      await _reloadCounts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update reaction: '
                '${error.message}',
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Post detail reaction error: $error',
      );

      await _reloadCounts();

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
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingReaction = false;
        });
      }
    }
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
  // COMMENTS
  // ----------------------------------------------------------------
  void _openComments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Post comments are coming next.',
        ),
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(
            fontWeight:
            FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
            _sharePost,
            icon:
            const Icon(
              Icons.share_outlined,
            ),
          ),

          const SizedBox(
            width: 6,
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: ListView(
          padding:
          const EdgeInsets.only(
            bottom: 40,
          ),
          children: [
            // ------------------------------------------------------
            // HEADER
            // ------------------------------------------------------
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                14,
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
                        alpha: 0.12,
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
                    18,
                    color:
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha:
                      0.55,
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
                        0.55,
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
                        12,
                        fontWeight:
                        FontWeight.w600,
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
                  ],
                ],
              ),
            ),

            // ------------------------------------------------------
            // LARGE IMAGE
            // ------------------------------------------------------
            if (_isLoadingImages)
              const SizedBox(
                height:
                420,
                child:
                Center(
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (_signedImageUrls.isNotEmpty)
              AspectRatio(
                aspectRatio:
                4 / 5,
                child:
                Image.network(
                  _signedImageUrls[
                  _selectedImageIndex
                  ],
                  width:
                  double.infinity,
                  fit:
                  BoxFit.cover,
                ),
              ),

            // ------------------------------------------------------
            // THUMBNAILS
            // ------------------------------------------------------
            if (_signedImageUrls.length > 1) ...[
              const SizedBox(
                height:
                12,
              ),

              SizedBox(
                height:
                78,
                child:
                ListView.separated(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    16,
                  ),
                  scrollDirection:
                  Axis.horizontal,
                  itemCount:
                  _signedImageUrls.length,
                  separatorBuilder:
                      (
                      context,
                      index,
                      ) {
                    return const SizedBox(
                      width:
                      10,
                    );
                  },
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    final bool selected =
                        index ==
                            _selectedImageIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageIndex =
                              index;
                        });
                      },
                      child:
                      Container(
                        width:
                        66,
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                          border:
                          Border.all(
                            color:
                            selected
                                ? AppTheme
                                .primaryPurple
                                : Colors
                                .transparent,
                            width:
                            selected
                                ? 3
                                : 0,
                          ),
                        ),
                        child:
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(
                            9,
                          ),
                          child:
                          Image.network(
                            _signedImageUrls[
                            index
                            ],
                            fit:
                            BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // ------------------------------------------------------
            // CAPTION
            // ------------------------------------------------------
            if (caption != null &&
                caption.trim().isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  4,
                ),
                child:
                Text(
                  caption,
                  style:
                  const TextStyle(
                    fontSize:
                    16,
                    height:
                    1.5,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(
              height:
              16,
            ),

            const Divider(
              height:
              1,
            ),

            // ------------------------------------------------------
            // REAL INTERACTION BAR
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
                  InkWell(
                    onTap:
                    _openComments,
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                    child:
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal:
                        4,
                        vertical:
                        6,
                      ),
                      child:
                      Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
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
                            _commentCount
                                .toString(),
                            style:
                            const TextStyle(
                              fontSize:
                              13,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}