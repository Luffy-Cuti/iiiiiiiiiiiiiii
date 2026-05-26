part of '../profile_screen.dart';

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
