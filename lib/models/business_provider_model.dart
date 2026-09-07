// lib/models/business_provider_model.dart
class BusinessProvider {
  final String id;
  final String userId;
  final String businessType;
  final String businessName;
  final double serviceRadius;
  final bool isBusiness;
  final double latitude;
  final double longitude;
  final String? profession;
  final String? about;
  final String? phone;
  final String? address;
  final bool isAvailable;
  final double rating;
  final int totalReviews;
  final bool isVerified;

  BusinessProvider({
    required this.id,
    required this.userId,
    required this.businessType,
    required this.businessName,
    required this.serviceRadius,
    required this.isBusiness,
    required this.latitude,
    required this.longitude,
    this.profession,
    this.about,
    this.phone,
    this.address,
    this.isAvailable = true,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
  });

  factory BusinessProvider.fromJson(Map<String, dynamic> json) {
    return BusinessProvider(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      businessType: json['business_type'] ?? 'individual',
      businessName: json['business_name'] ?? '',
      serviceRadius: (json['service_radius'] ?? 20).toDouble(),
      isBusiness: json['is_business'] ?? false,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      profession: json['profession'],
      about: json['about'],
      phone: json['phone'],
      address: json['permanent_address'],
      isAvailable: json['is_available'] ?? true,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_type': businessType,
      'business_name': businessName,
      'service_radius': serviceRadius,
      'is_business': isBusiness,
      'latitude': latitude,
      'longitude': longitude,
      'profession': profession,
      'about': about,
      'phone': phone,
      'permanent_address': address,
      'is_available': isAvailable,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_verified': isVerified,
    };
  }
}

// lib/models/business_product.dart
class BusinessProduct {
  final String id;
  final String providerId;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final double deliveryCharge;
  final Map<String, dynamic>? quantityOptions;
  final List<String> images;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessProduct({
    required this.id,
    required this.providerId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.deliveryCharge,
    this.quantityOptions,
    this.images = const [],
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessProduct.fromJson(Map<String, dynamic> json) {
    return BusinessProduct(
      id: json['id'] ?? '',
      providerId: json['provider_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      quantityOptions: json['quantity_options'] as Map<String, dynamic>?,
      images: List<String>.from(json['images'] ?? []),
      isAvailable: json['is_available'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'delivery_charge': deliveryCharge,
      'quantity_options': quantityOptions,
      'images': images,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}