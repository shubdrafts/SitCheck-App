enum OccupancyStatus { empty, partial, full }

extension OccupancyStatusX on OccupancyStatus {
  String get label {
    switch (this) {
      case OccupancyStatus.empty:
        return 'Empty';
      case OccupancyStatus.partial:
        return 'Partial';
      case OccupancyStatus.full:
        return 'Full';
    }
  }
}