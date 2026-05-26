import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/video_api_client.dart';
import '../../../core/network/video_api_endpoints.dart';
import '../models/category_model.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';

class VideoRepository {
  VideoRepository({FirebaseFirestore? firestore, VideoApiClient? apiClient})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _apiClient = apiClient ?? VideoApiClient();

  static const Duration _homeVideoApiTimeout = Duration(seconds: 5);

  final FirebaseFirestore _firestore;
  final VideoApiClient _apiClient;

  Future<List<VideoModel>> fetchVideos() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _apiClient
          .get(
            VideoApiEndpoints.getVideoRecommend,
            queryParameters: {
              'page': '0',
              'size': '20',
              'msisdn': AppConfig.defaultMsisdn,
              'timestamp': timestamp,
              'security': '',
              'lastHashId': '',
            },
          )
          .timeout(_homeVideoApiTimeout);

      _debugLog('Video API status: ${response.statusCode}');

      final videos = _extractVideoList(response.body);

      _debugLog('Video API returned ${videos.length} videos');

      final playableVideos = _playableVideos(videos);
      if (playableVideos.isEmpty) {
        return _sampleVideos('Video API returned no playable videos');
      }

      if (playableVideos.length < 2) {
        final sampleVideos = await _sampleVideos(
          'Video API returned only ${playableVideos.length} playable videos',
        );
        return [...playableVideos, ...sampleVideos].take(4).toList();
      }

