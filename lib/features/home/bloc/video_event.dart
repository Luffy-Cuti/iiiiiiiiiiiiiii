abstract class VideoEvent {
  const VideoEvent();
}

class FetchVideos extends VideoEvent {
  const FetchVideos();
}

class LikeVideo extends VideoEvent {
  const LikeVideo(this.id);

  final String id;
}

class FollowChannel extends VideoEvent {
  const FollowChannel(this.channelId);

  final String channelId;
}