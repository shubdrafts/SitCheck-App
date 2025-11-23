import 'package:flutter/material.dart';

import '../../../models/restaurant.dart';
import '../../../theme/app_theme.dart';

class OccupancyCards extends StatelessWidget {
  const OccupancyCards({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final total = restaurant.totalTables;
    final available = restaurant.availableTables;
    final reserved = restaurant.reservedTables;
    final occupied = restaurant.occupiedTables;

    final occupancyPercent = total == 0 ? 0 : (occupied / total * 100).round();

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Availability',
            value: '$available tables',
            subtitle: 'Free right now',
            color: AppColors.green,
            icon: Icons.event_available,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Reserved',
            value: '$reserved tables',
            subtitle: 'Upcoming bookings',
            color: AppColors.yellow,
            icon: Icons.schedule,
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Occupancy',
            value: '$occupancyPercent%',
            subtitle: '$occupied of $total tables',
            color: AppColors.red,
            icon: Icons.local_fire_department,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.textColor = Colors.white,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}