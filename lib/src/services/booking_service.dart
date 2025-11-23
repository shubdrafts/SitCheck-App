import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';

class BookingService {
  final SupabaseClient _client = Supabase.instance.client;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  Future<String> createBooking({
    String? userId,
    required String restaurantId,
    required String tableId,
    required String guestName,
    required String guestPhone,
    required int partySize,
    required DateTime bookingDateTime,
    String? imagePath,
    String? notes,
  }) async {
    final date = _dateFormatter.format(bookingDateTime);
    final time = _timeFormatter.format(bookingDateTime);
    final slotKey = '$date|$time';

    try {
      // 1. Insert booking into Supabase
      final response = await _client.from('bookings').insert({
        'user_id': userId,
        'restaurant_id': restaurantId,
        'table_id': tableId,
        'guest_name': guestName,
        'guest_phone': guestPhone,
        'guest_count': partySize,
        'booking_date': date,
        'booking_time': time,
        'slot_key': slotKey,
        'status': BookingStatus.confirmed.name, // Auto-confirm for now
        'image_path': imagePath,
        'notes': notes,
      }).select().single();

      // 2. Update restaurant table status to 'occupied' in the JSON column
      // We need to fetch the current restaurant, find the table, update its status, and save back.
      final restaurantData = await _client
          .from('restaurants')
          .select('tables, occupancy_status')
          .eq('id', restaurantId)
          .single();

      final List<dynamic> tablesJson = restaurantData['tables'] ?? [];
      final updatedTables = tablesJson.map((t) {
        if (t['id'] == tableId || t['label'] == tableId) {
          return {
            ...t,
            'status': 'reserved',
            'last_updated': DateTime.now().toIso8601String(),
          };
        }
        return t;
      }).toList();

      await _client.from('restaurants').update({
        'tables': updatedTables,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', restaurantId);

      return response['id'].toString();
    } catch (e) {
      debugPrint('BookingService: Failed to create booking: $e');
      rethrow;
    }
  }

  Future<List<OwnerBooking>> fetchUpcomingBookings(String restaurantId) async {
    try {
      final now = DateTime.now();
      final today = _dateFormatter.format(now);
      
      final response = await _client
          .from('bookings')
          .select()
          .eq('restaurant_id', restaurantId)
          .gte('booking_date', today)
          .order('booking_date', ascending: true)
          .order('booking_time', ascending: true);

      return (response as List).map((row) => _mapToOwnerBooking(row)).toList();
    } catch (e) {
      debugPrint('BookingService: Failed to fetch upcoming bookings: $e');
      return [];
    }
  }

  Future<List<OwnerBooking>> fetchBookingHistory(String restaurantId) async {
    try {
      final now = DateTime.now();
      final today = _dateFormatter.format(now);

      final response = await _client
          .from('bookings')
          .select()
          .eq('restaurant_id', restaurantId)
          .lte('booking_date', today)
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false)
          .limit(50);

      final bookings = (response as List).map((row) => _mapToOwnerBooking(row)).toList();
      
      return bookings.where((b) => b.time.isBefore(now)).toList();
    } catch (e) {
      debugPrint('BookingService: Failed to fetch booking history: $e');
      return [];
    }
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _client.from('bookings').update({
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      debugPrint('BookingService: Failed to update booking status: $e');
      rethrow;
    }
  }

  Future<List<OwnerBooking>> fetchActiveBookings(String restaurantId) async {
    try {
      final now = DateTime.now();
      final today = _dateFormatter.format(now);
      
      // Try fetching from main table first (works for owners)
      try {
        final response = await _client
            .from('bookings')
            .select()
            .eq('restaurant_id', restaurantId)
            .eq('booking_date', today)
            .inFilter('status', ['confirmed', 'reserved', 'occupied', 'checkedIn']);
        
        if ((response as List).isNotEmpty) {
          return (response).map((row) => _mapToOwnerBooking(row)).toList();
        }
      } catch (_) {
        // Ignore error and fall back to public view
      }

      // Fallback to public_bookings view (works for everyone)
      final publicResponse = await _client
          .from('public_bookings')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('booking_date', today);

      return (publicResponse as List).map((row) => _mapToOwnerBooking(row)).toList();
    } catch (e) {
      debugPrint('BookingService: Failed to fetch active bookings: $e');
      return [];
    }
  }

  OwnerBooking _mapToOwnerBooking(Map<String, dynamic> row) {
    final date = row['booking_date'] as String? ?? '';
    final time = row['booking_time'] as String? ?? '00:00';
    final combined = '$date $time';
    final timestamp =
        DateFormat('yyyy-MM-dd HH:mm').tryParse(combined) ?? DateTime.now();

    return OwnerBooking(
      id: row['id'].toString(),
      guestName: row['guest_name'] as String? ?? 'Guest',
      partySize: (row['guest_count'] as int?) ?? 1,
      tableLabel: (row['table_label'] ?? row['table_id'] ?? '') as String,
      time: timestamp,
      status: _bookingStatusFromString(row['status'] as String? ?? 'pending'),
      guestPhone: row['guest_phone'] as String?,
      imagePath: row['image_path'] as String?,
    );
  }

  BookingStatus _bookingStatusFromString(String value) {
    switch (value) {
      case 'confirmed':
      case 'reserved':
        return BookingStatus.confirmed;
      case 'occupied':
      case 'checkedIn':
        return BookingStatus.checkedIn;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
}