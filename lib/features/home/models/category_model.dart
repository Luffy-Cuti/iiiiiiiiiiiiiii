import '../../../core/config/app_config.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconImageUrl,
    required this.headerBannerUrl,
    required this.description,
    this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? json['cateId'] ?? '').toString(),
      name: (json['cateName'] ?? json['name'] ?? '').toString(),
      iconImageUrl: _normalizeMediaUrl(json['iconImage']),
      headerBannerUrl: _normalizeMediaUrl(json['headerBanner']),
      description: (json['description'] ?? '').toString(),
      type: json['type']?.toString(),
    );
  }

  final String id;
  final String name;
  final String iconImageUrl;
  final String headerBannerUrl;
  final String description;
  final String? type;

  static String _normalizeMediaUrl(dynamic value) {
    final rawValue = value?.toString().trim() ?? '';
    if (rawValue.isEmpty || rawValue == '/' || rawValue == '/null') {
      return '';
    }
    if (rawValue.startsWith('http://') || rawValue.startsWith('https://')) {
      return rawValue;
    }
    final path = rawValue.startsWith('/') ? rawValue : '/$rawValue';
    return '${AppConfig.videoApiBaseUrl}$path';
  }
}