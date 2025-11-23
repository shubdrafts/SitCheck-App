import 'geo_point.dart';
import 'occupancy_status.dart';
import 'review.dart';
import 'table_slot.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.priceRange,
    required this.occupancyStatus,
    required this.bannerImage,
    required this.specialties,
    required this.tables,
    required this.menuImages,
    required this.location,
    required this.reviews,
    this.description =
        'Experience thoughtful hospitality with seasonal menus and curated pairings.',
    this.address = 'Mangalore City, India',
  });

  final String id;
  final String ownerId;
  final String name;
  final String cuisine;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String priceRange;
  final OccupancyStatus occupancyStatus;
  final String bannerImage;
  final List<String> specialties;
  final List<String> menuImages;
  final List<TableSlot> tables;
  final String description;
  final String address;
  final GeoPoint location;
  final List<Review> reviews;

  int get totalTables => tables.length;
  int get availableTables =>
      tables.where((table) => table.status == TableStatus.available).length;
  int get reservedTables =>
      tables.where((table) => table.status == TableStatus.reserved).length;
  int get occupiedTables =>
      tables.where((table) => table.status == TableStatus.occupied).length;

  Restaurant copyWith({
    String? ownerId,
    String? name,
    String? cuisine,
    double? rating,
    int? reviewCount,
    double? distanceKm,
    String? priceRange,
    OccupancyStatus? occupancyStatus,
    String? bannerImage,
    List<String>? specialties,
    List<String>? menuImages,
    List<TableSlot>? tables,
    String? description,
    String? address,
    GeoPoint? location,
    List<Review>? reviews,
  }) {
    return Restaurant(
      id: id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distanceKm: distanceKm ?? this.distanceKm,
      priceRange: priceRange ?? this.priceRange,
      occupancyStatus: occupancyStatus ?? this.occupancyStatus,
      bannerImage: bannerImage ?? this.bannerImage,
      specialties: specialties ?? this.specialties,
      menuImages: menuImages ?? this.menuImages,
      tables: tables ?? this.tables,
      description: description ?? this.description,
      address: address ?? this.address,
      location: location ?? this.location,
      reviews: reviews ?? this.reviews,
    );
  }
}