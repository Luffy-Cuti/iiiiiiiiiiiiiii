import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/channel_model.dart';
import '../models/video_model.dart';
import 'video_event.dart';
import 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc() : super(const VideoLoading()) {
    on<FetchVideos>(_onFetchVideos);
    on<LikeVideo>(_onLikeVideo);
    on<FollowChannel>(_onFollowChannel);
  }

  Future<void> _onFetchVideos(FetchVideos event, Emitter<VideoState> emit) async {
    emit(const VideoLoading());
    await Future<void>.delayed(const Duration(milliseconds: 250));
    emit(VideoLoaded(_mockVideos));
  }

  void _onLikeVideo(LikeVideo event, Emitter<VideoState> emit) {
    final current = state;
    if (current is! VideoLoaded) return;

    final updated = current.videos.map((video) {
      if (video.id != event.id) return video;
      final liked = !video.isLiked;
      return video.copyWith(
        isLiked: liked,
        likeCount: liked ? video.likeCount + 1 : video.likeCount - 1,
      );
    }).toList();

    emit(VideoLoaded(updated));
  }

  void _onFollowChannel(FollowChannel event, Emitter<VideoState> emit) {
    final current = state;
    if (current is! VideoLoaded) return;

    final updated = current.videos.map((video) {
      if (video.channel.id != event.channelId) return video;
      final followed = !video.isFollowed;
      return video.copyWith(
        isFollowed: followed,
        channel: video.channel.copyWith(isFollowed: followed),
      );
    }).toList();

    emit(VideoLoaded(updated));
  }
}

final List<VideoModel> _mockVideos = [
  VideoModel(
    id: 'v1',
    videoUrl:
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    thumbnailUrl:
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=500',
    description:
    'Sunset vibes and travel mood ✨ #fyp #travel #cinematic. Đây là mô tả dài để test nút xem thêm khi quá 2 dòng.',
    likeCount: 24500,
    commentCount: 899,
    shareCount: 422,
    channel: ChannelModel(
      id: 'c1',
      username: 'travel.daily',
      avatarUrl:
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
      isFollowed: false,
    ),
    music: 'Golden Hour - JVKE',
    isLiked: false,
    isFollowed: false,
  ),
  VideoModel(
    id: 'v2',
    videoUrl:
    'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
    thumbnailUrl:
    'https://images.unsplash.com/photo-1518773553398-650c184e0bb3?w=500',
    description: 'POV: Coding at 2 AM and it finally works 😎 #flutter #bloc',
    likeCount: 11800,
    commentCount: 300,
    shareCount: 104,
    channel: ChannelModel(
      id: 'c2',
      username: 'dev.corner',
      avatarUrl:
      'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?w=200',
      isFollowed: true,
    ),
    music: 'Night Drive - Chillhop',
    isLiked: true,
    isFollowed: true,
  ),
];