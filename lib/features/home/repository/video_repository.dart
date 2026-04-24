import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/channel_model.dart';
import '../models/video_model.dart';

class VideoRepository {
  VideoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<VideoModel>> fetchVideos() async {
    final snapshot = await _firestore
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => _toVideoModel(doc)).toList();
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
}