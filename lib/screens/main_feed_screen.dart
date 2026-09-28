import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/screens/create_experience_screen.dart';
import 'package:defame/theme/app_theme.dart';
import 'package:defame/widgets/feed/experience_feed_card.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() =>
      _MainFeedScreenState();
}

class _MainFeedScreenState
    extends State<MainFeedScreen> {
  // --------------------------------------------------------------
  // NAVIGATION
  // --------------------------------------------------------------
  int _selectedIndex = 0;

  // --------------------------------------------------------------
  // FEED
  // --------------------------------------------------------------
  int _currentPostIndex = 0;

  String _selectedFilter = 'Recent';

  bool _isLoadingExperiences = true;

  String? _feedError;

  List<Map<String, dynamic>>
  _experiences = [];

  // --------------------------------------------------------------
  // PAGE CONTROLLER
  // --------------------------------------------------------------
  final PageController _pageController =
  PageController(
    viewportFraction: 0.94,
  );

  @override
  void initState() {
    super.initState();

    _loadExperiences();
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  // --------------------------------------------------------------
  // LOAD EXPERIENCES
  // --------------------------------------------------------------
  Future<void> _loadExperiences() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingExperiences = true;
      _feedError = null;
    });

    try {
      // ----------------------------------------------------------
      // READ FROM SUPABASE
      // ----------------------------------------------------------
      //
      // Newest Experience first.
      final List<dynamic> response =
      await Supabase.instance.client
          .from('experiences')
          .select()
          .eq(
        'moderation_status',
        'approved',
      )
          .order(
        'created_at',
        ascending: false,
      );

      final List<Map<String, dynamic>>
      loadedExperiences =
      response
          .map(
            (item) =>
        Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _experiences =
            loadedExperiences;

        _isLoadingExperiences = false;

        _currentPostIndex = 0;
      });

      // ----------------------------------------------------------
      // RETURN TO FIRST POST
      // ----------------------------------------------------------
      if (_pageController.hasClients &&
          _experiences.isNotEmpty) {
        _pageController.jumpToPage(0);
      }
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingExperiences = false;

        _feedError =
        'Could not load Experiences: ${error.message}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingExperiences = false;

        _feedError =
        'Something went wrong while loading the feed.';
      });
    }
  }

  // --------------------------------------------------------------
  // NAVIGATION
  // --------------------------------------------------------------
  void _onNavigationTapped(int index) {
    // Create is an action, not a normal tab.
    if (index == 2) {
      _openCreateMenu();

      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // --------------------------------------------------------------
  // CREATE EXPERIENCE
  // --------------------------------------------------------------
  Future<void> _openExperienceCreator() async {
    final bool? created =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const CreateExperienceScreen(),
      ),
    );

    // ------------------------------------------------------------
    // NEW EXPERIENCE CREATED
    // ------------------------------------------------------------
    //
    // create_experience_screen.dart returns true after a
    // successful Supabase insert.
    if (created == true) {
      await _loadExperiences();

      if (!mounted) {
        return;
      }

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

  // --------------------------------------------------------------
  // CREATE MENU
  // --------------------------------------------------------------
  void _openCreateMenu() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
      Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'What do you want to create?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Choose how you want to share.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(sheetContext)
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // ------------------------------------------------
                // EXPERIENCE
                // ------------------------------------------------
                _CreateOption(
                  icon:
                  Icons.auto_stories_outlined,
                  title: 'Experience',
                  description:
                  'Share something that happened to you.',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    _openExperienceCreator();
                  },
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // NORMAL POST
                // ------------------------------------------------
                _CreateOption(
                  icon: Icons
                      .add_photo_alternate_outlined,
                  title: 'Post',
                  description:
                  'Share a thought, photo, video, poll, or update.',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Post creator coming next.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------
  // CHANGE FILTER
  // --------------------------------------------------------------
  void _changeFilter(
      String filter,
      ) {
    setState(() {
      _selectedFilter = filter;
    });

    // ------------------------------------------------------------
    // FILTER LOGIC COMES LATER
    // ------------------------------------------------------------
    //
    // Right now we're only changing the selected visual chip.
    //
    // Later:
    //
    // Recent
    // Popular
    // Nearby
    // Experiences
    // Posts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------
      appBar: AppBar(
        automaticallyImplyLeading: false,

        title: const Text(
          'De-Fame',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Search coming later.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.search,
            ),
          ),

          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Notifications coming later.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      // ------------------------------------------------------------
      // BODY
      // ------------------------------------------------------------
      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------
            // FILTERS
            // ------------------------------------------------------
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection:
                Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  _FilterButton(
                    label: 'Recent',
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
                    label: 'Popular',
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
                    label: 'Nearby',
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
                    label: 'Experiences',
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
                    label: 'Posts',
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

            const Divider(height: 1),

            // ------------------------------------------------------
            // LOADING
            // ------------------------------------------------------
            if (_isLoadingExperiences)
              const Expanded(
                child: Center(
                  child:
                  CircularProgressIndicator(),
                ),
              )

            // ------------------------------------------------------
            // ERROR
            // ------------------------------------------------------
            else if (_feedError != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding:
                    const EdgeInsets.all(
                      28,
                    ),
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        Text(
                          _feedError!,
                          textAlign:
                          TextAlign.center,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        FilledButton(
                          onPressed:
                          _loadExperiences,
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

            // ------------------------------------------------------
            // EMPTY FEED
            // ------------------------------------------------------
            else if (_experiences.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        28,
                      ),
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .auto_stories_outlined,
                            size: 64,
                            color: AppTheme
                                .primaryPurple
                                .withValues(
                              alpha: 0.75,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          const Text(
                            'No Experiences yet',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            'Be the first to share something.',
                            textAlign:
                            TextAlign.center,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          FilledButton.icon(
                            onPressed:
                            _openExperienceCreator,
                            icon: const Icon(
                              Icons.add,
                            ),
                            label:
                            const Text(
                              'Share Experience',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // ------------------------------------------------------
              // REAL FEED
              // ------------------------------------------------------
              else ...[
                  // ----------------------------------------------------
                  // SWIPE INFORMATION
                  // ----------------------------------------------------
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      18,
                      10,
                      18,
                      6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Swipe left or right',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),

                        const Spacer(),

                        Text(
                          '${_currentPostIndex + 1} / ${_experiences.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w700,
                            color: Theme.of(context)
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

                  // ----------------------------------------------------
                  // HORIZONTAL REAL EXPERIENCE FEED
                  // ----------------------------------------------------
                  Expanded(
                    child: PageView.builder(
                      controller:
                      _pageController,

                      scrollDirection:
                      Axis.horizontal,

                      itemCount:
                      _experiences.length,

                      onPageChanged:
                          (index) {
                        setState(() {
                          _currentPostIndex =
                              index;
                        });
                      },

                      itemBuilder:
                          (context, index) {
                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            right: 8,
                            bottom: 12,
                          ),
                          child:
                          ExperienceFeedCard(
                            experience:
                            _experiences[
                            index],
                          ),
                        );
                      },
                    ),
                  ),
                ],
          ],
        ),
      ),

      // ------------------------------------------------------------
      // BOTTOM NAVIGATION
      // ------------------------------------------------------------
      bottomNavigationBar:
      NavigationBar(
        selectedIndex:
        _selectedIndex,

        onDestinationSelected:
        _onNavigationTapped,

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.groups_outlined,
            ),
            selectedIcon: Icon(
              Icons.groups,
            ),
            label: 'Community',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.add_circle_outline,
              size: 32,
            ),
            selectedIcon: Icon(
              Icons.add_circle,
              size: 32,
            ),
            label: 'Create',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.favorite_border,
            ),
            selectedIcon: Icon(
              Icons.favorite,
            ),
            label: 'Activity',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =================================================================
// FILTER BUTTON
// =================================================================

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
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        right: 8,
      ),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          onTap();
        },
      ),
    );
  }
}

// =================================================================
// CREATE OPTION
// =================================================================

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
  Widget build(BuildContext context) {
    return Material(
      color:
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha: 0.45,
      ),
      borderRadius:
      BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: Padding(
          padding:
          const EdgeInsets.all(
            18,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                BoxDecoration(
                  color:
                  AppTheme.primaryPurple
                      .withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                  AppTheme.primaryPurple,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
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