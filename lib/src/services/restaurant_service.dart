import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/geo_point.dart';
import '../models/occupancy_status.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/table_slot.dart';

class RestaurantService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all restaurants from Supabase
  Future<List<Restaurant>> fetchRestaurants() async {
    try {
      final response = await _client
          .from('restaurants')
          .select()
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => _restaurantFromJson(json))
          .toList();
    } catch (e) {
      debugPrint('RestaurantService: Failed to fetch restaurants: $e');
      return [];
    }
  }

  /// Fetch a single restaurant by ID
  Future<Restaurant?> fetchRestaurantById(String id) async {
    try {
      final response = await _client
          .from('restaurants')
          .select('*, reviews(*, profiles(name))')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return _restaurantFromJson(response);
    } catch (e) {
      debugPrint('RestaurantService: Failed to fetch restaurant $id: $e');
      return null;
    }
  }

  /// Fetch restaurant by owner ID
  Future<Restaurant?> fetchRestaurantByOwnerId(String ownerId) async {
    try {
      final response = await _client
          .from('restaurants')
          .select('*, reviews(*, profiles(name))')
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (response == null) return null;
      return _restaurantFromJson(response);
    } catch (e) {
      debugPrint('RestaurantService: Failed to fetch restaurant for owner $ownerId: $e');
      return null;
    }
  }

  /// Create a new restaurant
  Future<void> createRestaurant(Restaurant restaurant) async {
    try {
      await _client.from('restaurants').upsert(_restaurantToJson(restaurant));
    } catch (e) {
      debugPrint('RestaurantService: Failed to create restaurant: $e');
      rethrow;
    }
  }

  /// Update an existing restaurant
  Future<void> updateRestaurant(String id, Restaurant restaurant) async {
    try {
      await _client
          .from('restaurants')
          .update(_restaurantToJson(restaurant))
          .eq('id', id);
    } catch (e) {
      debugPrint('RestaurantService: Failed to update restaurant: $e');
      rethrow;
    }
  }

  /// Update restaurant tables
  Future<void> updateRestaurantTables(String id, List<TableSlot> tables) async {
    try {
      await _client.from('restaurants').update({
        'tables': tables.map((t) => _tableToJson(t)).toList(),
        'occupancy_status': _deriveOccupancyStatus(tables).name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('RestaurantService: Failed to update tables: $e');
      rethrow;
    }
  }

  /// Update restaurant location
  Future<void> updateRestaurantLocation(String id, GeoPoint location) async {
    try {
      await _client.from('restaurants').update({
        'location_lat': location.latitude,
        'location_lng': location.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('RestaurantService: Failed to update location: $e');
      rethrow;
    }
  }

  /// Update restaurant details
  Future<void> updateRestaurantDetails(
    String id, {
    String? name,
    String? cuisine,
    String? description,
    String? priceRange,
    String? bannerImage,
    List<String>? menuImages,
    List<String>? specialties,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (cuisine != null) updates['cuisine'] = cuisine;
      if (description != null) updates['description'] = description;
      if (priceRange != null) updates['price_range'] = priceRange;
      if (bannerImage != null) updates['banner_image'] = bannerImage;
      if (menuImages != null) updates['menu_images'] = menuImages;
      if (specialties != null) updates['specialties'] = specialties;
      if (address != null) updates['address'] = address;

      await _client.from('restaurants').update(updates).eq('id', id);
    } catch (e) {
      debugPrint('RestaurantService: Failed to update details: $e');
      rethrow;
    }
  }

  /// Add a review
  Future<void> addReview(String restaurantId, Review review) async {
    try {
      final json = review.toJson();
      json['restaurant_id'] = restaurantId;
      await _client.from('reviews').insert(json);
    } catch (e) {
      debugPrint('RestaurantService: Failed to add review: $e');
      rethrow;
    }
  }

  // Helper methods for JSON conversion
  Restaurant _restaurantFromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      cuisine: json['cuisine'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceRange: json['price_range'] as String? ?? '',
      address: json['address'] as String? ?? '',
      location: GeoPoint(
        latitude: (json['location_lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['location_lng'] as num?)?.toDouble() ?? 0.0,
      ),
      bannerImage: json['banner_image'] as String? ?? '',
      menuImages: (json['menu_images'] as List?)?.cast<String>() ?? [],
      specialties: (json['specialties'] as List?)?.cast<String>() ?? [],
      tables: (json['tables'] as List?)
              ?.map((t) => _tableFromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      occupancyStatus: OccupancyStatus.values.firstWhere(
        (e) => e.name == (json['occupancy_status'] as String? ?? 'empty'),
        orElse: () => OccupancyStatus.empty,
      ),
      // Default values for fields not stored in Supabase
      rating: 4.5,
      reviewCount: 0,
      distanceKm: 0.0,
      reviews: (json['reviews'] as List?)
              ?.map((r) => Review.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> _restaurantToJson(Restaurant restaurant) {
    return {
      'id': restaurant.id,
      'owner_id': restaurant.ownerId,
      'name': restaurant.name,
      'cuisine': restaurant.cuisine,
      'description': restaurant.description,
      'price_range': restaurant.priceRange,
      'address': restaurant.address,
      'location_lat': restaurant.location.latitude,
      'location_lng': restaurant.location.longitude,
      'banner_image': restaurant.bannerImage,
      'menu_images': restaurant.menuImages,
      'specialties': restaurant.specialties,
      'tables': restaurant.tables.map((t) => _tableToJson(t)).toList(),
      'occupancy_status': restaurant.occupancyStatus.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  TableSlot _tableFromJson(Map<String, dynamic> json) {
    return TableSlot(
      id: json['id'] as String,
      label: json['label'] as String,
      seats: json['seats'] as int,
      status: TableStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'available'),
        orElse: () => TableStatus.available,
      ),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _tableToJson(TableSlot table) {
    return {
      'id': table.id,
      'label': table.label,
      'seats': table.seats,
      'status': table.status.name,
      'last_updated': table.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  OccupancyStatus _deriveOccupancyStatus(List<TableSlot> tables) {
    if (tables.isEmpty) return OccupancyStatus.empty;
    final occupied =
        tables.where((table) => table.status == TableStatus.occupied).length;
    final ratio = occupied / tables.length;
    if (ratio < 0.3) return OccupancyStatus.empty;
    if (ratio < 0.7) return OccupancyStatus.partial;
    return OccupancyStatus.full;
  }

  /// Stream of all restaurants for real-time updates
  Stream<List<Restaurant>> getRestaurantsStream() {
    return _client
        .from('restaurants')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((data) => data.map((json) => _restaurantFromJson(json)).toList());
  }
}
