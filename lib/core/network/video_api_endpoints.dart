class VideoApiEndpoints {
  VideoApiEndpoints._();

  static const getHome = '/video-service/v1/home/discovery';
  static const getVideoRecommend = '/video-service/v1/video/hot/new';
  static const getCategoryList = '/video-service/v1/category/list/v2';
  static const getVideoByCategory = '/video-service/v1/video/{id}/cate/v2';
  static const getVideoSearch = '/video-service/v1/video/search';
  static const getChannelSearch = '/video-service/v1/channel/search';
  static const getMyChannelInfo = '/video-service/v1/user/channel/mine';
  static const createAndUpdateChannel = '/video-service/v1/user/channel/push';
  static const followChannel = '/video-service/v1/channel/{id}/follow';
  static const unfollowChannel = '/video-service/v1/channel/{id}/unfollow';
  static const uploadVideo = '/video-service/v1/media/video/upload';
  static const createVideo = '/video-service/v1/user/video/create';
}