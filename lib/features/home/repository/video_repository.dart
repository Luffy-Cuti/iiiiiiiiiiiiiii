import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../models/category_model.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';
import '../../../core/network/video_api_client.dart';
import '../../../core/network/video_api_endpoints.dart';

class VideoRepository {
  VideoRepository({FirebaseFirestore? firestore, VideoApiClient? apiClient})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _apiClient = apiClient ?? VideoApiClient();

  final FirebaseFirestore _firestore;
  final VideoApiClient _apiClient;

  Future<List<VideoModel>> fetchVideos() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _apiClient.get(
        VideoApiEndpoints.getVideoRecommend,
        queryParameters: {
          'page': '0',
          'size': '20',
          'msisdn': AppConfig.defaultMsisdn,
          'timestamp': timestamp,
          'security': '',
          'lastHashId': '',
        },
      );

      _debugLog('Video API status: ${response.statusCode}');

      final videos = _extractVideoList(response.body);

      _debugLog('Video API returned ${videos.length} videos');

      return videos;
    } catch (error, stackTrace) {
      _debugLog('Video API failed: $error\n$stackTrace');
      return _fetchVideosFromFirestoreFallback();
    }
  }

  Future<List<VideoModel>> _fetchVideosFromFirestoreFallback() async {
    try {
      final snapshot = await _firestore
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final videos = snapshot.docs.map(_toVideoModel).toList();
      _debugLog('Firestore fallback returned ${videos.length} videos');

      return videos;
    } catch (error, stackTrace) {
      _debugLog('Firestore fallback failed: $error\n$stackTrace');
      return const [];
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

    return _extractVideoList(response.body);
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

  VideoModel _toVideoModel(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final channelId = data['channelId'] as String? ?? 'unknown';
    final username = data['username'] as String? ?? 'user';

    return VideoModel(
      id: doc.id,
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: (data['thumbnailUrl'] as String?)?.trim().isNotEmpty == true
          ? (data['thumbnailUrl'] as String)
          : 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=500',
      description: data['description'] as String? ?? '',
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
      channel: ChannelModel(
        id: channelId,
        username: username,
        avatarUrl: (data['avatarUrl'] as String?)?.trim().isNotEmpty == true
            ? (data['avatarUrl'] as String)
            : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        isFollowed: false,
      ),
      music: data['music'] as String? ?? '',
      isLiked: false,
      isFollowed: false,
    );
  }

  VideoModel _videoFromJson(Map<String, dynamic> data) {
    final channelData =
        (data['channelInfo'] as Map?)?.cast<String, dynamic>() ??
        (data['channel'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return VideoModel(
      id: (data['id'] ?? data['videoId'] ?? '').toString(),
      videoUrl: (data['urlVideo'] ?? data['videoUrl'] ?? '').toString(),
      thumbnailUrl: (data['thumbnail'] ?? data['thumbnailUrl'] ?? '')
          .toString(),
      description: (data['description'] ?? data['title'] ?? '').toString(),
      likeCount: _asInt(data['totalLike'] ?? data['likeCount']),
      commentCount: _asInt(data['totalComment'] ?? data['commentCount']),
      shareCount: _asInt(data['totalShare'] ?? data['shareCount']),
      channel: _channelFromJson(channelData),
      music: (data['music'] ?? '').toString(),
      isLiked: _asBool(data['isLiked']),
      isFollowed: _asBool(data['isFollowed']),
    );
  }

  ChannelModel _channelFromJson(Map<String, dynamic> data) {
    return ChannelModel(
      id: (data['id'] ?? data['channelId'] ?? '').toString(),
      username: (data['channelName'] ?? data['username'] ?? 'User').toString(),
      avatarUrl: (data['avatarUrl'] ?? '').toString(),
      isFollowed: _asBool(data['isFollowed']),
    );
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
}
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
