import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/login_bloc.dart';
import '../../auth/repository/firebase_auth_repository.dart';
import '../../auth/services/auth_local_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import '../../auth/view/login_page.dart';

import '../../search/bloc/search_page.dart';
import '../../upload/view/upload_video_page.dart';

import '../../upload/bloc/upload_bloc.dart';
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
  bool _isForYouTab = true;

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
    final candidates = <int>{
      if (activeIndex - 1 >= 0) activeIndex - 1,
      activeIndex,
      if (activeIndex + 1 < state.videos.length) activeIndex + 1,
    };

    for (final index in candidates) {
      void _debugLog(String message) {
        if (kDebugMode) {
          debugPrint(message);
        }
      }
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
      final file = await DefaultCacheManager().getSingleFile(videoUrl);
      final controller = VideoPlayerController.file(file);
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

  void _onNavTap(int index) {
    setState(() => _bottomIndex = index);
  }

  Future<void> _handleSignOut() async {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFeedTabChip(
                        label: 'Following',
                        isActive: !_isForYouTab,
                        onTap: () => setState(() => _isForYouTab = false),
                      ),
                      _buildFeedTabChip(
                        label: 'For You',
                        isActive: _isForYouTab,
                        onTap: () => setState(() => _isForYouTab = true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.search, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTabChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white12, width: .5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: _onNavTap,
        backgroundColor: Colors.black,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedFontSize: 11,
        unselectedFontSize: 11,
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
      ),
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

class _SimpleTabPage extends StatelessWidget {
  const _SimpleTabPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
