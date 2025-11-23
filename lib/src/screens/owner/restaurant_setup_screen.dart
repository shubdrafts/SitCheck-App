import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/restaurant_controller.dart';
import '../../core/session/session_controller.dart';
import '../../models/geo_point.dart';
import '../../models/occupancy_status.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import 'owner_shell.dart';

class RestaurantSetupScreen extends StatefulWidget {
  const RestaurantSetupScreen({super.key});

  @override
  State<RestaurantSetupScreen> createState() => _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends State<RestaurantSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceRangeController = TextEditingController(text: r'$$');
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceRangeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final session = context.read<SessionController>().state;
      final userId = session.user?.id;
      if (userId == null) throw Exception('User not authenticated');

      final service = RestaurantService();
      
      // Create a new restaurant object
      final newRestaurant = Restaurant(
        id: '${DateTime.now().millisecondsSinceEpoch}-${userId.substring(0, 4)}', // Unique ID
        ownerId: userId,
        name: _nameController.text.trim(),
        cuisine: _cuisineController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        priceRange: _priceRangeController.text.trim(),
        rating: 0.0,
        reviewCount: 0,
        distanceKm: 0.0,
        occupancyStatus: OccupancyStatus.empty,
        bannerImage: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        menuImages: [],
        specialties: [],
        tables: [],
        location: const GeoPoint(latitude: 12.9141, longitude: 74.8560),
        reviews: [],
      );

      await service.createRestaurant(newRestaurant);
      
      // No need to navigate manually. 
      // The RestaurantController stream will pick up the new restaurant,
      // notify the OwnerShell, and it will automatically switch to the Dashboard.
      // We keep loading state true until this widget is disposed.
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create restaurant: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Restaurant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome! Let\'s set up your restaurant.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Enter the basic details to get started.'),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _cuisineController,
                decoration: const InputDecoration(
                  labelText: 'Cuisine (e.g. Italian, Indian)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about your place...',
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _priceRangeController.text,
                decoration: const InputDecoration(
                  labelText: 'Price Range',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: r'$', child: Text(r'Budget ($)')),
                  DropdownMenuItem(value: r'$$', child: Text(r'Moderate ($$)')),
                  DropdownMenuItem(value: r'$$$', child: Text(r'Expensive ($$$)')),
                  DropdownMenuItem(value: r'$$$$', child: Text(r'Luxury ($$$$)')),
                ],
                onChanged: (v) {
                  if (v != null) _priceRangeController.text = v;
                },
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Restaurant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
