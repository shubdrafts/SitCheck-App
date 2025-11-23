enum BookingStatus { pending, confirmed, checkedIn, cancelled, completed }

class OwnerBooking {
  const OwnerBooking({
    required this.id,
    required this.guestName,
    required this.partySize,
    required this.tableLabel,
    required this.time,
    this.status = BookingStatus.pending,
    this.guestPhone,
    this.imagePath,
  });

  final String id;
  final String guestName;
  final int partySize;
  final String tableLabel;
  final DateTime time;
  final BookingStatus status;
  final String? guestPhone;
  final String? imagePath;

  OwnerBooking copyWith({BookingStatus? status}) {
    return OwnerBooking(
      id: id,
      guestName: guestName,
      partySize: partySize,
      tableLabel: tableLabel,
      time: time,
      status: status ?? this.status,
      guestPhone: guestPhone,
      imagePath: imagePath,
    );
  }
}

