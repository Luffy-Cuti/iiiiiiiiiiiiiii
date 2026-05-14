import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/video_api_client.dart';
import '../../../core/network/video_api_endpoints.dart';

class UploadRepository {
  UploadRepository({
    FirebaseStorage? storage,
    VideoApiClient? apiClient,
    Dio? dio,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _apiClient = apiClient ?? VideoApiClient(dio: dio);

  final FirebaseStorage _storage;
  final VideoApiClient _apiClient;

  static const _uploadTimeout = Duration(seconds: 450);

  Future<String> uploadVideo({
    required File file,
    required String userId,
    required String fileName,
    required void Function(int progress) onProgress,
  }) async {
    final path =
        'videos/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final ref = _storage.ref(path);

    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((snapshot) {
      final totalBytes = snapshot.totalBytes;

      if (totalBytes <= 0) return;

      final progress = ((snapshot.bytesTransferred / totalBytes) * 100).round();

      onProgress(progress.clamp(0, 100));
    });

    await uploadTask;

    return ref.getDownloadURL();
  }

  Future<String> uploadVideoToKakoak({
    required File file,
    required String msisdn,
    required void Function(int progress) onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = file.uri.pathSegments.isEmpty
        ? file.path.split(Platform.pathSeparator).last
        : file.uri.pathSegments.last;

    final formData = FormData.fromMap({
      'msisdn': msisdn,
      'timestamp': timestamp,
      'security': '',
      'mpw': AppConfig.uploadPassword,
      'fName': fileName,
      'uFile': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    onProgress(0);

    final response = await _apiClient.uploadMultipart(
      VideoApiEndpoints.uploadVideo,
      data: formData,
      timeout: _uploadTimeout,
      onSendProgress: (bytes, totalBytes) {
        if (totalBytes <= 0) return;

        final progress = ((bytes / totalBytes) * 90).round();

        onProgress(progress.clamp(0, 90));
      },
    );

    onProgress(95);

    _debugLog('Upload status: ${response.statusCode}');

    final videoUrl = _extractUploadedVideoUrl(response.body);

    if (videoUrl.isEmpty) {
      throw VideoApiException(
        response.statusCode,
        'Upload response does not contain a video URL: ${response.body}',
      );
    }

    onProgress(100);

    return videoUrl;
  }

  Future<void> createVideoMetadata({
    required String videoUrl,
    required String title,
    required String description,
    required String categoryId,
    required bool allowComment,
    required bool allowDuet,
    required String visibility,
  }) async {
    final response = await _apiClient.post(
      VideoApiEndpoints.createVideo,
      body: {
        'videoUrl': videoUrl,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'allowComment': allowComment,
        'allowDuet': allowDuet,
        'visibility': visibility,
      },
    );

    _debugLog('Create video metadata success: ${response.statusCode}');
  }

  String _extractUploadedVideoUrl(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is String) {
        return decoded;
      }

      if (decoded is! Map<String, dynamic>) {
        return '';
      }

      final candidates = <dynamic>[
        decoded['mediaUrl'],
        decoded['urlVideo'],
        decoded['videoUrl'],
        decoded['url'],
        decoded['fileUrl'],
        decoded['link'],
        decoded['data'],
        decoded['result'],
      ];

      for (final candidate in candidates) {
        final url = _extractUrl(candidate);

        if (url.isNotEmpty) {
          return url;
        }
      }

      return '';
    } catch (e) {
      print('PARSE VIDEO URL ERROR: $e');
      return '';
    }
  }

  String _extractUrl(dynamic value) {
    if (value is String) {
      return value;
    }

    if (value is Map) {
      for (final key in const [
        'mediaUrl',
        'urlVideo',
        'videoUrl',
        'url',
        'fileUrl',
        'link',
        'path',
      ]) {
        final nestedValue = value[key];

        if (nestedValue is String && nestedValue.isNotEmpty) {
          return nestedValue;
        }
      }
    }

    return '';
  }
}

void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
