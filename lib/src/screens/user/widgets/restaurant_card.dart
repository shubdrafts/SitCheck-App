import 'package:flutter/material.dart';

import '../../../models/occupancy_status.dart';
import '../../../models/restaurant.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/network_cover_image.dart';

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
  });

  final Restaurant restaurant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkCoverImage(
              imageUrl: restaurant.bannerImage,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              aspectRatio: 16 / 9,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              restaurant.cuisine,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      OccupancyBadge(status: restaurant.occupancyStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 4),
                      Text('${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount})'),
                      const Spacer(),
                      Text(restaurant.priceRange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 18, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text('${restaurant.distanceKm.toStringAsFixed(1)} km • Nearby'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: restaurant.specialties
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: AppColors.beige,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OccupancyBadge extends StatelessWidget {
  const OccupancyBadge({super.key, required this.status});

  final OccupancyStatus status;

  Color get _color {
    switch (status) {
      case OccupancyStatus.empty:
        return AppColors.green;
      case OccupancyStatus.partial:
        return AppColors.yellow;
      case OccupancyStatus.full:
        return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _color.darken(),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

extension _ColorUtils on Color {
  Color darken([double amount = .15]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}