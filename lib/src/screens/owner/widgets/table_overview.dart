import 'package:flutter/material.dart';

import '../../../models/table_slot.dart';
import '../../../theme/app_theme.dart';

class TableOverview extends StatefulWidget {
  const TableOverview({super.key, required this.tables, this.onChanged});

  final List<TableSlot> tables;
  final ValueChanged<List<TableSlot>>? onChanged;

  @override
  State<TableOverview> createState() => _TableOverviewState();
}

class _TableOverviewState extends State<TableOverview> {
  late List<TableSlot> _tables;

  @override
  void initState() {
    super.initState();
    _tables = widget.tables.map((table) => table).toList();
  }

  @override
  void didUpdateWidget(covariant TableOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tables != widget.tables) {
      _tables = widget.tables.map((table) => table).toList();
    }
  }

  void _cycleStatus(int index) {
    final table = _tables[index];
    TableStatus next;
    switch (table.status) {
      case TableStatus.available:
        next = TableStatus.reserved;
        break;
      case TableStatus.reserved:
        next = TableStatus.occupied;
        break;
      case TableStatus.occupied:
        next = TableStatus.available;
        break;
    }

    setState(() {
      _tables[index] = table.copyWith(status: next);
    });
    widget.onChanged?.call(_tables);
  }

  Color _statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return AppColors.green;
      case TableStatus.reserved:
        return AppColors.yellow;
      case TableStatus.occupied:
        return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tables layout',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Layout editing coming soon.')),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _tables.length,
          itemBuilder: (context, index) {
            final table = _tables[index];
            final color = _statusColor(table.status);
            final foreground = table.status == TableStatus.reserved ? Colors.black87 : Colors.white;
            return GestureDetector(
              onTap: () => _cycleStatus(index),
              child: Container(
                decoration: BoxDecoration(
                  color: table.status == TableStatus.reserved
                      ? color.withValues(alpha: 0.85)
                      : color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 6)),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      table.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${table.seats} seats',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}