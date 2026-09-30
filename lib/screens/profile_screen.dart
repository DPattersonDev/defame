import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:defame/theme/app_theme.dart';
import 'package:defame/screens/home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  bool _isLoading = true;

  String? _errorMessage;

  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // ----------------------------------------------------------------
  // LOAD PROFILE
  // ----------------------------------------------------------------
  Future<void> _loadProfile() async {
    final User? user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
        'No signed-in user was found.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
      await Supabase.instance.client
          .from('profiles')
          .select(
        '''
                id,
                username,
                display_name,
                bio,
                avatar_url,
                default_avatar,
                age_verified,
                created_at
                ''',
      )
          .eq(
        'id',
        user.id,
      )
          .maybeSingle();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = response;
        _isLoading = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Something went wrong while loading your profile.';
      });
    }
  }

  // ----------------------------------------------------------------
  // SIGN OUT
  // ----------------------------------------------------------------
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(),
        ),
            (route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not sign out. Please try again.',
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------------
  // DEFAULT AVATAR ICON
  // ----------------------------------------------------------------
  //
  // Temporary placeholders.
  //
  // Later we can replace these with the
  // custom De-Fame avatar images.
  // ----------------------------------------------------------------
  IconData _defaultAvatarIcon(
      int avatarNumber,
      ) {
    switch (avatarNumber) {
      case 1:
        return Icons.face;

      case 2:
        return Icons.face_2;

      case 3:
        return Icons.face_3;

      case 4:
        return Icons.face_4;

      case 5:
        return Icons.face_5;

      case 6:
        return Icons.face_6;

      case 7:
        return Icons.sentiment_satisfied_alt;

      case 8:
        return Icons.person;

      default:
        return Icons.person;
    }
  }

  // ----------------------------------------------------------------
  // PROFILE AVATAR
  // ----------------------------------------------------------------
  Widget _buildAvatar() {
    final String? avatarUrl =
    _profile?['avatar_url']?.toString();

    final int defaultAvatar =
        int.tryParse(
          _profile?['default_avatar']
              ?.toString() ??
              '1',
        ) ??
            1;

    // --------------------------------------------------------------
    // CUSTOM UPLOADED PHOTO
    // --------------------------------------------------------------
    if (avatarUrl != null &&
        avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundColor:
        AppTheme.primaryPurple.withValues(
          alpha: 0.15,
        ),
        backgroundImage:
        NetworkImage(
          avatarUrl,
        ),
      );
    }

    // --------------------------------------------------------------
    // DEFAULT DE-FAME AVATAR
    // --------------------------------------------------------------
    return CircleAvatar(
      radius: 55,
      backgroundColor:
      AppTheme.primaryPurple.withValues(
        alpha: 0.15,
      ),
      child: Icon(
        _defaultAvatarIcon(
          defaultAvatar,
        ),
        size: 60,
        color:
        AppTheme.primaryPurple,
      ),
    );
  }

  // ----------------------------------------------------------------
  // EDIT PROFILE PLACEHOLDER
  // ----------------------------------------------------------------
  void _openEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Edit Profile is coming next.',
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // SETTINGS PLACEHOLDER
  // ----------------------------------------------------------------
  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Settings is coming next.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight:
            FontWeight.w900,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh:
        _loadProfile,
        child:
        _buildBody(),
      ),
    );
  }

  // ----------------------------------------------------------------
  // PROFILE BODY
  // ----------------------------------------------------------------
  Widget _buildBody() {
    // --------------------------------------------------------------
    // LOADING
    // --------------------------------------------------------------
    if (_isLoading) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 300,
          ),

          Center(
            child:
            CircularProgressIndicator(),
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // ERROR
    // --------------------------------------------------------------
    if (_errorMessage != null) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(
          24,
        ),
        children: [
          const SizedBox(
            height: 120,
          ),

          const Icon(
            Icons.error_outline,
            size: 56,
            color: Colors.red,
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            _errorMessage!,
            textAlign:
            TextAlign.center,
          ),

          const SizedBox(
            height: 20,
          ),

          FilledButton(
            onPressed:
            _loadProfile,
            child:
            const Text(
              'Try Again',
            ),
          ),
        ],
      );
    }

    // --------------------------------------------------------------
    // PROFILE VALUES
    // --------------------------------------------------------------
    final String username =
        _profile?['username']
            ?.toString()
            .trim() ??
            '';

    final String displayName =
        _profile?['display_name']
            ?.toString()
            .trim() ??
            '';

    final String bio =
        _profile?['bio']
            ?.toString()
            .trim() ??
            '';

    final String shownDisplayName =
    displayName.isNotEmpty
        ? displayName
        : username.isNotEmpty
        ? username
        : 'De-Fame User';

    final String shownUsername =
    username.isNotEmpty
        ? '@$username'
        : '@username';

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        40,
      ),
      children: [
        // ----------------------------------------------------------
        // AVATAR
        // ----------------------------------------------------------
        Center(
          child:
          _buildAvatar(),
        ),

        const SizedBox(
          height: 18,
        ),

        // ----------------------------------------------------------
        // DISPLAY NAME
        // ----------------------------------------------------------
        Text(
          shownDisplayName,
          textAlign:
          TextAlign.center,
          style:
          const TextStyle(
            fontSize: 26,
            fontWeight:
            FontWeight.w900,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        // ----------------------------------------------------------
        // USERNAME
        // ----------------------------------------------------------
        Text(
          shownUsername,
          textAlign:
          TextAlign.center,
          style: TextStyle(
            fontSize: 15,
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

        const SizedBox(
          height: 14,
        ),

        // ----------------------------------------------------------
        // BIO
        // ----------------------------------------------------------
        Text(
          bio.isNotEmpty
              ? bio
              : 'No bio yet.',
          textAlign:
          TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color:
            Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(
              alpha:
              bio.isNotEmpty
                  ? 0.8
                  : 0.45,
            ),
          ),
        ),

        const SizedBox(
          height: 24,
        ),

        // ----------------------------------------------------------
        // EDIT PROFILE
        // ----------------------------------------------------------
        SizedBox(
          width:
          double.infinity,
          child:
          FilledButton.icon(
            onPressed:
            _openEditProfile,
            style:
            FilledButton.styleFrom(
              backgroundColor:
              AppTheme.primaryPurple,
              foregroundColor:
              Colors.white,
              padding:
              const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
            icon:
            const Icon(
              Icons.edit_outlined,
            ),
            label:
            const Text(
              'Edit Profile',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 28,
        ),

        const Divider(),

        const SizedBox(
          height: 10,
        ),

        // ----------------------------------------------------------
        // PROFILE CONTENT COUNTS
        // ----------------------------------------------------------
        const Row(
          children: [
            Expanded(
              child:
              _ProfileStat(
                number: '0',
                label: 'Experiences',
              ),
            ),

            Expanded(
              child:
              _ProfileStat(
                number: '0',
                label: 'Posts',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 24,
        ),

        const Divider(),

        const SizedBox(
          height: 10,
        ),

        // ----------------------------------------------------------
        // SETTINGS
        // ----------------------------------------------------------
        ListTile(
          contentPadding:
          EdgeInsets.zero,
          leading:
          const Icon(
            Icons.settings_outlined,
          ),
          title:
          const Text(
            'Settings',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          trailing:
          const Icon(
            Icons.chevron_right,
          ),
          onTap:
          _openSettings,
        ),

        // ----------------------------------------------------------
        // SIGN OUT
        // ----------------------------------------------------------
        ListTile(
          contentPadding:
          EdgeInsets.zero,
          leading:
          const Icon(
            Icons.logout,
            color: Colors.red,
          ),
          title:
          const Text(
            'Sign Out',
            style:
            TextStyle(
              color: Colors.red,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          onTap:
          _signOut,
        ),
      ],
    );
  }
}

// ==================================================================
// PROFILE STAT
// ==================================================================
class _ProfileStat extends StatelessWidget {
  final String number;
  final String label;

  const _ProfileStat({
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style:
          const TextStyle(
            fontSize: 22,
            fontWeight:
            FontWeight.w900,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          label,
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
      ],
    );
  }
}