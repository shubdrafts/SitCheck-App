import 'dart:convert';

import '../../models/geo_point.dart';
import '../../models/occupancy_status.dart';
import '../../models/restaurant.dart';
import '../../models/review.dart';
import '../../models/table_slot.dart';

class RestaurantMapper {
  const RestaurantMapper._();

  static Restaurant fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      priceRange: json['price_range'] as String? ?? '',
      occupancyStatus:
          _occupancyStatusFromString(json['occupancy_status'] as String? ?? 'empty'),
      bannerImage: json['banner_image'] as String? ?? '',
      specialties: (json['specialties'] as List?)?.map((e) => e.toString()).toList() ?? [],
      menuImages: (json['menu_images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tables: tablesFromJson(json['tables'] as List?),
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      location: GeoPoint(
        latitude: (json['location_lat'] as num?)?.toDouble() ?? 37.7749,
        longitude: (json['location_lng'] as num?)?.toDouble() ?? -122.4194,
      ),
      reviews: _reviewsFromJson(json['reviews'] as List?),
    );
  }

  static Map<String, dynamic> toJson(Restaurant restaurant) {
    return {
      'id': restaurant.id,
      'owner_id': restaurant.ownerId,
      'name': restaurant.name,
      'cuisine': restaurant.cuisine,
      'rating': restaurant.rating,
      'review_count': restaurant.reviewCount,
      'distance_km': restaurant.distanceKm,
      'price_range': restaurant.priceRange,
      'occupancy_status': restaurant.occupancyStatus.name,
      'banner_image': restaurant.bannerImage,
      'specialties': restaurant.specialties,
      'menu_images': restaurant.menuImages,
      'tables': tablesToJson(restaurant.tables),
      'description': restaurant.description,
      'address': restaurant.address,
      'location_lat': restaurant.location.latitude,
      'location_lng': restaurant.location.longitude,
      'reviews': _reviewsToJson(restaurant.reviews),
    };
  }

  static Restaurant fromPayload(String payload) {
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    return fromJson(decoded);
  }

  static String toPayload(Restaurant restaurant) {
    final map = toJson(restaurant);
    return jsonEncode(map);
  }

  static List<TableSlot> tablesFromJson(List? json) {
    if (json == null) return [];
    return json.map((item) {
      final map = item as Map<String, dynamic>;
      return TableSlot(
        id: map['id'] as String? ?? '',
        label: map['label'] as String? ?? '',
        seats: (map['seats'] as num?)?.toInt() ?? 4,
        status: _tableStatusFromString(map['status'] as String? ?? 'available'),
        lastUpdated: map['last_updated'] != null
            ? DateTime.tryParse(map['last_updated'] as String)
            : null,
      );
    }).toList();
  }

  static List<Map<String, dynamic>> tablesToJson(List<TableSlot> tables) {
    return tables
        .map((table) => {
              'id': table.id,
              'label': table.label,
              'seats': table.seats,
              'status': table.status.name,
              'last_updated': table.lastUpdated?.toIso8601String(),
            })
        .toList();
  }

  static List<Review> _reviewsFromJson(List? json) {
    if (json == null) return [];
    return json.map((item) {
      final map = item as Map<String, dynamic>;
      return Review(
        id: map['id'] as String? ?? '',
        userId: map['user_id'] as String? ?? '',
        author: map['author'] as String? ?? '',
        comment: map['comment'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
    }).toList();
  }

  static List<Map<String, dynamic>> _reviewsToJson(List<Review> reviews) {
    return reviews
        .map((review) => {
              'id': review.id,
              'user_id': review.userId,
              'author': review.author,
              'comment': review.comment,
              'rating': review.rating,
              'created_at': review.createdAt.toIso8601String(),
            })
        .toList();
  }

  static OccupancyStatus _occupancyStatusFromString(String value) {
    switch (value) {
      case 'empty':
        return OccupancyStatus.empty;
      case 'partial':
        return OccupancyStatus.partial;
      case 'full':
        return OccupancyStatus.full;
      default:
        return OccupancyStatus.empty;
    }
  }

  static TableStatus _tableStatusFromString(String value) {
    switch (value) {
      case 'available':
        return TableStatus.available;
      case 'reserved':
        return TableStatus.reserved;
      case 'occupied':
        return TableStatus.occupied;
      default:
        return TableStatus.available;
    }
  }
}

