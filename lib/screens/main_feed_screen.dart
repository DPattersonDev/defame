import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/screens/activity_screen.dart';
import 'package:defame/screens/community_screen.dart';
import 'package:defame/screens/create_experience_screen.dart';
import 'package:defame/screens/create_post_screen.dart';
import 'package:defame/screens/profile_screen.dart';
import 'package:defame/theme/app_theme.dart';
import 'package:defame/widgets/feed/experience_feed_card.dart';
import 'package:defame/widgets/feed/post_feed_card.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({
    super.key,
  });

  @override
  State<MainFeedScreen> createState() =>
      _MainFeedScreenState();
}

class _MainFeedScreenState
    extends State<MainFeedScreen> {
  // ----------------------------------------------------------------
  // NAVIGATION
  // ----------------------------------------------------------------
  //
  // 0 = Home
  // 1 = Community
  // 2 = Create
  // 3 = Activity
  // 4 = Profile
  // ----------------------------------------------------------------
  int _selectedIndex = 0;

  // ----------------------------------------------------------------
  // FEED
  // ----------------------------------------------------------------
  int _currentPostIndex = 0;

  String _selectedFilter = 'Recent';

  bool _isLoadingFeed = true;

  String? _feedError;

  // ----------------------------------------------------------------
  // ALL FEED ITEMS
  // ----------------------------------------------------------------
  //
  // Experiences and Posts both go into this list.
  //
  // Each item receives:
  //
  // _feed_type = experience
  //
  // or:
  //
  // _feed_type = post
  // ----------------------------------------------------------------
  List<Map<String, dynamic>> _feedItems = [];

  // ----------------------------------------------------------------
  // EXPIRATION TIMER
  // ----------------------------------------------------------------
  Timer? _expirationTimer;

  // ----------------------------------------------------------------
  // PAGE CONTROLLER
  // ----------------------------------------------------------------
  final PageController _pageController =
  PageController(
    viewportFraction: 0.94,
  );

  @override
  void initState() {
    super.initState();

    _loadFeed();

    // --------------------------------------------------------------
    // CHECK EXPIRED EXPERIENCES EVERY MINUTE
    // --------------------------------------------------------------
    _expirationTimer =
        Timer.periodic(
          const Duration(
            minutes: 1,
          ),
              (_) {
            _removeExpiredExperiences();
          },
        );
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();

    _pageController.dispose();

    super.dispose();
  }

  // ----------------------------------------------------------------
  // LOAD HOME FEED
  // ----------------------------------------------------------------
  Future<void> _loadFeed() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingFeed = true;

      _feedError = null;
    });

    try {
      final SupabaseClient supabase =
          Supabase.instance.client;

      final String now =
      DateTime.now()
          .toUtc()
          .toIso8601String();

      // ------------------------------------------------------------
      // LOAD EXPERIENCES
      // ------------------------------------------------------------
      //
      // Only Experiences that:
      //
      // 1. are approved
      // 2. have not expired
      //
      // are allowed into the Home feed.
      // ------------------------------------------------------------
      final List<dynamic> experienceResponse =
      await supabase
          .from(
        'experiences',
      )
          .select()
          .eq(
        'moderation_status',
        'approved',
      )
          .or(
        'expires_at.is.null,expires_at.gt.$now',
      )
          .order(
        'created_at',
        ascending: false,
      );

      // ------------------------------------------------------------
      // LOAD POSTS
      // ------------------------------------------------------------
      //
      // We also load post_images so PostFeedCard can find
      // image_order 0 and use it as the cover.
      // ------------------------------------------------------------
      final List<dynamic> postResponse =
      await supabase
          .from(
        'posts',
      )
          .select(
        '''
                *,
                post_images (
                  image_url,
                  image_order
                )
                ''',
      )
          .eq(
        'moderation_status',
        'approved',
      )
          .order(
        'created_at',
        ascending: false,
      );

      // ------------------------------------------------------------
      // CONVERT EXPERIENCES TO FEED ITEMS
      // ------------------------------------------------------------
      final List<Map<String, dynamic>>
      experienceItems =
      experienceResponse.map(
            (item) {
          final Map<String, dynamic> map =
          Map<String, dynamic>.from(
            item as Map,
          );

          map['_feed_type'] =
          'experience';

          return map;
        },
      ).toList();

      // ------------------------------------------------------------
      // CONVERT POSTS TO FEED ITEMS
      // ------------------------------------------------------------
      final List<Map<String, dynamic>>
      postItems =
      postResponse.map(
            (item) {
          final Map<String, dynamic> map =
          Map<String, dynamic>.from(
            item as Map,
          );

          map['_feed_type'] =
          'post';

          return map;
        },
      ).toList();

      // ------------------------------------------------------------
      // COMBINE BOTH TYPES
      // ------------------------------------------------------------
      final List<Map<String, dynamic>>
      combinedItems = [
        ...experienceItems,
        ...postItems,
      ];

      // ------------------------------------------------------------
      // SORT NEWEST FIRST
      // ------------------------------------------------------------
      combinedItems.sort(
            (
            first,
            second,
            ) {
          final DateTime firstDate =
              DateTime.tryParse(
                first['created_at']
                    ?.toString() ??
                    '',
              ) ??
                  DateTime.fromMillisecondsSinceEpoch(
                    0,
                  );

          final DateTime secondDate =
              DateTime.tryParse(
                second['created_at']
                    ?.toString() ??
                    '',
              ) ??
                  DateTime.fromMillisecondsSinceEpoch(
                    0,
                  );

          return secondDate.compareTo(
            firstDate,
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _feedItems =
            combinedItems;

        _currentPostIndex = 0;

        _isLoadingFeed = false;
      });

      // ------------------------------------------------------------
      // RETURN TO FIRST FEED ITEM
      // ------------------------------------------------------------
      if (_pageController.hasClients &&
          _visibleFeedItems.isNotEmpty) {
        _pageController.jumpToPage(
          0,
        );
      }
    } on PostgrestException catch (error) {
      debugPrint(
        'Feed database error: ${error.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingFeed = false;

        _feedError =
        'Could not load the feed: '
            '${error.message}';
      });
    } catch (error) {
      debugPrint(
        'Feed error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingFeed = false;

        _feedError =
        'Something went wrong while loading the feed.';
      });
    }
  }

  // ----------------------------------------------------------------
  // FILTERED FEED
  // ----------------------------------------------------------------
  List<Map<String, dynamic>>
  get _visibleFeedItems {
    // --------------------------------------------------------------
    // EXPERIENCES ONLY
    // --------------------------------------------------------------
    if (_selectedFilter ==
        'Experiences') {
      return _feedItems.where(
            (item) {
          return item['_feed_type'] ==
              'experience';
        },
      ).toList();
    }

    // --------------------------------------------------------------
    // POSTS ONLY
    // --------------------------------------------------------------
    if (_selectedFilter ==
        'Posts') {
      return _feedItems.where(
            (item) {
          return item['_feed_type'] ==
              'post';
        },
      ).toList();
    }

    // --------------------------------------------------------------
    // RECENT
    // --------------------------------------------------------------
    //
    // Popular and Nearby will get their own logic later.
    //
    // For now:
    //
    // Recent
    // Popular
    // Nearby
    //
    // all show the combined feed.
    // --------------------------------------------------------------
    return _feedItems;
  }

  // ----------------------------------------------------------------
  // REMOVE EXPIRED EXPERIENCES
  // ----------------------------------------------------------------
  void _removeExpiredExperiences() {
    if (!mounted ||
        _feedItems.isEmpty) {
      return;
    }

    final DateTime now =
    DateTime.now().toUtc();

    final List<Map<String, dynamic>>
    activeItems =
    _feedItems.where(
          (item) {
        // ----------------------------------------------------------
        // POSTS DO NOT EXPIRE
        // ----------------------------------------------------------
        if (item['_feed_type'] ==
            'post') {
          return true;
        }

        final String? expiresAtText =
        item['expires_at']
            ?.toString();

        // ----------------------------------------------------------
        // EXPERIENCE WITH NO EXPIRATION
        // ----------------------------------------------------------
        if (expiresAtText == null ||
            expiresAtText.isEmpty) {
          return true;
        }

        final DateTime? expiresAt =
        DateTime.tryParse(
          expiresAtText,
        );

        // Do not remove something if the date
        // somehow cannot be parsed.
        if (expiresAt == null) {
          return true;
        }

        return expiresAt
            .toUtc()
            .isAfter(
          now,
        );
      },
    ).toList();

    if (activeItems.length ==
        _feedItems.length) {
      return;
    }

    setState(() {
      _feedItems =
          activeItems;

      final int visibleLength =
          _visibleFeedItems.length;

      if (visibleLength == 0) {
        _currentPostIndex = 0;
      } else if (_currentPostIndex >=
          visibleLength) {
        _currentPostIndex =
            visibleLength - 1;
      }
    });

    if (_pageController.hasClients &&
        _visibleFeedItems.isNotEmpty) {
      final int safePage =
      _currentPostIndex.clamp(
        0,
        _visibleFeedItems.length - 1,
      );

      _pageController.animateToPage(
        safePage,
        duration:
        const Duration(
          milliseconds: 250,
        ),
        curve:
        Curves.easeOut,
      );
    }
  }

  // ----------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ----------------------------------------------------------------
  void _onNavigationTapped(
      int index,
      ) {
    // --------------------------------------------------------------
    // CREATE BUTTON
    // --------------------------------------------------------------
    if (index == 2) {
      _openCreateMenu();

      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // ----------------------------------------------------------------
  // CREATE EXPERIENCE
  // ----------------------------------------------------------------
  Future<void> _openExperienceCreator() async {
    final bool? created =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const CreateExperienceScreen(),
      ),
    );

    if (created == true) {
      await _loadFeed();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedIndex = 0;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Experience shared.',
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------------
  // CREATE POST
  // ----------------------------------------------------------------
  Future<void> _openPostCreator() async {
    final bool? created =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const CreatePostScreen(),
      ),
    );

    if (created == true) {
      await _loadFeed();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  // ----------------------------------------------------------------
  // CREATE MENU
  // ----------------------------------------------------------------
  void _openCreateMenu() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
      Theme.of(context)
          .colorScheme
          .surface,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              30,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const Text(
                  'What do you want to create?',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Choose how you want to share.',
                  style:
                  TextStyle(
                    fontSize: 14,
                    color:
                    Theme.of(
                      sheetContext,
                    )
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 26,
                ),

                // --------------------------------------------------
                // EXPERIENCE
                // --------------------------------------------------
                _CreateOption(
                  icon:
                  Icons.auto_stories_outlined,
                  title:
                  'Experience',
                  description:
                  'Share something that happened to you.',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    _openExperienceCreator();
                  },
                ),

                const SizedBox(
                  height: 14,
                ),

                // --------------------------------------------------
                // POST
                // --------------------------------------------------
                _CreateOption(
                  icon:
                  Icons.add_photo_alternate_outlined,
                  title:
                  'Post',
                  description:
                  'Share photos, a caption, or a story.',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    _openPostCreator();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------
  // CHANGE FILTER
  // ----------------------------------------------------------------
  void _changeFilter(
      String filter,
      ) {
    setState(() {
      _selectedFilter =
          filter;

      _currentPostIndex = 0;
    });

    if (_pageController.hasClients &&
        _visibleFeedItems.isNotEmpty) {
      _pageController.jumpToPage(
        0,
      );
    }
  }

  // ----------------------------------------------------------------
  // BUILD SCREEN
  // ----------------------------------------------------------------
  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      // ------------------------------------------------------------
      // HOME APP BAR
      // ------------------------------------------------------------
      appBar:
      _selectedIndex == 0
          ? _buildHomeAppBar()
          : null,

      // ------------------------------------------------------------
      // CURRENT TAB
      // ------------------------------------------------------------
      body:
      _buildCurrentPage(),

      // ------------------------------------------------------------
      // BOTTOM NAVIGATION
      // ------------------------------------------------------------
      bottomNavigationBar:
      NavigationBar(
        selectedIndex:
        _selectedIndex,
        onDestinationSelected:
        _onNavigationTapped,
        destinations:
        const [
          NavigationDestination(
            icon:
            Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
            Icon(
              Icons.home,
            ),
            label:
            'Home',
          ),

          NavigationDestination(
            icon:
            Icon(
              Icons.groups_outlined,
            ),
            selectedIcon:
            Icon(
              Icons.groups,
            ),
            label:
            'Community',
          ),

          NavigationDestination(
            icon:
            Icon(
              Icons.add_circle_outline,
              size: 32,
            ),
            selectedIcon:
            Icon(
              Icons.add_circle,
              size: 32,
            ),
            label:
            'Create',
          ),

          NavigationDestination(
            icon:
            Icon(
              Icons.favorite_border,
            ),
            selectedIcon:
            Icon(
              Icons.favorite,
            ),
            label:
            'Activity',
          ),

          NavigationDestination(
            icon:
            Icon(
              Icons.person_outline,
            ),
            selectedIcon:
            Icon(
              Icons.person,
            ),
            label:
            'Profile',
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // HOME APP BAR
  // ----------------------------------------------------------------
  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      automaticallyImplyLeading:
      false,
      title:
      const Text(
        'De-Fame',
        style:
        TextStyle(
          fontWeight:
          FontWeight.w900,
          fontSize:
          24,
        ),
      ),
      actions: [
        // ----------------------------------------------------------
        // SEARCH
        // ----------------------------------------------------------
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content:
                Text(
                  'Search coming later.',
                ),
              ),
            );
          },
          icon:
          const Icon(
            Icons.search,
          ),
        ),

        // ----------------------------------------------------------
        // ACTIVITY
        // ----------------------------------------------------------
        IconButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 3;
            });
          },
          icon:
          const Icon(
            Icons.notifications_none,
          ),
        ),

        const SizedBox(
          width: 6,
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // CHOOSE CURRENT TAB
  // ----------------------------------------------------------------
  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeFeed();

      case 1:
        return const CommunityScreen();

      case 3:
        return const ActivityScreen();

      case 4:
        return const ProfileScreen();

      default:
        return _buildHomeFeed();
    }
  }

  // ----------------------------------------------------------------
  // HOME FEED
  // ----------------------------------------------------------------
  Widget _buildHomeFeed() {
    final List<Map<String, dynamic>>
    visibleItems =
        _visibleFeedItems;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // --------------------------------------------------------
          // FILTERS
          // --------------------------------------------------------
          SizedBox(
            height: 54,
            child:
            ListView(
              scrollDirection:
              Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(
                horizontal:
                16,
                vertical:
                6,
              ),
              children: [
                _FilterButton(
                  label:
                  'Recent',
                  selected:
                  _selectedFilter ==
                      'Recent',
                  onTap: () {
                    _changeFilter(
                      'Recent',
                    );
                  },
                ),

                _FilterButton(
                  label:
                  'Popular',
                  selected:
                  _selectedFilter ==
                      'Popular',
                  onTap: () {
                    _changeFilter(
                      'Popular',
                    );
                  },
                ),

                _FilterButton(
                  label:
                  'Nearby',
                  selected:
                  _selectedFilter ==
                      'Nearby',
                  onTap: () {
                    _changeFilter(
                      'Nearby',
                    );
                  },
                ),

                _FilterButton(
                  label:
                  'Experiences',
                  selected:
                  _selectedFilter ==
                      'Experiences',
                  onTap: () {
                    _changeFilter(
                      'Experiences',
                    );
                  },
                ),

                _FilterButton(
                  label:
                  'Posts',
                  selected:
                  _selectedFilter ==
                      'Posts',
                  onTap: () {
                    _changeFilter(
                      'Posts',
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          // --------------------------------------------------------
          // LOADING
          // --------------------------------------------------------
          if (_isLoadingFeed)
            const Expanded(
              child:
              Center(
                child:
                CircularProgressIndicator(),
              ),
            )

          // --------------------------------------------------------
          // ERROR
          // --------------------------------------------------------
          else if (_feedError != null)
            Expanded(
              child:
              Center(
                child:
                Padding(
                  padding:
                  const EdgeInsets.all(
                    28,
                  ),
                  child:
                  Column(
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
                        height:
                        14,
                      ),

                      Text(
                        _feedError!,
                        textAlign:
                        TextAlign.center,
                      ),

                      const SizedBox(
                        height:
                        18,
                      ),

                      FilledButton(
                        onPressed:
                        _loadFeed,
                        child:
                        const Text(
                          'Try Again',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          // --------------------------------------------------------
          // EMPTY FILTER / FEED
          // --------------------------------------------------------
          else if (visibleItems.isEmpty)
              Expanded(
                child:
                Center(
                  child:
                  Padding(
                    padding:
                    const EdgeInsets.all(
                      28,
                    ),
                    child:
                    Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedFilter ==
                              'Posts'
                              ? Icons
                              .photo_library_outlined
                              : Icons
                              .auto_stories_outlined,
                          size:
                          64,
                          color:
                          AppTheme.primaryPurple
                              .withValues(
                            alpha:
                            0.75,
                          ),
                        ),

                        const SizedBox(
                          height:
                          18,
                        ),

                        Text(
                          _selectedFilter ==
                              'Posts'
                              ? 'No Posts yet'
                              : _selectedFilter ==
                              'Experiences'
                              ? 'No Experiences yet'
                              : 'Nothing here yet',
                          style:
                          const TextStyle(
                            fontSize:
                            22,
                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height:
                          8,
                        ),

                        const Text(
                          'Create something and it will appear here.',
                          textAlign:
                          TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )

            // --------------------------------------------------------
            // REAL FEED
            // --------------------------------------------------------
            else ...[
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    6,
                  ),
                  child:
                  Row(
                    children: [
                      Text(
                        'Swipe left or right',
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

                      const Spacer(),

                      Text(
                        '${_currentPostIndex + 1} / ${visibleItems.length}',
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
                    ],
                  ),
                ),

                // ------------------------------------------------------
                // PAGE VIEW
                // ------------------------------------------------------
                Expanded(
                  child:
                  PageView.builder(
                    controller:
                    _pageController,
                    scrollDirection:
                    Axis.horizontal,
                    itemCount:
                    visibleItems.length,
                    onPageChanged:
                        (index) {
                      setState(() {
                        _currentPostIndex =
                            index;
                      });
                    },
                    itemBuilder:
                        (
                        context,
                        index,
                        ) {
                      final Map<String, dynamic>
                      item =
                      visibleItems[index];

                      final String feedType =
                          item['_feed_type']
                              ?.toString() ??
                              '';

                      // ------------------------------------------------
                      // POST
                      // ------------------------------------------------
                      if (feedType ==
                          'post') {
                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            right:
                            8,
                            bottom:
                            12,
                          ),
                          child:
                          PostFeedCard(
                            post:
                            item,
                          ),
                        );
                      }

                      // ------------------------------------------------
                      // EXPERIENCE
                      // ------------------------------------------------
                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          right:
                          8,
                          bottom:
                          12,
                        ),
                        child:
                        ExperienceFeedCard(
                          experience:
                          item,
                        ),
                      );
                    },
                  ),
                ),
              ],
        ],
      ),
    );
  }
}

// ==================================================================
// FILTER BUTTON
// ==================================================================
class _FilterButton
    extends StatelessWidget {
  final String label;

  final bool selected;

  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        right: 8,
      ),
      child:
      ChoiceChip(
        label:
        Text(
          label,
        ),
        selected:
        selected,
        onSelected:
            (_) {
          onTap();
        },
      ),
    );
  }
}

// ==================================================================
// CREATE OPTION
// ==================================================================
class _CreateOption
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String description;

  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha:
        0.45,
      ),
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child:
      InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child:
        Padding(
          padding:
          const EdgeInsets.all(
            18,
          ),
          child:
          Row(
            children: [
              Container(
                width:
                52,
                height:
                52,
                decoration:
                BoxDecoration(
                  color:
                  AppTheme.primaryPurple
                      .withValues(
                    alpha:
                    0.13,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                Icon(
                  icon,
                  color:
                  AppTheme.primaryPurple,
                  size:
                  28,
                ),
              ),

              const SizedBox(
                width:
                16,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontSize:
                        17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height:
                      5,
                    ),

                    Text(
                      description,
                      style:
                      TextStyle(
                        fontSize:
                        13,
                        height:
                        1.4,
                        color:
                        Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(
                          alpha:
                          0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}