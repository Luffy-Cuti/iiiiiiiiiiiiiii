import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/models/channel_model.dart';
import '../../home/models/video_model.dart';
import '../../home/repository/video_repository.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBloc(videoRepository: VideoRepository()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<SearchBloc>().add(SearchQueryChanged(value));
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    context.read<SearchBloc>().add(const SearchCleared());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchBloc, SearchState>(
      listenWhen: (previous, current) =>
      previous.message != current.message && current.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message!)),
        );
      },
      child: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _SearchHeader(
                controller: _controller,
                onChanged: _onSearchTextChanged,
                onSubmitted: (value) {
                  _debounce?.cancel();
                  context.read<SearchBloc>().add(SearchQueryChanged(value));
                },
                onClear: _clearSearch,
              ),
              const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'Video'),
                  Tab(text: 'Channel'),
                ],
              ),
              Expanded(
                child: BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    if (!state.hasQuery) {
                      return const _EmptySearchHint();
                    }

                    if (state.status == SearchStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == SearchStatus.failure) {
                      return _SearchError(
                        message: state.message ??
                            'Không thể tìm kiếm. Vui lòng thử lại.',
                        onRetry: () => context
                            .read<SearchBloc>()
                            .add(SearchQueryChanged(_controller.text)),
                      );
                    }

                    return TabBarView(
                      children: [
                        _VideoResults(videos: state.videos),
                        _ChannelResults(channels: state.channels),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: 'Tìm video hoặc channel',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              );
            },
          ),
          filled: true,
          fillColor: const Color(0xFF1F1F1F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _VideoResults extends StatelessWidget {
  const _VideoResults({required this.videos});

  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const _NoResults(message: 'Chưa tìm thấy video phù hợp.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _VideoResultCard(video: videos[index]),
    );
  }
}

class _VideoResultCard extends StatelessWidget {
  const _VideoResultCard({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showVideoInfo(context, video),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 132,
                child: _NetworkImageOrFallback(
                  imageUrl: video.thumbnailUrl,
                  icon: Icons.play_arrow,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.description.isEmpty ? 'Video không có mô tả' : video.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Avatar(channel: video.channel, radius: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '@${video.channel.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _StatChip(icon: Icons.favorite, value: video.likeCount),
                      _StatChip(icon: Icons.chat_bubble, value: video.commentCount),
                      _StatChip(icon: Icons.share, value: video.shareCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoInfo(BuildContext context, VideoModel video) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.description.isEmpty ? 'Chi tiết video' : video.description,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('@${video.channel.username}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(icon: Icons.favorite, value: video.likeCount),
                _StatChip(icon: Icons.chat_bubble, value: video.commentCount),
                _StatChip(icon: Icons.share, value: video.shareCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelResults extends StatelessWidget {
  const _ChannelResults({required this.channels});

  final List<ChannelModel> channels;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const _NoResults(message: 'Chưa tìm thấy channel phù hợp.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ChannelResultTile(
        channel: channels[index],
        onFollow: () => context
            .read<SearchBloc>()
            .add(SearchChannelFollowToggled(channels[index].id)),
      ),
    );
  }
}

class _ChannelResultTile extends StatelessWidget {
  const _ChannelResultTile({required this.channel, required this.onFollow});

  final ChannelModel channel;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Avatar(channel: channel, radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${channel.id.isEmpty ? 'N/A' : channel.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onFollow,
            style: OutlinedButton.styleFrom(
              foregroundColor: channel.isFollowed ? Colors.white : Colors.redAccent,
              side: BorderSide(
                color: channel.isFollowed ? Colors.white54 : Colors.redAccent,
              ),
            ),
            child: Text(channel.isFollowed ? 'Đã follow' : 'Follow'),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.channel, required this.radius});

  final ChannelModel channel;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (channel.avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white12,
        child: Icon(Icons.person, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: CachedNetworkImageProvider(channel.avatarUrl),
      backgroundColor: Colors.white12,
    );
  }
}

class _NetworkImageOrFallback extends StatelessWidget {
  const _NetworkImageOrFallback({required this.imageUrl, required this.icon});

  final String imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _ImageFallback(icon: icon);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => _ImageFallback(icon: icon),
      errorWidget: (_, __, ___) => _ImageFallback(icon: icon),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white10,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white70, size: 34),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text('$value', style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _EmptySearchHint extends StatelessWidget {
  const _EmptySearchHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search, size: 56, color: Colors.white38),
            SizedBox(height: 12),
            Text(
              'Nhập từ khóa để tìm video và channel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}