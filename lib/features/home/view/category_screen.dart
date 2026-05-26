import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../bloc/video_bloc.dart';
import '../bloc/video_event.dart';
import '../models/category_model.dart';
import '../models/video_model.dart';
import '../repository/video_repository.dart';
import '../widgets/video_player_widget.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, VideoRepository? videoRepository})
    : _videoRepository = videoRepository;

  final VideoRepository? _videoRepository;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final VideoRepository _videoRepository;
  late Future<List<CategoryModel>> _categoriesFuture;
  CategoryModel? _selectedCategory;
  Future<List<VideoModel>>? _videosFuture;

  @override
  void initState() {
    super.initState();
    _videoRepository = widget._videoRepository ?? VideoRepository();
    _categoriesFuture = _videoRepository.fetchCategories();
  }

  Future<void> _reloadCategories() async {
    final categoriesFuture = _videoRepository.fetchCategories();
    setState(() {
      _selectedCategory = null;
      _videosFuture = null;
      _categoriesFuture = categoriesFuture;
    });
    await categoriesFuture;
  }

  void _selectCategory(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
      _videosFuture = _videoRepository.fetchVideosByCategory(
        categoryId: category.id,
      );
    });
  }

  void _openVideoViewer(List<VideoModel> videos, int selectedIndex) {
    final selectedVideo = videos[selectedIndex];
    if (selectedVideo.videoUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API tra ve video nay nhung thieu URL de phat.'),
        ),
      );
      return;
    }

    final playableVideos = videos
        .where((video) => video.videoUrl.trim().isNotEmpty)
        .toList(growable: false);
    final initialIndex = playableVideos.indexWhere(
      (video) => video.id == selectedVideo.id,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CategoryVideoViewerScreen(
          videos: playableVideos,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _reloadCategories,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            FutureBuilder<List<CategoryModel>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: _MessageState(
                      message: 'Không thể tải danh mục video.',
                      actionLabel: 'Thử lại',
                      onAction: () => _reloadCategories(),
                    ),
                  );
                }

                final categories = snapshot.data ?? const <CategoryModel>[];
                if (categories.isEmpty) {
                  return SliverFillRemaining(
                    child: _MessageState(
                      message: 'Chưa có danh mục để hiển thị.',
                      actionLabel: 'Tải lại',
                      onAction: () => _reloadCategories(),
                    ),
                  );
                }

                return SliverList.list(
                  children: [
                    _buildCategoryList(categories),
                    _buildSelectedCategoryVideos(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Chọn danh mục để xem video tương ứng.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    return SizedBox(
      height: 136,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == _selectedCategory?.id;
          return _CategoryCard(
            category: category,
            isSelected: selected,
            onTap: () => _selectCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCategoryVideos() {
    final selectedCategory = _selectedCategory;
    final videosFuture = _videosFuture;

    if (selectedCategory == null || videosFuture == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Hãy chọn một category ở phía trên.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return FutureBuilder<List<VideoModel>>(
      future: videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _MessageState(
            message: 'Không thể tải video của ${selectedCategory.name}.',
            actionLabel: 'Thử lại',
            onAction: () => _selectCategory(selectedCategory),
          );
        }

        final videos = snapshot.data ?? const <VideoModel>[];
        if (videos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Category ${selectedCategory.name} chưa có video.',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedCategory.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: videos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.74,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) => _VideoTile(
                  video: videos[index],
                  onTap: () => _openVideoViewer(videos, index),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 118,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NetworkThumb(
              imageUrl: category.iconImageUrl,
              width: 42,
              height: 42,
              borderRadius: 12,
              fallbackIcon: Icons.category_outlined,
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, required this.onTap});

  final VideoModel video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canPlay = video.videoUrl.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkThumb(
                    imageUrl: video.thumbnailUrl,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                    fallbackIcon: Icons.play_circle_outline,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.58),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      canPlay ? Icons.play_circle_fill : Icons.link_off,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  if (!canPlay)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'No video URL',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                video.description.isEmpty ? 'Video' : video.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryVideoViewerScreen extends StatefulWidget {
  const _CategoryVideoViewerScreen({
    required this.videos,
    required this.initialIndex,
  });

  final List<VideoModel> videos;
  final int initialIndex;

  @override
  State<_CategoryVideoViewerScreen> createState() =>
      _CategoryVideoViewerScreenState();
}

class _CategoryVideoViewerScreenState
    extends State<_CategoryVideoViewerScreen> {
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<int> _loadingIndexes = {};
  late final PageController _pageController;
  late List<VideoModel> _videos;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _videos = List<VideoModel>.of(widget.videos);
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
      if (mounted) setState(() {});
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
                  'category-video-${video.id}-${video.isLiked}-${video.isFollowed}',
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
                    'Category videos',
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

class _NetworkThumb extends StatelessWidget {
  const _NetworkThumb({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.fallbackIcon,
  });

  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Colors.white10,
      child: Icon(fallbackIcon, color: Colors.white54),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, url) => placeholder,
              errorWidget: (context, url, error) => placeholder,
            ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
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
