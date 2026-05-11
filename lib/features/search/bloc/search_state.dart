import '../../home/models/channel_model.dart';
import '../../home/models/video_model.dart';

enum SearchStatus { initial, loading, success, failure }

class SearchState {
  const SearchState({
    this.query = '',
    this.status = SearchStatus.initial,
    this.videos = const <VideoModel>[],
    this.channels = const <ChannelModel>[],
    this.message,
  });

  final String query;
  final SearchStatus status;
  final List<VideoModel> videos;
  final List<ChannelModel> channels;
  final String? message;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => videos.isNotEmpty || channels.isNotEmpty;

  SearchState copyWith({
    String? query,
    SearchStatus? status,
    List<VideoModel>? videos,
    List<ChannelModel>? channels,
    String? message,
    bool clearMessage = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      videos: videos ?? this.videos,
      channels: channels ?? this.channels,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}