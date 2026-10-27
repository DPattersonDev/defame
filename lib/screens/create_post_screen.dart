import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
  });

  @override
  State<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState
    extends State<CreatePostScreen> {
  // ----------------------------------------------------------------
  // CONTROLLERS
  // ----------------------------------------------------------------
  final TextEditingController _captionController =
  TextEditingController();

  // ----------------------------------------------------------------
  // PHOTO PICKER
  // ----------------------------------------------------------------
  final ImagePicker _imagePicker =
  ImagePicker();

  final List<XFile> _selectedImages = [];

  // ----------------------------------------------------------------
  // POST OPTIONS
  // ----------------------------------------------------------------
  bool _isAnonymous = false;

  bool _isPosting = false;

  static const int _maxImages = 5;

  @override
  void dispose() {
    _captionController.dispose();

    super.dispose();
  }

  // ----------------------------------------------------------------
  // PICK PHOTOS
  // ----------------------------------------------------------------
  Future<void> _pickPhotos() async {
    final int remainingSlots =
        _maxImages - _selectedImages.length;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can add up to 5 photos.',
          ),
        ),
      );

      return;
    }

    try {
      final List<XFile> pickedImages =
      await _imagePicker.pickMultiImage(
        imageQuality: 90,
      );

      if (pickedImages.isEmpty) {
        return;
      }

      final List<XFile> imagesToAdd =
      pickedImages
          .take(remainingSlots)
          .toList();

      setState(() {
        _selectedImages.addAll(
          imagesToAdd,
        );
      });

      if (pickedImages.length >
          remainingSlots) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only $remainingSlots more '
                  '${remainingSlots == 1 ? 'photo' : 'photos'} '
                  'could be added.',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint(
        'Photo picker error: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open your photos.',
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------------
  // REMOVE PHOTO
  // ----------------------------------------------------------------
  void _removeImage(
      int index,
      ) {
    setState(() {
      _selectedImages.removeAt(
        index,
      );
    });
  }

  // ----------------------------------------------------------------
  // MAKE PHOTO THE COVER
  // ----------------------------------------------------------------
  void _makeCoverPhoto(
      int index,
      ) {
    if (index == 0) {
      return;
    }

    setState(() {
      final XFile selectedImage =
      _selectedImages.removeAt(
        index,
      );

      _selectedImages.insert(
        0,
        selectedImage,
      );
    });
  }

  // ----------------------------------------------------------------
  // FILE EXTENSION
  // ----------------------------------------------------------------
  String _getFileExtension(
      XFile image,
      ) {
    final String fileName =
    image.name.toLowerCase();

    if (fileName.endsWith('.png')) {
      return 'png';
    }

    if (fileName.endsWith('.webp')) {
      return 'webp';
    }

    if (fileName.endsWith('.jpeg')) {
      return 'jpeg';
    }

    // Default to JPG.
    return 'jpg';
  }

  // ----------------------------------------------------------------
  // CONTENT TYPE
  // ----------------------------------------------------------------
  String _getContentType(
      XFile image,
      ) {
    if (image.mimeType != null &&
        image.mimeType!.startsWith(
          'image/',
        )) {
      return image.mimeType!;
    }

    final String extension =
    _getFileExtension(
      image,
    );

    switch (extension) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  // ----------------------------------------------------------------
  // CLEAN UP FAILED POST
  // ----------------------------------------------------------------
  Future<void> _cleanUpFailedPost({
    required String? postId,
    required List<String> uploadedPaths,
  }) async {
    final SupabaseClient supabase =
        Supabase.instance.client;

    // --------------------------------------------------------------
    // DELETE UPLOADED FILES
    // --------------------------------------------------------------
    if (uploadedPaths.isNotEmpty) {
      try {
        await supabase.storage
            .from(
          'post-images',
        )
            .remove(
          uploadedPaths,
        );
      } catch (error) {
        debugPrint(
          'Could not clean up uploaded images: $error',
        );
      }
    }

    // --------------------------------------------------------------
    // DELETE POST
    // --------------------------------------------------------------
    //
    // post_images rows use ON DELETE CASCADE,
    // so removing the post also removes any image rows.
    // --------------------------------------------------------------
    if (postId != null) {
      try {
        await supabase
            .from(
          'posts',
        )
            .delete()
            .eq(
          'id',
          postId,
        );
      } catch (error) {
        debugPrint(
          'Could not clean up failed post: $error',
        );
      }
    }
  }

  // ----------------------------------------------------------------
  // SHARE POST
  // ----------------------------------------------------------------
  Future<void> _sharePost() async {
    // --------------------------------------------------------------
    // BASIC VALIDATION
    // --------------------------------------------------------------
    if (_selectedImages.isEmpty &&
        _captionController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a photo or write something first.',
          ),
        ),
      );

      return;
    }

    // Prevent accidental double publishing.
    if (_isPosting) {
      return;
    }

    final SupabaseClient supabase =
        Supabase.instance.client;

    final User? user =
        supabase.auth.currentUser;

    // --------------------------------------------------------------
    // USER MUST BE SIGNED IN
    // --------------------------------------------------------------
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need to be signed in to create a post.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isPosting = true;
    });

    String? createdPostId;

    final List<String> uploadedPaths = [];

    try {
      final String caption =
      _captionController.text.trim();

      // ------------------------------------------------------------
      // STEP 1
      // CREATE POST DATABASE ROW
      // ------------------------------------------------------------
      final Map<String, dynamic> createdPost =
      await supabase
          .from(
        'posts',
      )
          .insert(
        {
          'author_id': user.id,
          'is_anonymous':
          _isAnonymous,

          // Store null instead of an empty string.
          'caption':
          caption.isEmpty
              ? null
              : caption,

          // AI moderation will eventually decide
          // this value before publishing.
          'moderation_status':
          'approved',
        },
      )
          .select(
        'id',
      )
          .single();

      createdPostId =
          createdPost['id'].toString();

      // ------------------------------------------------------------
      // STEP 2
      // UPLOAD EACH PHOTO
      // ------------------------------------------------------------
      for (
      int index = 0;
      index < _selectedImages.length;
      index++
      ) {
        final XFile selectedImage =
        _selectedImages[index];

        final File imageFile =
        File(
          selectedImage.path,
        );

        final String extension =
        _getFileExtension(
          selectedImage,
        );

        final String contentType =
        _getContentType(
          selectedImage,
        );

        // ----------------------------------------------------------
        // STORAGE STRUCTURE
        // ----------------------------------------------------------
        //
        // post-images/
        //   USER_ID/
        //     POST_ID/
        //       0.jpg  <-- cover
        //       1.jpg
        //       2.jpg
        //
        // Because tapping a thumbnail moves it to index 0,
        // index 0 is always the selected cover photo.
        // ----------------------------------------------------------
        final String storagePath =
            '${user.id}/'
            '$createdPostId/'
            '$index.$extension';

        await supabase.storage
            .from(
          'post-images',
        )
            .upload(
          storagePath,
          imageFile,
          fileOptions:
          FileOptions(
            cacheControl:
            '3600',
            upsert:
            false,
            contentType:
            contentType,
          ),
        );

        // Remember the uploaded file in case
        // something later fails.
        uploadedPaths.add(
          storagePath,
        );
      }

      // ------------------------------------------------------------
      // STEP 3
      // CREATE POST_IMAGES ROWS
      // ------------------------------------------------------------
      if (uploadedPaths.isNotEmpty) {
        final List<Map<String, dynamic>>
        imageRows = [];

        for (
        int index = 0;
        index < uploadedPaths.length;
        index++
        ) {
          imageRows.add(
            {
              'post_id':
              createdPostId,

              // ----------------------------------------------------
              // IMPORTANT
              // ----------------------------------------------------
              //
              // Our bucket is PRIVATE.
              //
              // We store the Storage path here instead of a public
              // URL. When we display Posts later, De-Fame will
              // generate a temporary signed URL for this path.
              //
              // The column is currently named image_url, but it is
              // functioning as the stored object path.
              // ----------------------------------------------------
              'image_url':
              uploadedPaths[index],

              'image_order':
              index,
            },
          );
        }

        await supabase
            .from(
          'post_images',
        )
            .insert(
          imageRows,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isPosting = false;
      });

      // ------------------------------------------------------------
      // SUCCESS
      // ------------------------------------------------------------
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post shared.',
          ),
        ),
      );

      // Return true so MainFeedScreen can know
      // a new Post was created.
      Navigator.pop(
        context,
        true,
      );
    } on StorageException catch (error) {
      debugPrint(
        'Storage error: ${error.message}',
      );

      await _cleanUpFailedPost(
        postId:
        createdPostId,
        uploadedPaths:
        uploadedPaths,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isPosting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not upload your photos: '
                '${error.message}',
          ),
        ),
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'Database error: ${error.message}',
      );

      await _cleanUpFailedPost(
        postId:
        createdPostId,
        uploadedPaths:
        uploadedPaths,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isPosting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not publish your post: '
                '${error.message}',
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Create post error: $error',
      );

      await _cleanUpFailedPost(
        postId:
        createdPostId,
        uploadedPaths:
        uploadedPaths,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isPosting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while publishing your post.',
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------
  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontWeight:
            FontWeight.w900,
          ),
        ),
        actions: [
          TextButton(
            onPressed:
            _isPosting
                ? null
                : _sharePost,
            child:
            _isPosting
                ? const SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Share',
              style: TextStyle(
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding:
          const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            40,
          ),
          children: [
            // ------------------------------------------------------
            // PUBLIC / ANONYMOUS
            // ------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Posting as',
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
                ),

                SegmentedButton<bool>(
                  segments:
                  const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(
                        'Public',
                      ),
                      icon: Icon(
                        Icons.person_outline,
                      ),
                    ),

                    ButtonSegment<bool>(
                      value: true,
                      label: Text(
                        'Anonymous',
                      ),
                      icon: Icon(
                        Icons
                            .visibility_off_outlined,
                      ),
                    ),
                  ],
                  selected: {
                    _isAnonymous,
                  },
                  onSelectionChanged:
                      (
                      selection,
                      ) {
                    setState(() {
                      _isAnonymous =
                          selection.first;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // ------------------------------------------------------
            // PHOTO SECTION TITLE
            // ------------------------------------------------------
            Row(
              children: [
                const Text(
                  'Photos',
                  style:
                  TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const Spacer(),

                Text(
                  '${_selectedImages.length}/$_maxImages',
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
                      alpha: 0.45,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Your first photo becomes the cover shown in the Home feed.',
              style:
              TextStyle(
                fontSize: 13,
                height: 1.4,
                color:
                Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(
                  alpha: 0.55,
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ------------------------------------------------------
            // NO PHOTOS YET
            // ------------------------------------------------------
            if (_selectedImages.isEmpty)
              _buildAddPhotoBox()

            // ------------------------------------------------------
            // COVER PHOTO
            // ------------------------------------------------------
            else
              _buildCoverPhoto(),

            // ------------------------------------------------------
            // THUMBNAILS
            // ------------------------------------------------------
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(
                height: 14,
              ),

              _buildPhotoThumbnails(),
            ],

            const SizedBox(
              height: 28,
            ),

            // ------------------------------------------------------
            // CAPTION / STORY
            // ------------------------------------------------------
            const Text(
              'Caption or Story',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Optional. Add context, tell the story, or leave the photo to speak for itself.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color:
                Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(
                  alpha: 0.55,
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            TextField(
              controller:
              _captionController,
              minLines: 5,
              maxLines: 14,
              textCapitalization:
              TextCapitalization.sentences,
              decoration:
              InputDecoration(
                hintText:
                'What do you want people to know?',
                alignLabelWithHint:
                true,
                filled:
                true,
                fillColor:
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(
                  alpha: 0.35,
                ),
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ------------------------------------------------------
            // AI REWRITE
            // ------------------------------------------------------
            OutlinedButton.icon(
              onPressed:
              _isPosting
                  ? null
                  : () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'AI Rewrite is coming next.',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.auto_awesome,
                color:
                AppTheme.primaryPurple,
              ),
              label: const Text(
                'Rewrite with AI',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
              style:
              OutlinedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(
                  vertical: 15,
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ------------------------------------------------------
            // OPTIONAL FEATURES
            // ------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child:
                  _OptionalFeatureButton(
                    icon:
                    Icons.poll_outlined,
                    label:
                    'Poll',
                    onTap: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Polls coming later.',
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                  _OptionalFeatureButton(
                    icon:
                    Icons.location_on_outlined,
                    label:
                    'Location',
                    onTap: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Post location coming later.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 28,
            ),

            // ------------------------------------------------------
            // SHARE BUTTON
            // ------------------------------------------------------
            SizedBox(
              width:
              double.infinity,
              child:
              FilledButton(
                onPressed:
                _isPosting
                    ? null
                    : _sharePost,
                style:
                FilledButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
                child:
                _isPosting
                    ? const Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Text(
                      'Sharing...',
                    ),
                  ],
                )
                    : const Text(
                  'Share Post',
                  style:
                  TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // ADD PHOTO BOX
  // ----------------------------------------------------------------
  Widget _buildAddPhotoBox() {
    return Material(
      color:
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha: 0.35,
      ),
      borderRadius:
      BorderRadius.circular(
        20,
      ),
      child: InkWell(
        onTap:
        _isPosting
            ? null
            : _pickPhotos,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        child: Container(
          height: 260,
          alignment:
          Alignment.center,
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration:
                BoxDecoration(
                  color:
                  AppTheme.primaryPurple
                      .withValues(
                    alpha: 0.12,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                const Icon(
                  Icons
                      .add_photo_alternate_outlined,
                  size: 31,
                  color:
                  AppTheme.primaryPurple,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              const Text(
                'Add Photos',
                style:
                TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Choose up to 5',
                style:
                TextStyle(
                  fontSize: 13,
                  color:
                  Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // COVER PHOTO
  // ----------------------------------------------------------------
  Widget _buildCoverPhoto() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius:
          BorderRadius.circular(
            20,
          ),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio:
                4 / 5,
                child: Image.file(
                  File(
                    _selectedImages[0]
                        .path,
                  ),
                  width:
                  double.infinity,
                  fit:
                  BoxFit.cover,
                ),
              ),

              // ----------------------------------------------------
              // COVER LABEL
              // ----------------------------------------------------
              Positioned(
                left: 12,
                top: 12,
                child:
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.black
                        .withValues(
                      alpha: 0.65,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child:
                  const Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Icon(
                        Icons
                            .photo_outlined,
                        color:
                        Colors.white,
                        size:
                        15,
                      ),

                      SizedBox(
                        width: 5,
                      ),

                      Text(
                        'Cover',
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize:
                          11,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ----------------------------------------------------
              // REMOVE COVER
              // ----------------------------------------------------
              Positioned(
                right: 12,
                top: 12,
                child:
                IconButton.filled(
                  onPressed:
                  _isPosting
                      ? null
                      : () {
                    _removeImage(
                      0,
                    );
                  },
                  style:
                  IconButton.styleFrom(
                    backgroundColor:
                    Colors.black
                        .withValues(
                      alpha: 0.65,
                    ),
                    foregroundColor:
                    Colors.white,
                  ),
                  icon:
                  const Icon(
                    Icons.close,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          'This is the only photo shown on the Home feed.',
          style:
          TextStyle(
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
    );
  }

  // ----------------------------------------------------------------
  // PHOTO THUMBNAILS
  // ----------------------------------------------------------------
  Widget _buildPhotoThumbnails() {
    return SizedBox(
      height: 86,
      child:
      ListView.separated(
        scrollDirection:
        Axis.horizontal,
        itemCount:
        _selectedImages.length +
            (_selectedImages.length <
                _maxImages
                ? 1
                : 0),
        separatorBuilder:
            (
            context,
            index,
            ) {
          return const SizedBox(
            width: 10,
          );
        },
        itemBuilder:
            (
            context,
            index,
            ) {
          // --------------------------------------------------------
          // ADD MORE BUTTON
          // --------------------------------------------------------
          if (index ==
              _selectedImages.length) {
            return InkWell(
              onTap:
              _isPosting
                  ? null
                  : _pickPhotos,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              child:
              Container(
                width: 78,
                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                  border:
                  Border.all(
                    color:
                    AppTheme.primaryPurple
                        .withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
                child:
                const Icon(
                  Icons.add,
                  color:
                  AppTheme.primaryPurple,
                ),
              ),
            );
          }

          // --------------------------------------------------------
          // PHOTO THUMBNAIL
          // --------------------------------------------------------
          return GestureDetector(
            onTap:
            _isPosting
                ? null
                : () {
              _makeCoverPhoto(
                index,
              );
            },
            child:
            Stack(
              children: [
                Container(
                  width: 78,
                  decoration:
                  BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                    border:
                    Border.all(
                      color:
                      index == 0
                          ? AppTheme
                          .primaryPurple
                          : Colors
                          .transparent,
                      width:
                      index == 0
                          ? 2.5
                          : 0,
                    ),
                  ),
                  child:
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    child:
                    Image.file(
                      File(
                        _selectedImages[
                        index]
                            .path,
                      ),
                      fit:
                      BoxFit.cover,
                    ),
                  ),
                ),

                if (index == 0)
                  Positioned(
                    left: 5,
                    bottom: 5,
                    child:
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        AppTheme
                            .primaryPurple,
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                      ),
                      child:
                      const Text(
                        'Cover',
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize:
                          9,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================================================================
// OPTIONAL FEATURE BUTTON
// ==================================================================
class _OptionalFeatureButton
    extends StatelessWidget {
  final IconData icon;

  final String label;

  final VoidCallback onTap;

  const _OptionalFeatureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return OutlinedButton.icon(
      onPressed:
      onTap,
      icon:
      Icon(
        icon,
      ),
      label:
      Text(
        label,
      ),
      style:
      OutlinedButton.styleFrom(
        padding:
        const EdgeInsets.symmetric(
          vertical: 14,
        ),
      ),
    );
  }
}