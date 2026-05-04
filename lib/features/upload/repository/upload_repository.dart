import 'dart:io';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/video_api_client.dart';
import '../../../core/network/video_api_endpoints.dart';

class UploadRepository {
  UploadRepository({
    FirebaseStorage? storage,
    VideoApiClient? apiClient,
    http.Client? httpClient,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _apiClient = apiClient ?? VideoApiClient(httpClient: httpClient);

  final FirebaseStorage _storage;
  final VideoApiClient _apiClient;

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
    final uploadUri = Uri.parse(
      '${_apiClient.baseUrl}${VideoApiEndpoints.uploadVideo}',
    );
    final request = http.MultipartRequest('POST', uploadUri)
      ..headers.addAll(_apiClient.defaultHeaders)
      ..fields['msisdn'] = msisdn
      ..fields['timestamp'] = '${DateTime.now().millisecondsSinceEpoch}'
      ..fields['security'] = ''
      ..fields['fName'] = file.path.split('/').last
      ..files.add(await http.MultipartFile.fromPath('uFile', file.path));

    onProgress(5);
    final streamedResponse = await request.send();
    onProgress(80);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VideoApiException(response.statusCode, response.body);
    }
    onProgress(100);

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    final data = jsonMap['data'];
    if (data is Map<String, dynamic>) {
      return (data['urlVideo'] ?? data['videoUrl'] ?? '').toString();
    }
    return '';
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
    await _apiClient.post(
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
  }
}
