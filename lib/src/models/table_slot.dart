enum TableStatus { available, reserved, occupied }

class TableSlot {
  const TableSlot({
    required this.id,
    required this.label,
    this.seats = 4,
    this.status = TableStatus.available,
    this.lastUpdated,
  });

  final String id;
  final String label;
  final int seats;
  final TableStatus status;
  final DateTime? lastUpdated;

  TableSlot copyWith({
    TableStatus? status,
    int? seats,
    String? label,
    DateTime? lastUpdated,
  }) {
    return TableSlot(
      id: id,
      label: label ?? this.label,
      seats: seats ?? this.seats,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

