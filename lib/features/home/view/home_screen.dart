import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../../auth/bloc/login_bloc.dart';
import '../../auth/repository/firebase_auth_repository.dart';
import '../../auth/services/auth_local_storage.dart';
import '../../auth/view/login_page.dart';
import '../../search/bloc/search_page.dart';
import '../../upload/view/upload_video_page.dart';
import '../bloc/video_bloc.dart';
import '../bloc/video_event.dart';
import '../bloc/video_state.dart';
import '../widgets/video_player_widget.dart';
import 'category_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<int> _loadingIndexes = {};
  int _bottomIndex = 0;
  int _currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<VideoBloc>().add(const FetchVideos());
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _prepareVideoWindow(VideoLoaded state, int activeIndex) async {
    _currentVideoIndex = activeIndex;
    if (_bottomIndex != 0) {
      _pauseAllVideos();
      return;
    }

    final candidates = <int>{
      if (activeIndex - 1 >= 0) activeIndex - 1,
      activeIndex,
      if (activeIndex + 1 < state.videos.length) activeIndex + 1,
    };

    for (final index in candidates) {
      await _initializeController(
        state,
        index,
        shouldPlay: index == activeIndex,
      );
    }

    final toDispose = _videoControllers.keys
        .where((index) => !candidates.contains(index))
        .toList();
    for (final index in toDispose) {
      await _videoControllers.remove(index)?.dispose();
    }
  }

  Future<void> _initializeController(
    VideoLoaded state,
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
      final videoUrl = state.videos[index].videoUrl;
      final controller = await _createVideoController(videoUrl);
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
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Prepare video failed: $error\n$stackTrace');
      }
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

    if (_isHlsUrl(uri)) {
      return VideoPlayerController.networkUrl(uri);
    }

    final file = await DefaultCacheManager().getSingleFile(trimmedUrl);
    return VideoPlayerController.file(file);
  }

  bool _isHlsUrl(Uri uri) {
    return uri.path.toLowerCase().endsWith('.m3u8');
  }

  void _onNavTap(int index) {
    if (index != 0) {
      _pauseAllVideos();
    }

    setState(() => _bottomIndex = index);
  }

  void _pauseAllVideos() {
    for (final controller in _videoControllers.values) {
      controller.pause();
    }
  }

  Future<void> _handleSignOut() async {
    _pauseAllVideos();
    await AuthLocalStorage.clearLoginStatus();
    await FirebaseAuthRepository().signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => LoginPage(bloc: LoginBloc())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBodyByTab(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBodyByTab() {
    if (_bottomIndex == 4) {
      return ProfileScreen(onSignOut: _handleSignOut);
    }

    if (_bottomIndex == 1) {
      return const SearchPage();
    }

    if (_bottomIndex == 2) {
      return UploadVideoPage(
        onUploaded: () {
          if (!mounted) return;
          setState(() => _bottomIndex = 0);
        },
      );
    }

    if (_bottomIndex == 3) {
      return const CategoryScreen();
    }

    return Stack(
      children: [
        BlocBuilder<VideoBloc, VideoState>(
          builder: (context, state) {
            if (state is VideoLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is VideoError) {
              return _FeedMessage(
                message: state.message,
                actionLabel: 'Thử lại',
                onAction: () =>
                    context.read<VideoBloc>().add(const FetchVideos()),
              );
            }
            if (state is! VideoLoaded) return const SizedBox.shrink();
            if (state.videos.isEmpty) {
              return _FeedMessage(
                message: 'Chưa có video để hiển thị.',
                actionLabel: 'Tải lại',
                onAction: () =>
                    context.read<VideoBloc>().add(const FetchVideos()),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _prepareVideoWindow(state, _currentVideoIndex);
            });

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: state.videos.length,
              onPageChanged: (index) {
                _prepareVideoWindow(state, index);
                setState(() => _currentVideoIndex = index);
              },
              itemBuilder: (context, index) {
                final video = state.videos[index];
                return VideoPlayerWidget(
                  key: ValueKey(video.id),
                  video: video,
                  videoController: _videoControllers[index],
                  isActive: index == _currentVideoIndex,
                  onLike: () =>
                      context.read<VideoBloc>().add(LikeVideo(video.id)),
                  onFollow: () => context.read<VideoBloc>().add(
                    FollowChannel(video.channel.id),
                  ),
                );
              },
            );
          },
        ),
        _buildTopBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Spacer(),
            Row(
              children: const [
                Text('Following', style: TextStyle(color: Colors.white70)),
                SizedBox(width: 16),
                Text(
                  'For You',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.search, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomNavigationBar(
      currentIndex: _bottomIndex,
      onTap: _onNavTap,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Container(
            width: 34,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent, width: 1.4),
              gradient: const LinearGradient(
                colors: [Colors.cyan, Colors.redAccent],
              ),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          label: 'Upload',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          label: 'Category',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
