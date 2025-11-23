import '../models/dining_table.dart';

final mockTablesByRestaurant = <String, List<DiningTable>>{
  '1': List.generate(
    20,
    (index) => DiningTable(
      id: '1-${index + 1}',
      label: 'T${index + 1}',
      seats: index.isEven ? 4 : 2,
      status: index < 12
          ? TableStatus.occupied
          : index < 16
              ? TableStatus.selected
              : TableStatus.available,
    ),
  ),
  '2': List.generate(
    12,
    (index) => DiningTable(
      id: '2-${index + 1}',
      label: 'L${index + 1}',
      seats: 4,
      status: index < 4 ? TableStatus.occupied : TableStatus.available,
    ),
  ),
  '3': List.generate(
    24,
    (index) => DiningTable(
      id: '3-${index + 1}',
      label: 'A${index + 1}',
      seats: 2 + (index % 3) * 2,
      status: index < 20 ? TableStatus.occupied : TableStatus.available,
    ),
  ),
};

