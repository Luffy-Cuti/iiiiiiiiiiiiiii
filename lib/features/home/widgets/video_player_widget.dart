import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/video_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.videoController,
    required this.isActive,
    required this.onLike,
    required this.onFollow,
  });

  final VideoModel video;
  final VoidCallback onLike;
  final VideoPlayerController? videoController;
  final bool isActive;
  final VoidCallback onFollow;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with TickerProviderStateMixin {
  ChewieController? _chewieController;
  late final AnimationController _discController;
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  bool _showCenterHeart = false;
  bool _expandedDesc = false;

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _heartScale = CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    );
    _syncChewieController();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoController != widget.videoController ||
        oldWidget.isActive != widget.isActive) {
      _syncChewieController();
    }
  }

  void _disposeChewie() {
    _chewieController?.dispose();

    _chewieController = null;
  }

  void _syncChewieController() {
    final controller = widget.videoController;
    if (controller == null || !controller.value.isInitialized) {
      _disposeChewie();
      if (mounted) setState(() {});
      return;
    }

    final current = _chewieController;
    if (current?.videoPlayerController != controller) {
      _disposeChewie();
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: true,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
      );
    }

    if (widget.isActive) {
      controller.play();
    } else {
      controller.pause();
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _disposeChewie();
    _discController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _handleDoubleTap() async {
    widget.onLike();
    setState(() => _showCenterHeart = true);
    await _heartController.forward(from: 0);
    if (mounted) setState(() => _showCenterHeart = false);
  }

  void _togglePlay() {
    final controller = widget.videoController;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewieController;
    final bottomOffset = MediaQuery.paddingOf(context).bottom + 16;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlay,
          onDoubleTap: _handleDoubleTap,
          child: chewie == null
              ? _VideoPreview(video: widget.video)
              : IgnorePointer(child: Chewie(controller: chewie)),
        ),
        IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [0.55, 1],
              ),
            ),
          ),
        ),
        if (_showCenterHeart)
          Center(
            child: ScaleTransition(
              scale: _heartScale,
              child: const Icon(Icons.favorite, color: Colors.white, size: 110),
            ),
          ),
        Positioned(
          right: 12,
          bottom: bottomOffset,
          child: _RightActions(
            video: widget.video,
            onLike: widget.onLike,
            onFollow: widget.onFollow,
            discController: _discController,
          ),
        ),
        Positioned(
          left: 14,
          right: 90,
          bottom: bottomOffset,
          child: _BottomMeta(
            video: widget.video,
            expandedDesc: _expandedDesc,
            onToggleDesc: () {
              setState(() => _expandedDesc = !_expandedDesc);
            },
          ),
        ),
      ],
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = video.thumbnailUrl.trim();

    if (_isNetworkUrl(thumbnailUrl)) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => const _LoadingPreview(),
      );
    }

    return const _LoadingPreview();
  }
}

class _LoadingPreview extends StatelessWidget {
  const _LoadingPreview();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class _RightActions extends StatelessWidget {
  const _RightActions({
    required this.video,
    required this.onLike,
    required this.onFollow,
    required this.discController,
  });

  final VideoModel video;
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final AnimationController discController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            _ChannelAvatar(avatarUrl: video.channel.avatarUrl, radius: 24),
            Positioned(
              bottom: -8,
              child: GestureDetector(
                onTap: onFollow,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: video.isFollowed ? Colors.green : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    video.isFollowed ? Icons.check : Icons.add,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ActionButton(
          icon: Icons.favorite,
          label: '${video.likeCount}',
          color: video.isLiked ? Colors.red : Colors.white,
          onTap: onLike,
          animate: video.isLiked,
        ),
        _ActionButton(
          icon: Icons.chat_bubble,
          label: '${video.commentCount}',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.share,
          label: '${video.shareCount}',
          onTap: () {},
        ),
        const SizedBox(height: 14),
        RotationTransition(
          turns: discController,
          child: _ChannelAvatar(
            avatarUrl: video.channel.avatarUrl,
            radius: 22,
            hasBorder: true,
          ),
        ),
      ],
    );
  }
}

class _ChannelAvatar extends StatelessWidget {
  const _ChannelAvatar({
    required this.avatarUrl,
    required this.radius,
    this.hasBorder = false,
  });

  final String avatarUrl;
  final double radius;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl.trim();
    final imageProvider = _isNetworkUrl(url)
        ? CachedNetworkImageProvider(url)
        : null;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasBorder ? Border.all(color: Colors.white54) : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(Icons.person, size: radius, color: Colors.white)
            : null,
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.animate = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool animate;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

bool _isNetworkUrl(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.8,
      upperBound: 1.2,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _ActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate && widget.animate) {
      _controller
        ..forward()
        ..reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            ScaleTransition(
              scale: _controller,
              child: Icon(widget.icon, color: widget.color, size: 34),
            ),
            Text(widget.label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BottomMeta extends StatelessWidget {
  const _BottomMeta({
    required this.video,
    required this.expandedDesc,
    required this.onToggleDesc,
  });

  final VideoModel video;
  final bool expandedDesc;
  final VoidCallback onToggleDesc;

  @override
  Widget build(BuildContext context) {
    final title = video.description.trim().isNotEmpty
        ? video.description.trim()
        : 'Video';
    final showMore = title.length > 80;
    final titleStyle = const TextStyle(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w700,
      shadows: [Shadow(blurRadius: 2)],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '@${video.channel.username}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2)],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onToggleDesc,
          child: Text(
            expandedDesc ? title : _truncate(title),
            maxLines: expandedDesc ? 5 : 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        if (showMore)
          GestureDetector(
            onTap: onToggleDesc,
            child: Text(
              expandedDesc ? 'Thu gọn' : 'xem thêm',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(height: 18, child: _MarqueeMusic(text: '♪ ${video.music}')),
      ],
    );
  }

  String _truncate(String text) {
    if (text.length <= 80) return text;
    return '${text.substring(0, 80)}...';
  }
}

class _MarqueeMusic extends StatefulWidget {
  const _MarqueeMusic({required this.text});

  final String text;

  @override
  State<_MarqueeMusic> createState() => _MarqueeMusicState();
}

class _MarqueeMusicState extends State<_MarqueeMusic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final dx = (1 - _controller.value * 2) * constraints.maxWidth;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontSize: 12,
              shadows: [Shadow(blurRadius: 2)],
            ),
          ),
        );
      },
    );
  }
}
