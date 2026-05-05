import 'dart:convert';

import 'package:http/http.dart' as http;

class VideoApiClient {
  VideoApiClient({
    http.Client? httpClient,
    this.baseUrl = 'https://timordev.ringme.vn',
    this.defaultHeaders = const {
      'Client-Type': 'Android',
      'sec-api': '123',
      'Accept-Language': 'vi',
    },
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$baseUrl$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.get(
      _buildUri(path, queryParameters),
      headers: {...defaultHeaders, ...?headers},
    );
    _throwIfNeeded(response);
    return response;
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.post(
      _buildUri(path, queryParameters),
      headers: {
        ...defaultHeaders,
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    _throwIfNeeded(response);
    return response;
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw VideoApiException(response.statusCode, response.body);
  }
}

class VideoApiException implements Exception {
  VideoApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() =>
      'VideoApiException(status: $statusCode, message: $message)';
}
