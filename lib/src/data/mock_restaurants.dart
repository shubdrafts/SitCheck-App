import '../models/geo_point.dart';
import '../models/occupancy_status.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/table_slot.dart';

List<TableSlot> _buildTables({
  required String prefix,
  required int total,
  required int occupied,
  int reserved = 0,
}) {
  return List.generate(total, (index) {
    final label = '$prefix${index + 1}';
    TableStatus status = TableStatus.available;
    if (index < occupied) {
      status = TableStatus.occupied;
    } else if (index < occupied + reserved) {
      status = TableStatus.reserved;
    }
    return TableSlot(
      id: label,
      label: label,
      seats: 4,
      status: status,
      lastUpdated: DateTime.now().subtract(Duration(minutes: index * 3)),
    );
  });
}

List<Review> _buildReviews(String prefix) {
  return [
    Review(
      id: '${prefix}_1',
      userId: 'mock-user-1',
      author: 'Anika Rao',
      comment: 'Loved the seasonal tasting menu and how easy it was to grab a table.',
      rating: 4.8,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Review(
      id: '${prefix}_2',
      userId: 'mock-user-2',
      author: 'Marcos Li',
      comment: 'Great ambience, live occupancy updates saved us a 30-min wait.',
      rating: 4.6,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];
}

final mockRestaurants = <Restaurant>[
  Restaurant(
    id: 'village-restaurant',
    ownerId: 'owner-1',
    name: 'Village Restaurant',
    cuisine: 'Coastal & South Indian',
    rating: 4.7,
    reviewCount: 428,
    distanceKm: 0.9,
    priceRange: r'₹400+ per person',
    occupancyStatus: OccupancyStatus.partial,
    bannerImage:
        'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg?auto=compress&cs=tinysrgb&w=1200',
    specialties: ['Neer Dosa Platters', 'Claypot Seafood', 'Traditional Thalis'],
    tables: _buildTables(prefix: 'V', total: 24, occupied: 10, reserved: 6),
    menuImages: const [
      'https://images.pexels.com/photos/590743/pexels-photo-590743.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/1580543/pexels-photo-1580543.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    description:
        'Village Restaurant blends homestyle Mangalorean cooking with modern plating. Families love the quick seating and curated seafood spreads.',
    address: 'Village Restaurant, Balmatta Road, Mangalore',
    location: const GeoPoint(latitude: 12.8787, longitude: 74.8421),
    reviews: _buildReviews('village'),
  ),
  Restaurant(
    id: 'naadu-restaurant',
    ownerId: 'owner-2',
    name: 'Naadu Restaurant',
    cuisine: 'Udupi & Millet Kitchen',
    rating: 4.5,
    reviewCount: 389,
    distanceKm: 1.3,
    priceRange: r'₹250-350 per person',
    occupancyStatus: OccupancyStatus.empty,
    bannerImage:
        'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=1200',
    specialties: ['Millet Breakfasts', 'Filter Coffee Flights', 'Live Counters'],
    tables: _buildTables(prefix: 'N', total: 28, occupied: 4, reserved: 3),
    menuImages: const [
      'https://images.pexels.com/photos/247117/pexels-photo-247117.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/3535383/pexels-photo-3535383.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/221143/pexels-photo-221143.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    description:
        'Naadu celebrates seasonal produce from across Dakshina Kannada. Guests track table availability live and skip long breakfast queues.',
    address: 'Naadu Restaurant, Bendoorwell Junction, Mangalore',
    location: const GeoPoint(latitude: 12.8881, longitude: 74.8563),
    reviews: _buildReviews('naadu'),
  ),
  Restaurant(
    id: 'hotel-sai-palace',
    ownerId: 'owner-3',
    name: 'Hotel Sai Palace',
    cuisine: 'Multi-cuisine Family Dining',
    rating: 4.3,
    reviewCount: 512,
    distanceKm: 2.0,
    priceRange: r'₹350-500 per person',
    occupancyStatus: OccupancyStatus.full,
    bannerImage:
        'https://images.pexels.com/photos/262918/pexels-photo-262918.jpeg?auto=compress&cs=tinysrgb&w=1200',
    specialties: ['Tandoor Nights', 'Corporate Lunch Buffets', 'Chef’s Specials'],
    tables: _buildTables(prefix: 'S', total: 30, occupied: 22, reserved: 5),
    menuImages: const [
      'https://images.pexels.com/photos/1128678/pexels-photo-1128678.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    description:
        'Hotel Sai Palace keeps large groups flowing with dependable service, private dining rooms, and live tandoor counters.',
    address: 'Hotel Sai Palace, KSR Road, Hampankatta, Mangalore',
    location: const GeoPoint(latitude: 12.8723, longitude: 74.8429),
    reviews: _buildReviews('sai_palace'),
  ),
];

