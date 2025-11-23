import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/restaurant_controller.dart';
import '../../core/session/session_controller.dart';
import '../../models/geo_point.dart';
import '../../models/restaurant.dart';
import '../../theme/app_theme.dart';

class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().state;
    final ownerId = session.profile?.id ?? 'owner-1';
    final restaurant = context.watch<RestaurantController>().getByOwnerId(ownerId);
    final initialPosition = CameraPosition(
      target: _toLatLng(restaurant.location),
      zoom: 15,
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: initialPosition,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              markers: {
                Marker(
                  markerId: MarkerId(restaurant.id),
                  position: _toLatLng(restaurant.location),
                  infoWindow: InfoWindow(title: restaurant.name),
                ),
              },
              onLongPress: (position) => _updateLocation(restaurant.id, position),
            ),
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: _OwnerMapPanel(
                restaurant: restaurant,
                onRecenter: () => _recenter(initialPosition.target),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recenter(LatLng target) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 15)),
    );
  }

  void _updateLocation(String restaurantId, LatLng position) {
    context.read<RestaurantController>().updateLocation(
          restaurantId,
          GeoPoint(latitude: position.latitude, longitude: position.longitude),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location updated for diners')),
    );
  }

  LatLng _toLatLng(GeoPoint point) => LatLng(point.latitude, point.longitude);
}

class _OwnerMapPanel extends StatelessWidget {
  const _OwnerMapPanel({required this.restaurant, required this.onRecenter});

  final Restaurant restaurant;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      elevation: 12,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              restaurant.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Press & hold on the map to move your pin. This updates user maps instantly.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lat: ${restaurant.location.latitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Lng: ${restaurant.location.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onRecenter,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Recenter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

