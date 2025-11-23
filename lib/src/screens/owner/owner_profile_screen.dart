import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/restaurant_controller.dart';
import '../../core/session/session_controller.dart';
import '../../models/profile.dart';
import '../../models/restaurant.dart';
import '../../models/table_slot.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../common/role_selection_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _ownerFormKey = GlobalKey<FormState>();
  final _restaurantFormKey = GlobalKey<FormState>();
  final _service = SupabaseService();
  final _storageService = StorageService();

  late TextEditingController _ownerNameController;
  late TextEditingController _ownerPhoneController;
  late TextEditingController _restaurantNameController;
  late TextEditingController _cuisineController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _bannerController;
  final TextEditingController _specialtyController = TextEditingController();

  Profile? _profile;
  String? _restaurantId;
  List<String> _menuImages = [];
  List<String> _specialties = [];
  XFile? _pickedBanner;
  bool _isUploadingBanner = false;
  bool _isUploadingMenu = false;
  bool _isSaving = false;
  bool _ownerInitialized = false;
  bool _restaurantInitialized = false;

  @override
  void initState() {
    super.initState();
    _ownerNameController = TextEditingController();
    _ownerPhoneController = TextEditingController();
    _restaurantNameController = TextEditingController();
    _cuisineController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _bannerController = TextEditingController();
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _restaurantNameController.dispose();
    _cuisineController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _bannerController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().state;
    final profile = session.profile;
    final ownerId = profile?.id ?? 'owner-1';
    final restaurant = context.watch<RestaurantController>().getByOwnerId(ownerId);
    _initializeOwner(profile);
    _initializeRestaurant(restaurant);

    return SafeArea(
      child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your contact info plus restaurant branding, menus, and layout.',
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'Owner contact',
                    child: Form(
                      key: _ownerFormKey,
                      child: Column(
                        children: [
                            TextFormField(
                              controller: _ownerNameController,
                              decoration: const InputDecoration(labelText: 'Owner name'),
                              textInputAction: TextInputAction.next,
                              validator: (value) => value == null || value.isEmpty ? 'Enter owner name' : null,
                            ),
                          const SizedBox(height: 12),
                            TextFormField(
                              controller: _ownerPhoneController,
                              decoration: const InputDecoration(labelText: 'Contact number'),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                            ),
                          const SizedBox(height: 12),
                          if (profile != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.email_outlined),
                              title: const Text('Login email'),
                              subtitle: Text(profile.email),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'Restaurant identity',
                    child: Form(
                      key: _restaurantFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            TextFormField(
                              controller: _restaurantNameController,
                              decoration: const InputDecoration(labelText: 'Restaurant name'),
                              textInputAction: TextInputAction.next,
                              validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                            ),
                          const SizedBox(height: 12),
                            TextFormField(
                              controller: _cuisineController,
                              decoration: const InputDecoration(labelText: 'Cuisine type'),
                              textInputAction: TextInputAction.next,
                            ),
                          const SizedBox(height: 12),
                            TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: 'Pricing range'),
                              textInputAction: TextInputAction.next,
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Description / bio'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bannerController,
                                  decoration: const InputDecoration(labelText: 'Banner image URL'),
                                  enabled: !_isUploadingBanner,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _isUploadingBanner ? null : _pickBannerImage,
                                icon: _isUploadingBanner
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.image),
                                label: const Text('Upload'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _pickedBanner != null
                                ? (kIsWeb
                                    ? Image.network(
                                        _pickedBanner!.path,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_pickedBanner!.path),
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ))
                                : Image.network(
                                    _bannerController.text.isNotEmpty
                                        ? _bannerController.text
                                        : 'https://via.placeholder.com/800x400',
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 160,
                                      color: AppColors.beige,
                                      alignment: Alignment.center,
                                      child: const Text('Preview unavailable'),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'Specialties',
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addSpecialty,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _specialties
                          .map(
                            (tag) => InputChip(
                              label: Text(tag),
                              onDeleted: () => setState(() => _specialties.remove(tag)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'Menu gallery',
                    trailing: _isUploadingMenu
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            onPressed: _addMenuImage,
                          ),
                    child: SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _menuImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final image = _menuImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  image,
                                  width: 160,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 160,
                                    height: 140,
                                    color: AppColors.beige,
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 32, color: Colors.grey),
                                        SizedBox(height: 4),
                                        Text('Failed to load', style: TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _menuImages.removeAt(index)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'Table layout',
                    trailing: IconButton(
                      icon: const Icon(Icons.table_bar_outlined),
                      onPressed: () => _openAddTableDialog(restaurant.id),
                    ),
                    child: Column(
                      children: restaurant.tables
                          .map(
                            (table) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.beige,
                                child: Text(table.label),
                              ),
                              title: Text('${table.seats} seats'),
                              subtitle: Text(table.status.name),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openEditTableDialog(restaurant.id, table);
                                  } else if (value == 'delete') {
                                    context.read<RestaurantController>().removeTable(restaurant.id, table.id).catchError((e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to delete table: ${e.toString()}')),
                                      );
                                    });
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit seats')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete table')),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _save(restaurant.id),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _handleSignOut(context),
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('Sign out'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _addSpecialty() async {
    _specialtyController.clear();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add specialty'),
        content: TextField(
          controller: _specialtyController,
          decoration: const InputDecoration(hintText: 'e.g. Chef’s tasting'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_specialtyController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (value != null && value.isNotEmpty) {
      if (!mounted) return;
      setState(() => _specialties.add(value));
    }
  }

  Future<void> _pickBannerImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Paste image URL'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      // URL input fallback
      final controller = TextEditingController(text: _bannerController.text);
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Banner image URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Paste image URL'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (value != null && mounted) {
        setState(() => _bannerController.text = value);
      }
      return;
    }

    setState(() => _isUploadingBanner = true);
    try {
      final image = await _storageService.pickImage(source);
      if (image != null && mounted) {
        setState(() => _pickedBanner = image);

        final restaurant = context.read<RestaurantController>().getByOwnerId(
              context.read<SessionController>().state.profile?.id ?? 'owner-1',
            );
        final uploadedUrl =
            await _storageService.uploadRestaurantBanner(image, restaurant.id);
        if (!mounted) return;
        setState(() {
          _bannerController.text = uploadedUrl;
          _isUploadingBanner = false;
        });
      } else {
        if (mounted) setState(() => _isUploadingBanner = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingBanner = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload banner: ${e.toString()}')),
      );
    }
  }



  Future<void> _addMenuImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Paste image URL'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      // URL input fallback
      final controller = TextEditingController();
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add menu image'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Paste image URL'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        ),
      );

      if (value != null && value.isNotEmpty && mounted) {
        setState(() => _menuImages.add(value));
      }
      return;
    }

    setState(() => _isUploadingMenu = true);
    try {
      final image = await _storageService.pickImage(source);
      if (image != null && mounted) {
        final restaurant = context.read<RestaurantController>().getByOwnerId(
              context.read<SessionController>().state.profile?.id ?? 'owner-1',
            );
        final uploadedUrl = await _storageService.uploadMenuImage(image, restaurant.id);
        if (!mounted) return;
        setState(() {
          _menuImages.add(uploadedUrl);
          _isUploadingMenu = false;
        });
      } else {
        if (mounted) setState(() => _isUploadingMenu = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingMenu = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
    }
  }

  Future<void> _openAddTableDialog(String restaurantId) async {
    final labelController = TextEditingController();
    final seatsController = TextEditingController(text: '4');
    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label (e.g. T21)'),
            ),
            TextField(
              controller: seatsController,
              decoration: const InputDecoration(labelText: 'Seats'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final seats = int.tryParse(seatsController.text.trim()) ?? 4;
              Navigator.of(context).pop((labelController.text.trim(), seats));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (!mounted) return;
      final (label, seats) = result;
      if (label.isEmpty) return;
      await context.read<RestaurantController>().addTable(
            restaurantId,
            TableSlot(id: label, label: label, seats: seats),
          );
    }
  }

  Future<void> _openEditTableDialog(String restaurantId, TableSlot table) async {
    final seatsController = TextEditingController(text: table.seats.toString());
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${table.label}'),
        content: TextField(
          controller: seatsController,
          decoration: const InputDecoration(labelText: 'Seats'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final seats = int.tryParse(seatsController.text.trim()) ?? table.seats;
              Navigator.of(context).pop(seats);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (!mounted) return;
      context.read<RestaurantController>().updateTableMetadata(
            restaurantId,
            tableId: table.id,
            seats: result,
          );
    }
  }

  Future<void> _save(String restaurantId) async {
    if (!_ownerFormKey.currentState!.validate() || !_restaurantFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = context.read<SessionController>().state;
      final profile = session.profile;
      
      // Update owner profile
      if (profile != null) {
        final updated = profile.copyWith(
          name: _ownerNameController.text.trim(),
          phoneNumber: _ownerPhoneController.text.trim(),
        );
        final service = SupabaseService();
        await service.updateProfile(updated);
        context.read<SessionController>().updateProfile(updated);
      }

      // Update restaurant details
      await context.read<RestaurantController>().updateDetails(
            restaurantId,
            name: _restaurantNameController.text.trim(),
            cuisine: _cuisineController.text.trim(),
            priceRange: _priceController.text.trim(),
            description: _descriptionController.text.trim(),
            bannerImage: _bannerController.text.trim(),
            menuImages: _menuImages,
            specialties: _specialties,
          );

      // Explicitly refresh to ensure latest data is loaded
      await context.read<RestaurantController>().refreshRestaurant(restaurantId);

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Changes saved and synced'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          backgroundColor: AppColors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _initializeOwner(Profile? profile) {
    if (profile == null) return;
    if (!_ownerInitialized || profile.id != _profile?.id) {
      _profile = profile;
      _ownerNameController.text = profile.name;
      _ownerPhoneController.text = profile.phoneNumber ?? '';
      _ownerInitialized = true;
    }
  }

  void _initializeRestaurant(Restaurant restaurant) {
    if (!_restaurantInitialized || _restaurantId != restaurant.id) {
      _restaurantInitialized = true;
      _restaurantId = restaurant.id;
      _restaurantNameController.text = restaurant.name;
      _cuisineController.text = restaurant.cuisine;
      _priceController.text = restaurant.priceRange;
      _descriptionController.text = restaurant.description;
      _bannerController.text = restaurant.bannerImage;
      _menuImages = List.of(restaurant.menuImages);
      _specialties = List.of(restaurant.specialties);
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.signOut();
        if (!mounted) return;
        context.read<SessionController>().signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (_) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

