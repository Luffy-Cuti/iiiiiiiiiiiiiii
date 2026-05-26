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
    final nameController = TextEditingController(text: displayName);
    final bioController = TextEditingController(text: bio);
    String? nameError;
    _ProfileEditDraft? draft;

    try {
      draft = await showModalBottomSheet<_ProfileEditDraft>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: _bg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

              void submit() {
                final trimmedName = nameController.text.trim();
                if (trimmedName.isEmpty) {
                  setSheetState(() => nameError = 'Name cannot be empty');
                  return;
                }

                Navigator.pop(
                  sheetContext,
                  _ProfileEditDraft(
                    name: trimmedName,
                    bio: bioController.text.trim(),
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close, color: _text),
                          ),
                          const Expanded(
                            child: Text(
                              'Edit profile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _text,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: submit,
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEditableAvatar(),
                      const SizedBox(height: 24),
                      _EditProfileField(
                        controller: nameController,
                        label: 'Name',
                        maxLength: 30,
                        errorText: nameError,
                        onChanged: (_) {
                          if (nameError == null) return;
                          setSheetState(() => nameError = null);
                        },
                      ),
                      const SizedBox(height: 14),
                      _ReadonlyProfileField(label: 'Username', value: username),
                      const SizedBox(height: 14),
                      _EditProfileField(
                        controller: bioController,
                        label: 'Bio',
                        maxLines: 3,
                        maxLength: 80,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      bioController.dispose();
    }

    if (draft == null || !mounted) return;
    final result = await _saveProfileChanges(
      name: draft.name,
      bioText: draft.bio,
    );
    if (!mounted) return;
    _showSnackBar(result.message);
  }

  Widget _buildEditableAvatar() {
    final photoUrl = _user?.photoURL;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showComingSoon('Change photo'),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: _surface,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                child: hasPhoto
                    ? null
                    : const Icon(Icons.person, color: _text, size: 42),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: _text, size: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Change photo',
          style: TextStyle(
            color: _text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
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

class _ProfileSaveResult {
  const _ProfileSaveResult({required this.saved, required this.message});

  final bool saved;
  final String message;
}

class _ProfileEditDraft {
  const _ProfileEditDraft({required this.name, required this.bio});

  final String name;
  final String bio;
}

class _ProfileVideoViewerScreen extends StatefulWidget {
  const _ProfileVideoViewerScreen({
    required this.initialVideos,
    required this.initialIndex,
  });

  final List<VideoModel> initialVideos;
  final int initialIndex;

  @override
  State<_ProfileVideoViewerScreen> createState() =>
      _ProfileVideoViewerScreenState();
}

class _ProfileVideoViewerScreenState extends State<_ProfileVideoViewerScreen> {
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<int> _loadingIndexes = {};
  late final PageController _pageController;
  late List<VideoModel> _videos;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _videos = List<VideoModel>.of(widget.initialVideos);
    _currentIndex = _videos.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _videos.length - 1).toInt();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prepareVideoWindow(_currentIndex);
    });
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _prepareVideoWindow(int activeIndex) async {
    if (_videos.isEmpty) return;

    final candidates = <int>{
      if (activeIndex - 1 >= 0) activeIndex - 1,
      activeIndex,
      if (activeIndex + 1 < _videos.length) activeIndex + 1,
    };

    for (final index in candidates) {
      await _initializeController(index, shouldPlay: index == activeIndex);
    }

    final toDispose = _videoControllers.keys
        .where((index) => !candidates.contains(index))
        .toList();
    for (final index in toDispose) {
      await _videoControllers.remove(index)?.dispose();
    }
  }

  Future<void> _initializeController(
    int index, {
    required bool shouldPlay,
  }) async {
    final existing = _videoControllers[index];
    if (existing != null) {
      if (shouldPlay) {
        await existing.play();
      } else {
        await existing.pause();
      }
      return;
    }
    if (_loadingIndexes.contains(index)) return;

    _loadingIndexes.add(index);
    try {
      final controller = await _createVideoController(_videos[index].videoUrl);
      await controller.initialize();
      controller.setLooping(true);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _videoControllers[index] = controller;
      if (shouldPlay) {
        await controller.play();
      } else {
        await controller.pause();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    } finally {
      _loadingIndexes.remove(index);
    }
  }

  Future<VideoPlayerController> _createVideoController(String videoUrl) async {
    final trimmedUrl = videoUrl.trim();
    final uri = Uri.tryParse(trimmedUrl);

    if (trimmedUrl.startsWith('assets/')) {
      return VideoPlayerController.asset(trimmedUrl);
    }

    if (uri != null && uri.scheme == 'file') {
      return VideoPlayerController.file(File.fromUri(uri));
    }

    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return VideoPlayerController.file(File(trimmedUrl));
    }

    final file = await DefaultCacheManager().getSingleFile(trimmedUrl);
    return VideoPlayerController.file(file);
  }

  void _toggleLike(String videoId) {
    final index = _videos.indexWhere((video) => video.id == videoId);
    if (index == -1) return;

    final video = _videos[index];
    final liked = !video.isLiked;
    setState(() {
      _videos[index] = video.copyWith(
        isLiked: liked,
        likeCount: liked
            ? video.likeCount + 1
            : (video.likeCount > 0 ? video.likeCount - 1 : 0),
      );
    });
    context.read<VideoBloc>().add(LikeVideo(videoId));
  }

  void _toggleFollow(String channelId) {
    final channelIndex = _videos.indexWhere(
      (video) => video.channel.id == channelId,
    );
    if (channelIndex == -1) return;

    final followed = !_videos[channelIndex].isFollowed;
    setState(() {
      _videos = [
        for (final video in _videos)
          if (video.channel.id == channelId)
            video.copyWith(
              isFollowed: followed,
              channel: video.channel.copyWith(isFollowed: followed),
            )
          else
            video,
      ];
    });
    context.read<VideoBloc>().add(FollowChannel(channelId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _prepareVideoWindow(index);
            },
            itemBuilder: (context, index) {
              final video = _videos[index];
              return VideoPlayerWidget(
                key: ValueKey(
                  'profile-video-${video.id}-${video.isLiked}-${video.isFollowed}',
                ),
                video: video,
                videoController: _videoControllers[index],
                isActive: index == _currentIndex,
                onLike: () => _toggleLike(video.id),
                onFollow: () => _toggleFollow(video.channel.id),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Profile videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(blurRadius: 2)],
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
}

class _ProfileVideoGrid extends StatelessWidget {
  const _ProfileVideoGrid({required this.videos, required this.onTap});

  final List<VideoModel> videos;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: videos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 9 / 16,
      ),
      itemBuilder: (context, index) {
        return _ProfileVideoTile(
          video: videos[index],
          index: index,
          onTap: () => onTap(index),
        );
      },
    );
  }
}

class _ProfileVideoTile extends StatelessWidget {
  const _ProfileVideoTile({
    required this.video,
    required this.index,
    required this.onTap,
  });

  final VideoModel video;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPinned = index < 3;
    final isLive = index % 5 == 0;

    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ProfileVideoThumbnail(video: video, index: index),
          const _ProfileVideoOverlay(),
          if (isPinned)
            const Positioned(
              left: 6,
              top: 6,
              child: _ProfileVideoBadge(label: 'Pinned'),
            ),
          if (isLive)
            const Positioned(
              right: 6,
              top: 6,
              child: _ProfileVideoBadge(
                label: 'LIVE',
                color: Color(0xFFFE2C55),
              ),
            ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Row(
              children: [
                const Icon(
                  Icons.play_arrow,
                  color: Color(0xFFFFFFFF),
                  size: 14,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    _compactCount(video.likeCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileVideoThumbnail extends StatelessWidget {
  const _ProfileVideoThumbnail({required this.video, required this.index});

  final VideoModel video;
  final int index;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = video.thumbnailUrl.trim();

    if (_isNetworkUrl(thumbnailUrl)) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            _ProfileVideoFallback(video: video, index: index),
        errorWidget: (context, url, error) =>
            _ProfileVideoFallback(video: video, index: index),
      );
    }

    if (thumbnailUrl.startsWith('assets/')) {
      return Image.asset(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _ProfileVideoFallback(video: video, index: index),
      );
    }

    return _ProfileVideoFallback(video: video, index: index);
  }

  bool _isNetworkUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

class _ProfileVideoFallback extends StatelessWidget {
  const _ProfileVideoFallback({required this.video, required this.index});

  final VideoModel video;
  final int index;

  @override
  Widget build(BuildContext context) {
    final description = video.description.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 34, 8, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(
              const Color(0xFF292D45),
              const Color(0xFF6047A8),
              (index % 6) / 6,
            )!,
            Color.lerp(
              const Color(0xFF173A3F),
              const Color(0xFFFE2C55),
              (index % 5) / 7,
            )!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_fill,
            color: Color(0xE6FFFFFF),
            size: 30,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileVideoOverlay extends StatelessWidget {
  const _ProfileVideoOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.06),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.64),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.52, 1],
        ),
      ),
    );
  }
}

class _ProfileVideoBadge extends StatelessWidget {
  const _ProfileVideoBadge({
    required this.label,
    this.color = const Color(0xB8000000),
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ProfileVideoSkeletonGrid extends StatelessWidget {
  const _ProfileVideoSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 9 / 16,
      ),
      itemBuilder: (context, index) {
        return _ProfileVideoFallback(
          index: index,
          video: VideoModel(
            id: 'loading-$index',
            videoUrl: '',
            thumbnailUrl: '',
            description: 'Loading video',
            likeCount: 0,
            commentCount: 0,
            shareCount: 0,
            channel: const ChannelModel(
              id: 'loading',
              username: 'loading',
              avatarUrl: '',
              isFollowed: false,
            ),
            music: '',
            isLiked: false,
            isFollowed: false,
          ),
        );
      },
    );
  }
}

class _VideoGridMessage extends StatelessWidget {
  const _VideoGridMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: Color(0xFFFFFFFF),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFFFFF),
                backgroundColor: const Color(0xFF151515),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${_trimCompact(value / 1000000)}M';
  }
  if (value >= 1000) {
    return '${_trimCompact(value / 1000)}K';
  }
  return '$value';
}

String _trimCompact(double value) {
  final text = value >= 10
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

class _EditProfileField extends StatelessWidget {
  const _EditProfileField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          cursorColor: const Color(0xFFFE2C55),
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            errorText: errorText,
            errorStyle: const TextStyle(
              color: Color(0xFFFE2C55),
              fontWeight: FontWeight.w600,
            ),
            counterStyle: const TextStyle(color: Color(0xFF888888)),
            filled: true,
            fillColor: const Color(0xFF151515),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyProfileField extends StatelessWidget {
  const _ReadonlyProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        border: Border(
          bottom: BorderSide(
            color: overlapsContent
                ? const Color(0xFF222222)
                : Colors.transparent,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}