      return playableVideos;
    } catch (error, stackTrace) {
      _debugLog('Video API failed: $error\n$stackTrace');
      return _sampleVideos('Video API failed or timed out');
    }
  }

  Future<List<VideoModel>> fetchVideosByCategory({
    required String categoryId,
    int page = 0,
    int size = 18,
    String lastHashId = '',
  }) async {
    final response = await _apiClient.get(
      VideoApiEndpoints.getVideoByCategory.replaceAll('{id}', categoryId),
      queryParameters: _withDefaultQueryParameters({
        'page': '$page',
        'size': '$size',
        'lastHashId': lastHashId,
      }),
    );

    final videos = _extractVideoList(response.body);
    _debugLog(
      'Category $categoryId API returned ${videos.length} videos, '
      '${_playableVideos(videos).length} playable',
    );
    return videos;
  }

  Future<List<VideoModel>> searchVideos({
    required String keyword,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      VideoApiEndpoints.getVideoSearch,
      queryParameters: {'q': keyword, 'page': '$page', 'size': '$size'},
    );

    return _extractVideoList(response.body);
  }

  Future<List<ChannelModel>> searchChannels({
    required String keyword,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      VideoApiEndpoints.getChannelSearch,
      queryParameters: {'q': keyword, 'page': '$page', 'size': '$size'},
    );
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    final list = _firstListByKeys(jsonMap, const ['data', 'result', 'items']);
    return list.map(_channelFromJson).toList();
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _apiClient.get(
      VideoApiEndpoints.getCategoryList,
      queryParameters: _withDefaultQueryParameters({
        'clientType': 'Android',
        'revision': AppConfig.revision,
      }),
    );
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    final list = _firstListByKeys(jsonMap, const ['data', 'result', 'items']);
    return list.map(CategoryModel.fromJson).toList();
  }

  Future<Map<String, dynamic>> getMyChannelInfo() async {
    final response = await _apiClient.get(VideoApiEndpoints.getMyChannelInfo);
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    final candidate = jsonMap['data'] ?? jsonMap['result'] ?? jsonMap;
    if (candidate is Map<String, dynamic>) return candidate;
    return <String, dynamic>{};
  }

  Future<void> createOrUpdateChannel({
    required String channelName,
    required String description,
    String avatarUrl = '',
    String coverUrl = '',
  }) async {
    await _apiClient.post(
      VideoApiEndpoints.createAndUpdateChannel,
      body: {
        'channelName': channelName,
        'description': description,
        'avatarUrl': avatarUrl,
        'coverUrl': coverUrl,
      },
    );
  }

  Future<void> followChannel(String channelId) {
    return _apiClient.get(
      VideoApiEndpoints.followChannel.replaceAll('{id}', channelId),
    );
  }

  Future<void> unfollowChannel(String channelId) {
    return _apiClient.get(
      VideoApiEndpoints.unfollowChannel.replaceAll('{id}', channelId),
    );
  }

  Future<String> createVideoDocument({
    required String videoUrl,
    required String description,
    required String title,
    required String categoryId,
    required String userId,
    required String username,
    required String avatarUrl,
    required String visibility,
    required bool allowComment,
    required bool allowDuet,
  }) async {
    final document = _firestore.collection('videos').doc();
    await document.set({
      'videoUrl': videoUrl,
      'thumbnailUrl': '',
      'description': description,
      'title': title,
      'categoryId': categoryId,
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'music': '',
      'channelId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'visibility': visibility,
      'allowComment': allowComment,
      'allowDuet': allowDuet,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Map<String, String> _withDefaultQueryParameters(
    Map<String, String> queryParameters,
  ) {
    return {
      'msisdn': AppConfig.defaultMsisdn,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'security': '',
      ...queryParameters,
    };
  }

  List<VideoModel> _extractVideoList(String body) {
    final jsonMap = jsonDecode(body) as Map<String, dynamic>;
    final list = _firstListByKeys(jsonMap, const [
      'data',
      'result',
      'videos',
      'items',
    ]);
    return list.map(_videoFromJson).toList();
  }

  List<Map<String, dynamic>> _firstListByKeys(
    Map<String, dynamic> jsonMap,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = jsonMap[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (value is Map<String, dynamic>) {
        final nested = value['items'] ?? value['list'] ?? value['data'];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
  }

  VideoModel _videoFromJson(Map<String, dynamic> data) {
    final channelData =
        (data['channelInfo'] as Map?)?.cast<String, dynamic>() ??
        (data['channel'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return VideoModel(
      id: (data['id'] ?? data['videoId'] ?? '').toString(),
      videoUrl: _normalizeMediaUrl(
        data['urlVideo'] ?? data['videoUrl'] ?? data['videoMedia'],
      ),
      thumbnailUrl: _normalizeMediaUrl(
        data['thumbnail'] ??
            data['thumbnailUrl'] ??
            data['videoImage'] ??
            data['imageThumb'] ??
            data['imageSmall'],
      ),
      description:
          (data['description'] ??
                  data['title'] ??
                  data['videoTitle'] ??
                  data['videoDesc'] ??
                  '')
              .toString(),
      likeCount: _asInt(
        data['totalLike'] ?? data['totalLikes'] ?? data['likeCount'],
      ),
      commentCount: _asInt(
        data['totalComment'] ?? data['totalComments'] ?? data['commentCount'],
      ),
      shareCount: _asInt(
        data['totalShare'] ?? data['totalShares'] ?? data['shareCount'],
      ),
      channel: _channelFromJson(channelData),
      music: (data['music'] ?? '').toString(),
      isLiked: _asBool(data['isLiked'] ?? data['isLike']),
      isFollowed: _asBool(data['isFollowed'] ?? data['isFollow']),
    );
  }

  ChannelModel _channelFromJson(Map<String, dynamic> data) {
    return ChannelModel(
      id: (data['id'] ?? data['channelId'] ?? '').toString(),
      username: (data['channelName'] ?? data['username'] ?? 'User').toString(),
      avatarUrl: _normalizeMediaUrl(data['avatarUrl'] ?? data['channelAvatar']),
      isFollowed: _asBool(data['isFollowed'] ?? data['isFollow']),
    );
  }

  String _normalizeMediaUrl(dynamic value) {
    final rawValue = value?.toString().trim() ?? '';
    if (rawValue.isEmpty || rawValue == '/' || rawValue == '/null') {
      return '';
    }
    if (rawValue.startsWith('http://') ||
        rawValue.startsWith('https://') ||
        rawValue.startsWith('assets/') ||
        rawValue.startsWith('file:')) {
      return rawValue;
    }
    final path = rawValue.startsWith('/') ? rawValue : '/$rawValue';
    return '${AppConfig.videoApiBaseUrl}$path';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is num) return value != 0;
    return false;
  }

  List<VideoModel> _playableVideos(List<VideoModel> videos) {
    return videos.where((video) => video.videoUrl.trim().isNotEmpty).toList();
  }

  Future<List<VideoModel>> _sampleVideos(String reason) async {
    final assets = await _localVideoAssets();
    _debugLog('$reason. Using ${assets.length} local sample videos.');

    return [
      for (var index = 0; index < assets.length; index++)
        _sampleVideoFromAsset(assets[index], index),
    ];
  }

  Future<List<String>> _localVideoAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets =
          manifest.listAssets().where(_isSupportedLocalVideoAsset).toList()
            ..sort();

      return assets.take(4).toList();
    } catch (error, stackTrace) {
      _debugLog('Read local video assets failed: $error\n$stackTrace');
      return const [];
    }
  }

  bool _isSupportedLocalVideoAsset(String asset) {
    final lowerAsset = asset.toLowerCase();
    return lowerAsset.startsWith('assets/videos/') &&
        (lowerAsset.endsWith('.mp4') ||
            lowerAsset.endsWith('.mov') ||
            lowerAsset.endsWith('.m4v') ||
            lowerAsset.endsWith('.webm'));
  }

  VideoModel _sampleVideoFromAsset(String asset, int index) {
    final number = index + 1;
    return VideoModel(
      id: 'local-video-$number',
      videoUrl: asset,
      thumbnailUrl: '',
      description: _assetDisplayName(asset),
      likeCount: 1000 + index * 137,
      commentCount: 40 + index * 11,
      shareCount: 20 + index * 7,
      channel: ChannelModel(
        id: 'local-channel-$number',
        username: 'local_video_$number',
        avatarUrl: '',
        isFollowed: false,
      ),
      music: 'Local debug audio $number',
      isLiked: false,
      isFollowed: false,
    );
  }

  String _assetDisplayName(String asset) {
    final fileName = asset.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    final name = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    return name.replaceAll(RegExp(r'[_-]+'), ' ');
  }
}

void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
