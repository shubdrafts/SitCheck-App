enum TableStatus { available, selected, occupied }

class DiningTable {
  DiningTable({
    required this.id,
    required this.label,
    required this.seats,
    this.status = TableStatus.available,
  });

  final String id;
  final String label;
  final int seats;
  TableStatus status;
}

