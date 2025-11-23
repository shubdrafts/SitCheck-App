import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/restaurant_controller.dart';
import '../../core/session/session_controller.dart';
import '../../models/booking.dart';
import '../../models/restaurant.dart';
import '../../models/table_slot.dart';
import '../../models/user_role.dart';
import '../../services/booking_service.dart';
import '../../services/owner/owner_service.dart';
import '../auth/auth_decision_screen.dart';
import 'booking_history_screen.dart';
import 'widgets/booking_list.dart';
import 'widgets/occupancy_cards.dart';
import 'widgets/table_overview.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final OwnerService _service = OwnerService();
  final BookingService _bookingService = BookingService();
  List<OwnerBooking> _bookings = const [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  Future<void> _loadBookings() async {
    final restaurant = _currentRestaurant();
    try {
      final bookings = await _bookingService.fetchUpcomingBookings(restaurant.id);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
      });
    } catch (e) {
      // Fallback to mock service
      if (!mounted) return;
      setState(() {
        _bookings = _service.fetchUpcomingBookings(restaurant);
      });
    }
  }

  void _ensureOwner(BuildContext context) {
    final session = context.read<SessionController>().state;
    if (session.isGuest || session.role != UserRole.owner) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthDecisionScreen(role: UserRole.owner)),
        (_) => false,
      );
    }
  }

  void _handleTableChange(List<TableSlot> updated) {
    final restaurant = _currentRestaurant();
    context.read<RestaurantController>().updateTables(restaurant.id, updated);
  }

  Restaurant _currentRestaurant() {
    final session = context.read<SessionController>().state;
    final ownerId = session.profile?.id ?? 'owner-1';
    return context.read<RestaurantController>().getByOwnerId(ownerId);
  }

  Future<void> _quickUpdateOccupancy() async {
    setState(() => _isRefreshing = true);

    try {
      final restaurant = _currentRestaurant();
      final controller = context.read<RestaurantController>();

      // Refresh bookings
      await _loadBookings();

      // Refresh restaurant data from server to get latest table status
      await controller.refreshRestaurant(restaurant.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Occupancy updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureOwner(context);
    final session = context.watch<SessionController>().state;
    final ownerId = session.profile?.id ?? 'owner-1';
    final restaurant = context.watch<RestaurantController>().getByOwnerId(ownerId);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile settings coming soon')),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Occupancy overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          OccupancyCards(restaurant: restaurant),
          const SizedBox(height: 24),
          TableOverview(
            tables: restaurant.tables.map((table) {
              // Check for active bookings (confirmed and within +/- 2 hours)
              final now = DateTime.now();
              final hasActiveBooking = _bookings.any((b) {
                if (b.status != BookingStatus.confirmed) return false;
                if (b.tableLabel != table.label && b.tableLabel != table.id) return false;
                
                final diff = b.time.difference(now).inMinutes;
                // Consider active if booking is within next 2 hours or started less than 2 hours ago
                return diff >= -120 && diff <= 120;
              });

              if (hasActiveBooking) {
                return table.copyWith(status: TableStatus.occupied);
              }
              return table;
            }).toList(),
            onChanged: _handleTableChange,
          ),
          const SizedBox(height: 24),
          BookingList(
            bookings: _bookings,
            onStatusChanged: (id, status) async {
              try {
                await _bookingService.updateBookingStatus(id, status);
                
                // Auto-update table occupancy when booking is confirmed
                if (status == BookingStatus.confirmed) {
                  final booking = _bookings.firstWhere((b) => b.id == id);
                  final restaurant = _currentRestaurant();
                  final controller = context.read<RestaurantController>();
                  
                  final updatedTables = restaurant.tables.map((table) {
                    if (table.id == booking.tableLabel || table.label == booking.tableLabel) {
                      return table.copyWith(
                        status: TableStatus.occupied,
                        lastUpdated: DateTime.now(),
                      );
                    }
                    return table;
                  }).toList();
                  
                  await controller.updateTables(restaurant.id, updatedTables);
                }
                
                await _loadBookings();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update booking: ${e.toString()}')),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingHistoryScreen(restaurantId: restaurant.id),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('View booking history'),
          ),
          const SizedBox(height: 48),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRefreshing ? null : _quickUpdateOccupancy,
        icon: _isRefreshing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        label: Text(_isRefreshing ? 'Updating...' : 'Quick update'),
      ),
    );
  }
}