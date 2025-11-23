import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/restaurant_controller.dart';
import '../../models/geo_point.dart';
import '../../models/occupancy_status.dart';
import '../../models/restaurant.dart';
import '../user/restaurant_detail_screen.dart';
import 'widgets/restaurant_card.dart';

class UserMapScreen extends StatefulWidget {
  const UserMapScreen({super.key});

  @override
  State<UserMapScreen> createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  @override
  Widget build(BuildContext context) {
    final restaurants = context.watch<RestaurantController>().restaurants;
    final initial = restaurants.isEmpty
        ? const CameraPosition(
            target: LatLng(37.7749, -122.4194),
            zoom: 13,
          )
        : CameraPosition(
            target: _toLatLng(restaurants.first.location),
            zoom: 13,
          );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: initial,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
              markers: restaurants.map(_buildMarker).toSet(),
            ),
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: _MapHeader(
                total: restaurants.length,
                onRecenter: () => _recenter(initial.target),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recenter(LatLng target) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 13)),
    );
  }

  Marker _buildMarker(Restaurant restaurant) {
    return Marker(
      markerId: MarkerId(restaurant.id),
      position: _toLatLng(restaurant.location),
      icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(restaurant.occupancyStatus)),
      onTap: () => _openSheet(restaurant),
    );
  }

  void _openSheet(Restaurant restaurant) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => _RestaurantBottomSheet(
        restaurant: restaurant,
        onDirections: () => _openDirections(restaurant),
        onViewDetails: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDirections(Restaurant restaurant) async {
    final point = restaurant.location;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps')),
      );
    }
  }

  double _markerHue(OccupancyStatus status) {
    switch (status) {
      case OccupancyStatus.empty:
        return BitmapDescriptor.hueGreen;
      case OccupancyStatus.partial:
        return BitmapDescriptor.hueYellow;
      case OccupancyStatus.full:
        return BitmapDescriptor.hueRed;
    }
  }

  LatLng _toLatLng(GeoPoint point) => LatLng(point.latitude, point.longitude);
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.total, required this.onRecenter});

  final int total;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live map',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('$total restaurants nearby'),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: onRecenter,
              icon: const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantBottomSheet extends StatelessWidget {
  const _RestaurantBottomSheet({
    required this.restaurant,
    required this.onDirections,
    required this.onViewDetails,
  });

  final Restaurant restaurant;
  final VoidCallback onDirections;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.cuisine,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount})'),
                      ],
                    ),
                  ],
                ),
              ),
              OccupancyBadge(status: restaurant.occupancyStatus),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Directions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

