import '../../models/booking.dart';
import '../../models/restaurant.dart';
class OwnerService {
  List<OwnerBooking> fetchUpcomingBookings(Restaurant restaurant) {
    final upcoming = <OwnerBooking>[
      OwnerBooking(
        id: 'b1',
        guestName: 'Anika Rao',
        partySize: 4,
        tableLabel: restaurant.tables[2].label,
        time: DateTime.now().add(const Duration(minutes: 45)),
      ),
      OwnerBooking(
        id: 'b2',
        guestName: 'Marco Li',
        partySize: 2,
        tableLabel: restaurant.tables[5].label,
        time: DateTime.now().add(const Duration(hours: 1, minutes: 10)),
        status: BookingStatus.confirmed,
      ),
      OwnerBooking(
        id: 'b3',
        guestName: 'Priya Desai',
        partySize: 6,
        tableLabel: restaurant.tables[9].label,
        time: DateTime.now().add(const Duration(hours: 2)),
        status: BookingStatus.pending,
      ),
    ];
    return upcoming;
  }
}