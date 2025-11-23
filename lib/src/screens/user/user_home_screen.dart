import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../controllers/restaurant_controller.dart';
import '../../models/geo_point.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_utils.dart';
import 'restaurant_detail_screen.dart';
import 'widgets/restaurant_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String query = '';
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final location = await LocationUtils.getCurrentLocation();
    if (mounted) {
      setState(() => _userLocation = location);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      query = value;
    });
  }

  double _calculateDistance(GeoPoint restaurantLocation) {
    if (_userLocation == null) {
      // Fallback to mock distance if location not available
      return 0.8; // Default mock distance
    }
    return LocationUtils.calculateDistance(_userLocation!, restaurantLocation);
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = context.watch<RestaurantController>().restaurants;
    final visibleRestaurants = restaurants
        .where(
          (restaurant) =>
              restaurant.name.toLowerCase().contains(query.toLowerCase()) ||
              restaurant.cuisine.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Know before you go',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a table in seconds',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search restaurants, cuisine, keywords',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search, color: AppColors.primaryRed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await context.read<RestaurantController>().refresh();
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: visibleRestaurants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final restaurant = visibleRestaurants[index];
                  // Calculate dynamic distance if user location is available
                  final dynamicDistance = _userLocation != null
                      ? _calculateDistance(restaurant.location)
                      : restaurant.distanceKm;
                  return RestaurantCard(
                    restaurant: restaurant.copyWith(distanceKm: dynamicDistance),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailScreen(
                            restaurant: restaurant.copyWith(distanceKm: dynamicDistance),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}