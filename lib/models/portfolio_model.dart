// lib/models/portfolio_model.dart
class PortfolioItem {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final String mediaType; // 'image' or 'video'
  final String mediaUrl;
  final String thumbnailUrl;
  final DateTime createdAt;

  PortfolioItem({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl = '',
    required this.createdAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] ?? '',
      providerId: json['provider_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      mediaUrl: json['media_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'title': title,
      'description': description,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}