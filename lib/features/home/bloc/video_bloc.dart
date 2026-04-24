import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../repository/video_repository.dart';

import '../models/channel_model.dart';
import '../models/video_model.dart';
import 'video_event.dart';
import 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc({required VideoRepository videoRepository})
      : _videoRepository = videoRepository,
        super(const VideoLoading()) {
    on<FetchVideos>(_onFetchVideos);
    on<LikeVideo>(_onLikeVideo);
    on<FollowChannel>(_onFollowChannel);
  }
  final VideoRepository _videoRepository;

  Future<void> _onFetchVideos(FetchVideos event, Emitter<VideoState> emit) async {
    emit(const VideoLoading());
    try {
      final videos = await _videoRepository.fetchVideos();
      emit(VideoLoaded(videos));
    } catch (error, stack) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'fetch_videos_failed',
        fatal: false,
      );
      emit(const VideoError('Không thể tải video. Vui lòng thử lại.'));
    }
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

