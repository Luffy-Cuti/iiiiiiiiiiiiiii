import 'package:dio/dio.dart';

import '../config/app_config.dart';

class VideoApiClient {
  VideoApiClient({
    Dio? dio,
    this.baseUrl = AppConfig.videoApiBaseUrl,
    this.defaultHeaders = const {
      'Client-Type': 'Android',
      'sec-api': AppConfig.videoApiSecret,
      'Accept-Language': 'vi',
    },
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               headers: defaultHeaders,
               validateStatus: (_) => true,
             ),
           ) {
    if (dio != null) {
      _dio.options
        ..baseUrl = baseUrl
        ..validateStatus = (_) => true;

      _dio.options.headers.addAll(defaultHeaders);
    }
  }

  final Dio _dio;
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  Future<VideoApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _dio.get<String>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: _mergeHeaders(headers),
        responseType: ResponseType.plain,
      ),
    );

    final apiResponse = VideoApiResponse.fromDio(response);
    _throwIfNeeded(apiResponse);
    return apiResponse;
  }

  Future<VideoApiResponse> post(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final contentType = headers?['Content-Type'] ?? Headers.jsonContentType;

    final requestHeaders = _mergeHeaders(headers);
    requestHeaders.remove('Content-Type');

    final response = await _dio.post<String>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: Options(
        contentType: contentType,
        headers: requestHeaders,
        responseType: ResponseType.plain,
      ),
    );

    final apiResponse = VideoApiResponse.fromDio(response);
    _throwIfNeeded(apiResponse);
    return apiResponse;
  }

  Future<VideoApiResponse> uploadMultipart(
    String path, {
    required FormData data,
    Duration? timeout,
    ProgressCallback? onSendProgress,
    Map<String, String>? headers,
  }) async {
    final response = await _dio.post<String>(
      path,
      data: data,
      onSendProgress: onSendProgress,
      options: Options(
        headers: _mergeHeaders(headers),
        responseType: ResponseType.plain,
        sendTimeout: timeout,
        receiveTimeout: timeout,
      ),
    );

    final apiResponse = VideoApiResponse.fromDio(response);
    _throwIfNeeded(apiResponse);
    return apiResponse;
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return {...defaultHeaders, ...?headers};
  }

  void _throwIfNeeded(VideoApiResponse response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw VideoApiException(response.statusCode, response.body);
  }
}

class VideoApiResponse {
  const VideoApiResponse({required this.statusCode, required this.body});

  factory VideoApiResponse.fromDio(Response<String> response) {
    return VideoApiResponse(
      statusCode: response.statusCode ?? 0,
      body: response.data ?? '',
    );
  }

  final int statusCode;
  final String body;
}

class VideoApiException implements Exception {
  VideoApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() {
    return 'VideoApiException(status: $statusCode, message: $message)';
  }
}
