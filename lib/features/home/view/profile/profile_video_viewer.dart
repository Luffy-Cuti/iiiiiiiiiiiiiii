part of '../profile_screen.dart';

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
