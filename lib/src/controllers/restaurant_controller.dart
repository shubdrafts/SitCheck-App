import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/mock_restaurants.dart';
import '../models/geo_point.dart';
import '../models/occupancy_status.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/table_slot.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/restaurant_service.dart';

class RestaurantController extends ChangeNotifier {
  RestaurantController() {
    _loadRestaurants();
  }

  final RestaurantService _service = RestaurantService();
  final List<Restaurant> _restaurants = [];
  bool _isLoading = true;

  StreamSubscription<List<Restaurant>>? _subscription;

  List<Restaurant> get restaurants => List.unmodifiable(_restaurants);
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.getRestaurantsStream().listen(
      (fetched) async {
        if (fetched.isEmpty && _restaurants.isEmpty) {
          for (final restaurant in mockRestaurants) {
            await _service.createRestaurant(restaurant);
          }
        } else {
          _restaurants.clear();
          // Fetch active bookings for each restaurant and merge
          for (final restaurant in fetched) {
            final withBookings = await _mergeBookingsIntoRestaurant(restaurant);
            _restaurants.add(withBookings);
          }
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('RestaurantController: Stream error: $e');
        if (_restaurants.isEmpty) {
          _restaurants.addAll(mockRestaurants);
        }
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<Restaurant> _mergeBookingsIntoRestaurant(Restaurant restaurant) async {
    try {
      final bookingService = BookingService();
      final activeBookings = await bookingService.fetchActiveBookings(restaurant.id);
      
      if (activeBookings.isEmpty) return restaurant;

      final updatedTables = restaurant.tables.map((table) {
        // Find if there's an active booking for this table
        final booking = activeBookings.firstWhere(
          (b) => b.tableLabel == table.id || b.tableLabel == table.label,
          orElse: () => OwnerBooking(
            id: '',
            guestName: '',
            partySize: 0,
            tableLabel: '',
            time: DateTime.now(),
            status: BookingStatus.pending,
          ),
        );

        if (booking.id.isNotEmpty) {
          // Map booking status to table status
          TableStatus newStatus;
          if (booking.status == BookingStatus.checkedIn) {
            newStatus = TableStatus.occupied;
          } else if (booking.status == BookingStatus.confirmed) {
            newStatus = TableStatus.reserved;
          } else {
            newStatus = table.status;
          }
          
          return table.copyWith(
            status: newStatus,
            lastUpdated: DateTime.now(),
          );
        }
        return table;
      }).toList();

      return restaurant.copyWith(tables: updatedTables);
    } catch (e) {
      debugPrint('RestaurantController: Failed to merge bookings: $e');
      return restaurant;
    }
  }

  /// Manually refresh restaurant data from the server
  Future<void> refresh() async {
    await _loadRestaurants();
  }

  /// Refresh a specific restaurant from the server
  Future<void> refreshRestaurant(String restaurantId) async {
    try {
      final updated = await _service.fetchRestaurantById(restaurantId);
      if (updated != null) {
        final withBookings = await _mergeBookingsIntoRestaurant(updated);
        _updateRestaurant(restaurantId, (_) => withBookings);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('RestaurantController: Failed to refresh restaurant: $e');
      rethrow;
    }
  }

  Restaurant getById(String id) {
    try {
      return _restaurants.firstWhere((restaurant) => restaurant.id == id);
    } catch (e) {
      if (_restaurants.isNotEmpty) return _restaurants.first;
      throw StateError('No restaurants available');
    }
  }

  Restaurant getByOwnerId(String ownerId) {
    try {
      return _restaurants.firstWhere((restaurant) => restaurant.ownerId == ownerId);
    } catch (e) {
      if (_restaurants.isNotEmpty) return _restaurants.first;
      throw StateError('No restaurants available');
    }
  }

  Restaurant? getByOwnerIdOrNull(String ownerId) {
    try {
      return _restaurants.firstWhere((restaurant) => restaurant.ownerId == ownerId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateTables(String restaurantId, List<TableSlot> tables) async {
    // Optimistic update
    _updateRestaurant(restaurantId, (r) => r.copyWith(tables: tables));

    try {
      await _service.updateRestaurantTables(restaurantId, tables);
      await refreshRestaurant(restaurantId);
    } catch (e) {
      debugPrint('RestaurantController: Failed to update tables: $e');
      // Revert optimistic update on failure (optional, but good practice)
      // For now, we rely on the next refresh to fix it, or we could fetch the old state.
      // Since we don't have the old state easily here without fetching, we'll just rethrow.
      // A more robust solution would be to pass the old tables or fetch them before update.
      rethrow;
    }
  }

  Future<void> addTable(String restaurantId, TableSlot table) async {
    final currentRestaurant = getById(restaurantId);
    final optimisticTables = [...currentRestaurant.tables, table];
    _updateRestaurant(restaurantId, (r) => r.copyWith(tables: optimisticTables));
    
    try {
      final freshRestaurant = await _service.fetchRestaurantById(restaurantId);
      if (freshRestaurant == null) throw Exception('Restaurant not found');
      
      final updatedTables = [...freshRestaurant.tables, table];
      await _service.updateRestaurantTables(restaurantId, updatedTables);
      
      // Refresh to merge bookings
      await refreshRestaurant(restaurantId);
    } catch (e) {
      _updateRestaurant(restaurantId, (r) => r.copyWith(tables: currentRestaurant.tables));
      rethrow;
    }
  }

  Future<void> removeTable(String restaurantId, String tableId) async {
    final currentRestaurant = getById(restaurantId);
    final optimisticTables =
        currentRestaurant.tables.where((table) => table.id != tableId).toList();
    _updateRestaurant(restaurantId, (r) => r.copyWith(tables: optimisticTables));

    try {
      final freshRestaurant = await _service.fetchRestaurantById(restaurantId);
      if (freshRestaurant == null) throw Exception('Restaurant not found');

      final updatedTables =
          freshRestaurant.tables.where((table) => table.id != tableId).toList();

      await _service.updateRestaurantTables(restaurantId, updatedTables);
      
      // Refresh to merge bookings
      await refreshRestaurant(restaurantId);
    } catch (e) {
      _updateRestaurant(restaurantId, (r) => r.copyWith(tables: currentRestaurant.tables));
      rethrow;
    }
  }

  Future<void> updateLocation(String restaurantId, GeoPoint location) async {
    try {
      await _service.updateRestaurantLocation(restaurantId, location);
      await refreshRestaurant(restaurantId);
    } catch (e) {
      debugPrint('RestaurantController: Failed to update location: $e');
      rethrow;
    }
  }

  Future<void> updateDetails(
    String restaurantId, {
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
      await _service.updateRestaurantDetails(
        restaurantId,
        name: name,
        cuisine: cuisine,
        description: description,
        priceRange: priceRange,
        bannerImage: bannerImage,
        menuImages: menuImages,
        specialties: specialties,
        address: address,
      );
      
      await refreshRestaurant(restaurantId);
    } catch (e) {
      debugPrint('RestaurantController: Failed to update details: $e');
      rethrow;
    }
  }

  Future<void> addReview(String restaurantId, Review review) async {
    try {
      await _service.addReview(restaurantId, review);
      await refreshRestaurant(restaurantId);
    } catch (e) {
      debugPrint('RestaurantController: Failed to add review: $e');
      rethrow;
    }
  }

  void updateTableStatus(
    String restaurantId,
    String tableId,
    TableStatus newStatus,
  ) {
    final restaurant = getById(restaurantId);
    final updatedTables = restaurant.tables
        .map(
          (table) => table.id == tableId
              ? table.copyWith(
                  status: newStatus,
                  lastUpdated: DateTime.now(),
                )
              : table,
        )
        .toList();
    updateTables(restaurantId, updatedTables);
  }

  void updateTableMetadata(
    String restaurantId, {
    required String tableId,
    String? label,
    int? seats,
  }) {
    final restaurant = getById(restaurantId);
    final updatedTables = restaurant.tables
        .map(
          (table) => table.id == tableId
              ? table.copyWith(
                  label: label,
                  seats: seats,
                )
              : table,
        )
        .toList();
    updateTables(restaurantId, updatedTables);
  }

  OccupancyStatus _deriveStatus(List<TableSlot> tables) {
    if (tables.isEmpty) return OccupancyStatus.empty;
    final occupied =
        tables.where((table) => table.status == TableStatus.occupied).length;
    final ratio = occupied / tables.length;
    if (ratio < 0.3) return OccupancyStatus.empty;
    if (ratio < 0.7) return OccupancyStatus.partial;
    return OccupancyStatus.full;
  }

  void _updateRestaurant(
    String restaurantId,
    Restaurant Function(Restaurant restaurant) transform,
  ) {
    final index =
        _restaurants.indexWhere((restaurant) => restaurant.id == restaurantId);
    if (index == -1) return;
    final updated = transform(_restaurants[index]);
    _restaurants[index] = updated;
    notifyListeners();
  }
}

