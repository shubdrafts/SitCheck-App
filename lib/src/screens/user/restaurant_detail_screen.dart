import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../controllers/restaurant_controller.dart';
import '../../core/session/session_controller.dart';
import '../../models/restaurant.dart';
import '../../models/review.dart';
import '../../models/table_slot.dart';
import '../../models/user_role.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_decision_screen.dart';
import 'widgets/add_review_dialog.dart';
import 'widgets/booking_sheet.dart';
import 'widgets/occupancy_chart.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh restaurant data when screen opens to ensure latest info
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantController>().refreshRestaurant(widget.restaurant.id).catchError((e) {
        debugPrint('Failed to refresh restaurant: $e');
      });
    });
  }

  Future<void> _openBookingSheet() async {
    final session = context.read<SessionController>().state;
    if (session.isGuest) {
      _promptSignIn(session.role);
      return;
    }

    final restaurant = _currentRestaurant();
    final userId = session.user?.id;
    if (userId == null) {
      _promptSignIn(session.role);
      return;
    }

    final bookingResult = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => BookingSheet(
        tables: restaurant.tables,
        restaurantId: restaurant.id,
        userId: userId,
      ),
    );

    if (bookingResult != null && bookingResult['tables'] != null) {
      if (!mounted) return;
      final updatedTables = bookingResult['tables'] as List<TableSlot>;
      await context.read<RestaurantController>().updateTables(restaurant.id, updatedTables);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed and saved successfully'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _showAddReviewDialog() async {
    final session = context.read<SessionController>().state;
    if (session.isGuest || session.user == null) {
      _promptSignIn(UserRole.user);
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddReviewDialog(),
    );

    if (result != null && mounted) {
      try {
        final review = Review(
          id: const Uuid().v4(),
          userId: session.user!.id,
          author: session.profile?.name ?? 'Anonymous',
          comment: result['comment'],
          rating: result['rating'],
          createdAt: DateTime.now(),
        );
        
        await context.read<RestaurantController>().addReview(widget.restaurant.id, review);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    }
  }

  void _promptSignIn(UserRole role) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in to book'),
        content: const Text('Guests can browse restaurants but need an account to reserve tables.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AuthDecisionScreen(role: role)),
              );
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  Restaurant _currentRestaurant() {
    final controller = context.read<RestaurantController>();
    return controller.restaurants.firstWhere(
      (restaurant) => restaurant.id == widget.restaurant.id,
      orElse: () => widget.restaurant,
    );
  }

  Future<void> _openDirections(Restaurant restaurant) async {
    const origin = 'Mangalore City, India';
    final encodedOrigin = Uri.encodeComponent(origin);
    final encodedDestination = Uri.encodeComponent(restaurant.address);
    final googleMapsAppUri = Uri.parse(
      'comgooglemaps://?saddr=$encodedOrigin&daddr=$encodedDestination&directionsmode=driving',
    );
    final webFallback = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$encodedOrigin&destination=$encodedDestination',
    );

    try {
      if (await canLaunchUrl(googleMapsAppUri)) {
        await launchUrl(googleMapsAppUri);
        return;
      }
      await launchUrl(webFallback, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open directions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RestaurantController>();
    final restaurant = controller.restaurants.firstWhere(
      (item) => item.id == widget.restaurant.id,
      orElse: () => widget.restaurant,
    );

    // Merge active bookings to show correct status
    // Note: Ideally this should be in the controller, but for now we do it here to match OwnerDashboard logic
    // We need to fetch bookings for this restaurant to do this accurately client-side if we want real-time updates
    // without relying solely on the 'tables' JSON which might lag.
    // However, since we don't have a stream of bookings here easily, we will rely on the controller's
    // refresh mechanism which we triggered in BookingSheet.
    // But to be safe, let's trust the 'tables' JSON which BookingService now updates.
    
    // Actually, let's stick to the plan: if the JSON update works, we don't need to merge here.
    // But if the user says "it's still green", maybe the JSON update IS failing or being overwritten.
    // Since I fixed the overwrite in BookingSheet, let's see if that's enough.
    // But to be EXTRA safe, let's add the merge logic if we have access to bookings.
    // We don't have bookings in this screen easily.
    // So I will rely on the fixes I just made to BookingSheet and BookingService.
    // If those work, the JSON will be correct.
    
    // Wait, I should check if I need to do anything here.
    // The previous code was just:
    /*
    final restaurant = controller.restaurants.firstWhere(
      (item) => item.id == widget.restaurant.id,
      orElse: () => widget.restaurant,
    );
    */
    // I will leave this file alone for now and verify if the previous two fixes solved it.
    // If not, I will come back and add booking fetching here.
    
    // Actually, I'll just return the original code since I'm not making changes yet.
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 260,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      restaurant.bannerImage,
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(restaurant.name),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(restaurant: restaurant),
                    const SizedBox(height: 24),
                    OccupancyChart(
                      available: restaurant.availableTables,
                      reserved: restaurant.reservedTables,
                      occupied: restaurant.occupiedTables,
                    ),
                    const SizedBox(height: 16),
                    _AvailabilitySummary(restaurant: restaurant),
                    const SizedBox(height: 24),
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      restaurant.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Specialties',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: restaurant.specialties
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Menu previews',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: restaurant.menuImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final image = restaurant.menuImages[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(image, width: 180, height: 140, fit: BoxFit.cover),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _showAddReviewDialog,
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Write a Review'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...restaurant.reviews.map((review) => _ReviewCard(review: review)),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(restaurant.address),
                      subtitle: Text('${restaurant.distanceKm.toStringAsFixed(1)} km away'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _openDirections(restaurant);
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Directions'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openBookingSheet,
                            icon: const Icon(Icons.event_seat),
                            label: const Text('Book Table'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber[700], size: 18),
            const SizedBox(width: 4),
            Text('${restaurant.rating.toStringAsFixed(1)} • ${restaurant.reviewCount} reviews'),
            const SizedBox(width: 12),
            const Text('•'),
            const SizedBox(width: 12),
            Text(restaurant.priceRange),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          restaurant.cuisine,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _AvailabilitySummary extends StatelessWidget {
  const _AvailabilitySummary({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AvailabilityPill(
          color: AppColors.green,
          label: 'Available',
          value: restaurant.availableTables,
        ),
        const SizedBox(width: 8),
        _AvailabilityPill(
          color: AppColors.yellow,
          label: 'Reserved',
          value: restaurant.reservedTables,
          darkText: true,
        ),
        const SizedBox(width: 8),
        _AvailabilityPill(
          color: AppColors.red,
          label: 'Occupied',
          value: restaurant.occupiedTables,
        ),
      ],
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({
    required this.color,
    required this.label,
    required this.value,
    this.darkText = false,
  });

  final Color color;
  final String label;
  final int value;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: darkText ? 0.2 : 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: darkText ? Colors.black87 : color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  review.author,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(review.rating.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              review.dateLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(review.comment),
          ],
        ),
      ),
    );
  }
}