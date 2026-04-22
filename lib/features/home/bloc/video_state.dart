import '../models/video_model.dart';

abstract class VideoState {
  const VideoState();
}

class VideoLoading extends VideoState {
  const VideoLoading();
}

class VideoLoaded extends VideoState {
  const VideoLoaded(this.videos);

  final List<VideoModel> videos;
}

class VideoError extends VideoState {
  const VideoError(this.message);

  final String message;
}