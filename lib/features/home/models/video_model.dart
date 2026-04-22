import 'channel_model.dart';

class VideoModel {
  const VideoModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.description,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.channel,
    required this.music,
    required this.isLiked,
    required this.isFollowed,
  });

  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String description;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final ChannelModel channel;
  final String music;
  final bool isLiked;
  final bool isFollowed;

  VideoModel copyWith({
    String? id,
    String? videoUrl,
    String? thumbnailUrl,
    String? description,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    ChannelModel? channel,
    String? music,
    bool? isLiked,
    bool? isFollowed,
  }) {
    return VideoModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      channel: channel ?? this.channel,
      music: music ?? this.music,
      isLiked: isLiked ?? this.isLiked,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}