import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/theme/app_theme.dart';

class CreateExperienceScreen extends StatefulWidget {
  const CreateExperienceScreen({super.key});

  @override
  State<CreateExperienceScreen> createState() =>
      _CreateExperienceScreenState();
}

class _CreateExperienceScreenState
    extends State<CreateExperienceScreen> {
  // --------------------------------------------------------------
  // FORM
  // --------------------------------------------------------------
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  // --------------------------------------------------------------
  // SCROLL CONTROLLER
  // --------------------------------------------------------------
  //
  // If a guideline issue is detected, we send the user back
  // to the top so they immediately see the explanation.
  final ScrollController _scrollController =
  ScrollController();

  // --------------------------------------------------------------
  // TEXT CONTROLLERS
  // --------------------------------------------------------------
  final TextEditingController _subjectController =
  TextEditingController();

  final TextEditingController _titleController =
  TextEditingController();

  final TextEditingController _experienceController =
  TextEditingController();

  // --------------------------------------------------------------
  // EXPERIENCE SETTINGS
  // --------------------------------------------------------------
  bool _isAnonymous = true;

  String _selectedCategory = 'Dating';

  // --------------------------------------------------------------
  // TEMPORARY ATTACHMENT STATES
  // --------------------------------------------------------------
  //
  // These are still UI placeholders for now.
  bool _hasPhoto = false;
  bool _hasPoll = false;
  bool _hasLocation = false;

  // --------------------------------------------------------------
  // MODERATION / PUBLISHING STATE
  // --------------------------------------------------------------
  bool _isCheckingPost = false;

  String? _guidelineError;

  // --------------------------------------------------------------
  // CATEGORIES
  // --------------------------------------------------------------
  final List<String> _categories = [
    'Dating',
    'Relationship',
    'Friendship',
    'Family',
    'Work',
    'School',
    'Social',
    'Other',
  ];

  // --------------------------------------------------------------
  // ADD PHOTO
  // --------------------------------------------------------------
  void _addPhoto() {
    setState(() {
      _hasPhoto = !_hasPhoto;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasPhoto
              ? 'Photo placeholder added.'
              : 'Photo removed.',
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // ADD POLL
  // --------------------------------------------------------------
  void _addPoll() {
    setState(() {
      _hasPoll = !_hasPoll;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasPoll
              ? 'Poll placeholder added.'
              : 'Poll removed.',
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // ADD LOCATION
  // --------------------------------------------------------------
  void _addLocation() {
    setState(() {
      _hasLocation = !_hasLocation;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasLocation
              ? 'Broad location placeholder added.'
              : 'Location removed.',
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // REWRITE WITH AI
  // --------------------------------------------------------------
  //
  // Later:
  //
  // - User chooses this voluntarily.
  // - We send the draft to our secure backend.
  // - AI suggests safer wording.
  // - User decides whether to accept it.
  //
  // Nothing is automatically replaced.
  void _rewriteWithAi() {
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'AI rewriting will be connected later. '
              'Your original wording will remain under your control.',
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // DEVELOPMENT GUIDELINE CHECK
  // --------------------------------------------------------------
  //
  // This is ONLY a temporary local test.
  //
  // Later the real check will happen through the De-Fame
  // moderation system.
  String? _developmentGuidelineCheck() {
    final String combinedText =
    '${_titleController.text} '
        '${_experienceController.text} '
        '${_subjectController.text}'
        .toLowerCase();

    // ------------------------------------------------------------
    // BASIC PHONE NUMBER DETECTION
    // ------------------------------------------------------------
    final RegExp phonePattern = RegExp(
      r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b',
    );

    if (phonePattern.hasMatch(combinedText)) {
      return 'This Experience appears to contain a phone number. '
          'Remove private contact information before sharing.';
    }

    // ------------------------------------------------------------
    // BASIC THREAT DETECTION
    // ------------------------------------------------------------
    if (combinedText.contains('i will kill') ||
        combinedText.contains('i\'m going to kill') ||
        combinedText.contains('im going to kill')) {
      return 'This Experience appears to contain threatening language. '
          'Rewrite it manually or use the AI rewrite tool.';
    }

    return null;
  }

  // --------------------------------------------------------------
  // SHARE EXPERIENCE
  // --------------------------------------------------------------
  Future<void> _shareExperience() async {
    // Clear any old moderation message.
    setState(() {
      _guidelineError = null;
    });

    // ------------------------------------------------------------
    // REQUIRED FIELDS ONLY
    // ------------------------------------------------------------
    //
    // No minimum lengths.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isCheckingPost = true;
    });

    try {
      // ----------------------------------------------------------
      // DEVELOPMENT GUIDELINE CHECK
      // ----------------------------------------------------------
      //
      // Later this will be replaced by the real moderation call.
      final String? guidelineIssue =
      _developmentGuidelineCheck();

      if (guidelineIssue != null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isCheckingPost = false;
          _guidelineError = guidelineIssue;
        });

        // --------------------------------------------------------
        // RETURN USER TO TOP
        // --------------------------------------------------------
        await _scrollController.animateTo(
          0,
          duration: const Duration(
            milliseconds: 450,
          ),
          curve: Curves.easeOut,
        );

        return;
      }

      // ----------------------------------------------------------
      // GET CURRENT USER
      // ----------------------------------------------------------
      final User? user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw const AuthException(
          'You must be signed in to share an Experience.',
        );
      }

      // ----------------------------------------------------------
      // CREATED TIME
      // ----------------------------------------------------------
      final DateTime createdAt =
      DateTime.now().toUtc();

      // ----------------------------------------------------------
      // EXPIRATION
      // ----------------------------------------------------------
      //
      // Anonymous:
      //     expires in 72 hours
      //
      // Public:
      //     does not expire automatically
      final DateTime? expiresAt =
      _isAnonymous
          ? createdAt.add(
        const Duration(
          hours: 72,
        ),
      )
          : null;

      // ----------------------------------------------------------
      // CLEAN OPTIONAL SUBJECT
      // ----------------------------------------------------------
      final String subject =
      _subjectController.text.trim();

      // ----------------------------------------------------------
      // INSERT INTO SUPABASE
      // ----------------------------------------------------------
      await Supabase.instance.client
          .from('experiences')
          .insert(
        {
          'author_id': user.id,
          'is_anonymous': _isAnonymous,
          'category': _selectedCategory,

          // Store null instead of an empty string.
          'subject_name':
          subject.isEmpty
              ? null
              : subject,

          'title':
          _titleController.text.trim(),

          'body':
          _experienceController.text.trim(),

          'created_at':
          createdAt.toIso8601String(),

          'expires_at':
          expiresAt?.toIso8601String(),

          // ------------------------------------------------------
          // DEVELOPMENT MODERATION STATUS
          // ------------------------------------------------------
          //
          // Later:
          // pending → approved / review / blocked
          //
          // For now, approved lets us test publishing.
          'moderation_status':
          'approved',
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingPost = false;
      });

      // ----------------------------------------------------------
      // RETURN TO FEED
      // ----------------------------------------------------------
      //
      // We return true so the feed can know:
      //
      // "A new Experience was created."
      //
      // In the next step, MainFeedScreen will use this to refresh
      // its Supabase data immediately.
      Navigator.pop(
        context,
        true,
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingPost = false;
        _guidelineError =
        'Could not publish this Experience: ${error.message}';
      });

      await _scrollController.animateTo(
        0,
        duration: const Duration(
          milliseconds: 450,
        ),
        curve: Curves.easeOut,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingPost = false;
        _guidelineError = error.message;
      });

      await _scrollController.animateTo(
        0,
        duration: const Duration(
          milliseconds: 450,
        ),
        curve: Curves.easeOut,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingPost = false;
        _guidelineError =
        'Something went wrong while sharing your Experience.';
      });

      await _scrollController.animateTo(
        0,
        duration: const Duration(
          milliseconds: 450,
        ),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subjectController.dispose();
    _titleController.dispose();
    _experienceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------
      appBar: AppBar(
        title: const Text(
          'Share an Experience',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      // ------------------------------------------------------------
      // BODY
      // ------------------------------------------------------------
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              40,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // --------------------------------------------------
                // GUIDELINE / PUBLISHING ERROR
                // --------------------------------------------------
                if (_guidelineError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                      border: Border.all(
                        color: Colors.red,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .warning_amber_rounded,
                              color: Colors.red,
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                'This Experience can\'t be shared yet',
                                style: TextStyle(
                                  color:
                                  Colors.red,
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight
                                      .w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _guidelineError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'You can rewrite it yourself or use '
                              'the AI rewrite tool below.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],

                // --------------------------------------------------
                // INTRO
                // --------------------------------------------------
                Text(
                  'Share something that happened to you.',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Experiences are for firsthand stories. '
                      'Tell what happened without sharing private '
                      'or sensitive information.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.62,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // IDENTITY
                // --------------------------------------------------
                const _SectionTitle(
                  title:
                  'How do you want to post?',
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    // ----------------------------------------------
                    // ANONYMOUS
                    // ----------------------------------------------
                    Expanded(
                      child: _IdentityOption(
                        icon: Icons
                            .visibility_off_outlined,
                        title: 'Anonymous',
                        selected:
                        _isAnonymous,
                        onTap: () {
                          setState(() {
                            _isAnonymous =
                            true;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ----------------------------------------------
                    // PUBLIC
                    // ----------------------------------------------
                    Expanded(
                      child: _IdentityOption(
                        icon:
                        Icons.person_outline,
                        title: 'Public',
                        selected:
                        !_isAnonymous,
                        onTap: () {
                          setState(() {
                            _isAnonymous =
                            false;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // --------------------------------------------------
                // ANONYMOUS EXPIRATION
                // --------------------------------------------------
                if (_isAnonymous) ...[
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme
                          .primaryPurple
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color: AppTheme
                            .primaryPurple
                            .withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: AppTheme
                              .primaryPurple,
                          size: 21,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Anonymous Experiences are removed '
                                'from the public feed after 72 hours.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // --------------------------------------------------
                // CATEGORY
                // --------------------------------------------------
                const _SectionTitle(
                  title: 'Category',
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue:
                  _selectedCategory,
                  decoration:
                  InputDecoration(
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                    ),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  items: _categories
                      .map(
                        (category) =>
                        DropdownMenuItem<
                            String>(
                          value: category,
                          child: Text(
                            category,
                          ),
                        ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedCategory =
                          value;
                    });
                  },
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // SUBJECT
                // --------------------------------------------------
                const _SectionTitle(
                  title:
                  'Who or what is this about?',
                  optional: true,
                ),

                const SizedBox(height: 6),

                Text(
                  'Use a display name or general description. '
                      'Do not include addresses, phone numbers, or '
                      'other private information.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.52,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                  _subjectController,
                  decoration:
                  InputDecoration(
                    hintText:
                    'Example: Someone I dated',
                    prefixIcon: const Icon(
                      Icons
                          .person_search_outlined,
                    ),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // --------------------------------------------------
                // TITLE
                // --------------------------------------------------
                const _SectionTitle(
                  title: 'Title',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                  _titleController,
                  textCapitalization:
                  TextCapitalization
                      .sentences,
                  decoration:
                  InputDecoration(
                    hintText:
                    'Give your Experience a title',
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Add a title.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // --------------------------------------------------
                // EXPERIENCE BODY
                // --------------------------------------------------
                const _SectionTitle(
                  title: 'Your Experience',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                  _experienceController,
                  minLines: 8,
                  maxLines: null,
                  textCapitalization:
                  TextCapitalization
                      .sentences,
                  decoration:
                  InputDecoration(
                    hintText:
                    'Tell the community what happened...',
                    alignLabelWithHint:
                    true,
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Write your Experience.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // --------------------------------------------------
                // OPTIONAL AI REWRITE
                // --------------------------------------------------
                Tooltip(
                  message:
                  'Rewords your draft to make it safer and clearer '
                      'while keeping your original point.',
                  child: OutlinedButton.icon(
                    onPressed:
                    _rewriteWithAi,
                    icon: const Icon(
                      Icons.auto_awesome,
                    ),
                    label: const Text(
                      'Rewrite with AI',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor:
                      AppTheme
                          .primaryPurple,
                      side: const BorderSide(
                        color: AppTheme
                            .primaryPurple,
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // ATTACHMENTS
                // --------------------------------------------------
                const _SectionTitle(
                  title:
                  'Add to your Experience',
                  optional: true,
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child:
                      _AttachmentButton(
                        icon: Icons
                            .image_outlined,
                        label: 'Photo',
                        selected:
                        _hasPhoto,
                        onTap:
                        _addPhoto,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child:
                      _AttachmentButton(
                        icon:
                        Icons.poll_outlined,
                        label: 'Poll',
                        selected:
                        _hasPoll,
                        onTap:
                        _addPoll,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child:
                      _AttachmentButton(
                        icon: Icons
                            .location_on_outlined,
                        label: 'Location',
                        selected:
                        _hasLocation,
                        onTap:
                        _addLocation,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // COMMUNITY REMINDER
                // --------------------------------------------------
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(
                      alpha: 0.45,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Icon(
                        Icons
                            .shield_outlined,
                        color: AppTheme
                            .primaryPurple,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Share your firsthand experience. '
                              'Do not post private information, threats, '
                              'harassment, or other content prohibited '
                              'by De-Fame\'s Community Guidelines.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // SHARE EXPERIENCE
                // --------------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton(
                    onPressed:
                    _isCheckingPost
                        ? null
                        : _shareExperience,
                    style:
                    FilledButton.styleFrom(
                      backgroundColor:
                      AppTheme
                          .primaryPurple,
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                    child:
                    _isCheckingPost
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2.5,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Text(
                      'Share Experience',
                      style:
                      TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// SECTION TITLE
// =================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool optional;

  const _SectionTitle({
    required this.title,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.w800,
          ),
        ),

        if (optional) ...[
          const SizedBox(width: 7),

          Text(
            'Optional',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(
                alpha: 0.45,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// =================================================================
// IDENTITY OPTION
// =================================================================

class _IdentityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _IdentityOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primaryPurple
          .withValues(
        alpha: 0.12,
      )
          : Theme.of(context)
          .colorScheme
          .surface,
      borderRadius:
      BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(16),
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
            border: Border.all(
              width:
              selected ? 2 : 1,
              color: selected
                  ? AppTheme
                  .primaryPurple
                  : Theme.of(context)
                  .dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? AppTheme
                    .primaryPurple
                    : null,
                size: 28,
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                  color: selected
                      ? AppTheme
                      .primaryPurple
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// ATTACHMENT BUTTON
// =================================================================

class _AttachmentButton
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primaryPurple
          .withValues(
        alpha: 0.12,
      )
          : Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha: 0.40,
      ),
      borderRadius:
      BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(14),
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: selected
                  ? AppTheme
                  .primaryPurple
                  : Colors
                  .transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? AppTheme
                    .primaryPurple
                    : null,
              ),

              const SizedBox(height: 6),

              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w700,
                  color: selected
                      ? AppTheme
                      .primaryPurple
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}