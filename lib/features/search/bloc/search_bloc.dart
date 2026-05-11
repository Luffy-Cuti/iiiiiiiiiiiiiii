import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/models/channel_model.dart';
import '../../home/repository/video_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required VideoRepository videoRepository})
      : _videoRepository = videoRepository,
        super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchCleared>(_onCleared);
    on<SearchChannelFollowToggled>(_onChannelFollowToggled);
  }

  final VideoRepository _videoRepository;

  Future<void> _onQueryChanged(
      SearchQueryChanged event,
      Emitter<SearchState> emit,
      ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }

    emit(
      state.copyWith(
        query: query,
        status: SearchStatus.loading,
        videos: const [],
        channels: const [],
        clearMessage: true,
      ),
    );

    try {
      final videos = await _videoRepository.searchVideos(keyword: query);
      final channels = await _videoRepository.searchChannels(keyword: query);

      emit(
        SearchState(
          query: query,
          status: SearchStatus.success,
          videos: videos,
          channels: channels,
        ),
      );
    } catch (error, stack) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'search_video_channel_failed',
        fatal: false,
      );
      emit(
        state.copyWith(
          query: query,
          status: SearchStatus.failure,
          message: 'Không thể tìm kiếm. Vui lòng thử lại.',
        ),
      );
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }

  Future<void> _onChannelFollowToggled(
      SearchChannelFollowToggled event,
      Emitter<SearchState> emit,
      ) async {
    ChannelModel? currentChannel;
    for (final channel in state.channels) {
      if (channel.id == event.channelId) {
        currentChannel = channel;
        break;
      }
    }
    if (currentChannel == null) return;

    final shouldFollow = !currentChannel.isFollowed;
    emit(
      state.copyWith(
        channels: state.channels.map((channel) {
          if (channel.id != event.channelId) return channel;
          return channel.copyWith(isFollowed: shouldFollow);
        }).toList(),
        videos: state.videos.map((video) {
          if (video.channel.id != event.channelId) return video;
          return video.copyWith(
            isFollowed: shouldFollow,
            channel: video.channel.copyWith(isFollowed: shouldFollow),
          );
        }).toList(),
      ),
    );

    try {
      if (shouldFollow) {
        await _videoRepository.followChannel(event.channelId);
      } else {
        await _videoRepository.unfollowChannel(event.channelId);
      }
    } catch (error, stack) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'toggle_search_channel_follow_failed',
        fatal: false,
      );
      emit(
        state.copyWith(
          channels: state.channels.map((channel) {
            if (channel.id != event.channelId) return channel;
            return channel.copyWith(isFollowed: !shouldFollow);
          }).toList(),
          videos: state.videos.map((video) {
            if (video.channel.id != event.channelId) return video;
            return video.copyWith(
              isFollowed: !shouldFollow,
              channel: video.channel.copyWith(isFollowed: !shouldFollow),
            );
          }).toList(),
          message: 'Không thể cập nhật theo dõi kênh.',
        ),
      );
    }
  }
}