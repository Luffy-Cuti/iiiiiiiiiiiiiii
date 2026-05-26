import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../bloc/video_bloc.dart';
import '../bloc/video_event.dart';
import '../bloc/video_state.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';
import '../widgets/video_player_widget.dart';

part 'profile/profile_edit_models.dart';
part 'profile/profile_edit_sheet.dart';
part 'profile/profile_video_viewer.dart';
part 'profile/profile_video_grid.dart';
part 'profile/profile_shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onSignOut, super.key});

  final Future<void> Function() onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF000000);
  static const Color _text = Color(0xFFFFFFFF);
  static const Color _subText = Color(0xFF888888);
  static const Color _accent = Color(0xFFFE2C55);
  static const Color _surface = Color(0xFF151515);
  static const Color _border = Color(0xFF2A2A2A);

  final String following = '512';
  final String followers = '2.3M';
  final String likes = '45.6M';

  late final TabController _tabController;
  String? _editedDisplayName;
  String? _editedBio;

  User? get _user => FirebaseAuth.instance.currentUser;

  String get username {
    final email = _user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final localPart = email.split('@').first;
      return '@$localPart';
    }
    return '@user';
  }

  String get displayName {
    final editedName = _editedDisplayName?.trim();
    if (editedName != null && editedName.isNotEmpty) {
      return editedName;
    }

    final name = _user?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return _user?.email?.trim() ?? 'User';
  }

  String get bio {
    final editedBio = _editedBio?.trim();
    if (editedBio != null && editedBio.isNotEmpty) {
      return editedBio;
    }

    final email = _user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return 'Email: $email';
    }
    return 'Hoan thien ho so de moi nguoi de nhan dien ban.';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _copyUsername() async {
    await Clipboard.setData(ClipboardData(text: username));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Da copy username')));
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width * 0.04;

    return SafeArea(
      child: Scaffold(
        backgroundColor: _bg,
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                backgroundColor: _bg,
                elevation: 0,
                leading: IconButton(
                  tooltip: 'Add friends',
                  onPressed: () => _showComingSoon('Add friends'),
                  icon: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: _text,
                  ),
                ),
                centerTitle: true,
                title: GestureDetector(
                  onTap: _copyUsername,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: _text,
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Menu',
                    onPressed: _showProfileMenu,
                    icon: const Icon(Icons.menu, color: _text),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildAvatar(),
                      const SizedBox(height: 13),
                      Text(
                        username,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _subText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildStats(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 14),
                      Text(
                        bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProfileLink(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(color: _text, width: 2),
                    ),
                    dividerColor: _border,
                    labelColor: _text,
                    unselectedLabelColor: _subText,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on, size: 23)),
                      Tab(icon: Icon(Icons.lock_outline, size: 22)),
                      Tab(icon: Icon(Icons.bookmark_border, size: 23)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildVideoGrid(),
              _emptyTab(
                icon: Icons.lock_outline,
                title: 'Private videos',
                subtitle: 'Only you can view these videos.',
              ),
              _emptyTab(
                icon: Icons.bookmark_border,
                title: 'Favorites',
                subtitle: 'Videos you save will show up here.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final photoUrl = _user?.photoURL;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _showComingSoon('Avatar preview'),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 1.4),
              gradient: hasPhoto
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF202020), Color(0xFF3A3A3A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              image: hasPhoto
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasPhoto
                ? null
                : const Icon(Icons.person, color: _text, size: 44),
          ),
        ),
        Positioned(
          right: 34,
          bottom: -6,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
              border: Border.all(color: _bg, width: 2),
            ),
            child: const Icon(Icons.add, color: _text, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatItem(value: following, label: 'Following'),
        ),
        _divider(),
        Expanded(
          child: _StatItem(value: followers, label: 'Followers'),
        ),
        _divider(),
        Expanded(
          child: _StatItem(value: likes, label: 'Likes'),
        ),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: _border);

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _profileButton(
            label: 'Edit profile',
            onTap: _showEditProfileSheet,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _profileButton(
            label: 'Share profile',
            onTap: () => _showComingSoon('Share profile'),
          ),
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 44,
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _border),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Add link',
              onPressed: () => _showComingSoon('Add link'),
              icon: const Icon(
                Icons.person_add_alt_1_outlined,
                color: _text,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: _text,
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: _border),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildProfileLink() {
    return GestureDetector(
      onTap: _copyUsername,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.link, color: _text, size: 15),
          SizedBox(width: 4),
          Text(
            'tiktok.com/profile',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileSheet() async {
    final draft = await _showProfileEditSheet(
      context: context,
      displayName: displayName,
      bio: bio,
      username: username,
      photoUrl: _user?.photoURL,
      onChangePhoto: () => _showComingSoon('Change photo'),
    );
    if (draft == null || !mounted) return;

    final result = await _saveProfileChanges(
      name: draft.name,
      bioText: draft.bio,
    );
    if (!mounted) return;
    _showSnackBar(result.message);
  }

  Future<_ProfileSaveResult> _saveProfileChanges({
    required String name,
    required String bioText,
  }) async {
    final trimmedName = name.trim();
    final trimmedBio = bioText.trim();

    if (trimmedName.isEmpty) {
      return const _ProfileSaveResult(
        saved: false,
        message: 'Name cannot be empty',
      );
    }

    setState(() {
      _editedDisplayName = trimmedName;
      _editedBio = trimmedBio.isEmpty
          ? 'Hoan thien ho so de moi nguoi de nhan dien ban.'
          : trimmedBio;
    });

    final user = _user;
    if (user == null || user.displayName?.trim() == trimmedName) {
      return const _ProfileSaveResult(saved: true, message: 'Profile updated');
    }

    try {
      await user.updateDisplayName(trimmedName);
      await user.reload();
      return const _ProfileSaveResult(saved: true, message: 'Profile updated');
    } catch (_) {
      return const _ProfileSaveResult(
        saved: true,
        message: 'Saved locally. Could not sync name.',
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  void _showProfileMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuItem(
                icon: Icons.settings_outlined,
                label: 'Settings and privacy',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('Settings');
                },
              ),
              _menuItem(
                icon: Icons.qr_code_2,
                label: 'QR code',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('QR code');
                },
              ),
              _menuItem(
                icon: Icons.logout,
                label: 'Sign out',
                onTap: () {
                  Navigator.pop(context);
                  widget.onSignOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _text),
      title: Text(
        label,
        style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  Widget _buildVideoGrid() {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        if (state is VideoLoaded && state.videos.isNotEmpty) {
          final videos = state.videos.take(18).toList();
          return _ProfileVideoGrid(
            videos: videos,
            onTap: (index) => _openProfileVideoViewer(videos, index),
          );
        }

        if (state is VideoError) {
          return _VideoGridMessage(
            message: 'Could not load profile videos.',
            actionLabel: 'Retry',
            onAction: () => context.read<VideoBloc>().add(const FetchVideos()),
          );
        }

        return const _ProfileVideoSkeletonGrid();
      },
    );
  }

  void _openProfileVideoViewer(List<VideoModel> videos, int initialIndex) {
    if (videos.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileVideoViewerScreen(
          initialVideos: videos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _emptyTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _text, size: 46),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _subText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
