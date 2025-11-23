import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/session_controller.dart';
import '../../models/profile.dart';
import '../../models/user_role.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_decision_screen.dart';
import '../common/role_selection_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();
  final _storageService = StorageService();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  String? _photoUrl;
  XFile? _pickedFile;
  bool _isUploadingPhoto = false;
  Profile? _lastProfile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<SessionController>().state.profile;
    if (profile != null && profile != _lastProfile) {
      _lastProfile = profile;
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phoneNumber ?? '';
      _bioController.text = profile.bio ?? '';
      _photoUrl = profile.profilePhoto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().state;
    final Profile? profile = session.profile;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primaryRed,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your profile',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep your dining identity up to date',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.lightText,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            if (session.isGuest)
              _GuestPrompt(
                onSignIn: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthDecisionScreen(role: UserRole.user)),
                ),
              )
            else if (profile != null)
              _ProfileForm(
                formKey: _formKey,
                nameController: _nameController,
                emailController: _emailController,
                phoneController: _phoneController,
                bioController: _bioController,
                photoUrl: _photoUrl,
                pickedFile: _pickedFile,
                isUploadingPhoto: _isUploadingPhoto,
                onPhotoTap: _openPhotoDialog,
                role: profile.role,
                onSave: () => _saveProfile(context),
                onSignOut: () => _handleSignOut(context),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _openPhotoDialog() async {
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
      final controller = TextEditingController(text: _photoUrl);
      final value = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update profile photo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Paste an image URL'),
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
        setState(() => _photoUrl = value);
      }
      return;
    }

    // Handle image picker (gallery or camera)
    setState(() => _isUploadingPhoto = true);
    try {
      final image = await _storageService.pickImage(source);
      if (image != null && mounted) {
        setState(() => _pickedFile = image);
        
        // Upload to Supabase Storage
        final session = context.read<SessionController>().state;
        final userId = session.profile?.id;
        if (userId != null) {
          final uploadedUrl = await _storageService.uploadProfilePhoto(image, userId);
          if (!mounted) return;
          setState(() {
            _photoUrl = uploadedUrl;
            _isUploadingPhoto = false;
          });
          
          // Auto-save photo URL to profile immediately
          final currentProfile = session.profile;
          if (currentProfile != null) {
            final profileWithPhoto = currentProfile.copyWith(profilePhoto: uploadedUrl);
            try {
              await _service.updateProfile(profileWithPhoto);
              if (mounted) {
                context.read<SessionController>().updateProfile(profileWithPhoto);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo uploaded successfully'),
                    backgroundColor: AppColors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              // Photo is uploaded but profile update failed - user can save manually
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Photo uploaded. Click save to update profile.'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          }
        } else {
          setState(() => _isUploadingPhoto = false);
        }
      } else {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<SessionController>().state;
    if (session.isGuest) return;

    final profile = session.profile;
    if (profile == null) return;

    final updated = profile.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      profilePhoto: _photoUrl ?? profile.profilePhoto, // Preserve existing photo if no new upload
    );

    try {
      setState(() => _isUploadingPhoto = true); // Show loading
      await _service.updateProfile(updated);
      if (!mounted) return;
      context.read<SessionController>().updateProfile(updated);
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated successfully'),
            ],
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      
      if (e.code == 'PGRST205') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Setup Required'),
            content: const Text(
              'The "profiles" table is missing in your database.\n\n'
              'Please run the "create_profiles_table.sql" script in your Supabase Dashboard SQL Editor to fix this.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update: ${e.message}')),
              ],
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('An unexpected error occurred: $e')),
            ],
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
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

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are exploring as a guest',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create an account to sync bookings, update your profile photo, and save favorite spots.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSignIn,
              child: const Text('Create account'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.bioController,
    required this.photoUrl,
    this.pickedFile,
    this.isUploadingPhoto = false,
    required this.onPhotoTap,
    required this.role,
    required this.onSave,
    required this.onSignOut,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController bioController;
  final String? photoUrl;
  final XFile? pickedFile;
  final bool isUploadingPhoto;
  final VoidCallback onPhotoTap;
  final UserRole role;
  final VoidCallback onSave;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primaryRed.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: onPhotoTap,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.beige,
                      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                          ? NetworkImage(photoUrl!)
                          : pickedFile != null
                              ? (kIsWeb
                                  ? NetworkImage(pickedFile!.path)
                                  : FileImage(File(pickedFile!.path))) as ImageProvider
                              : null,
                      child: (photoUrl == null || photoUrl!.isEmpty) && pickedFile == null
                          ? Icon(Icons.camera_alt_outlined, color: AppColors.lightText, size: 32)
                          : null,
                    ),
                  ),
                  if (isUploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onPhotoTap,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Change photo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: nameController,
            label: 'Name',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: phoneController,
            label: 'Phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: bioController,
            label: 'Bio',
            icon: Icons.description_outlined,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSave(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.badge_outlined, color: AppColors.primaryRed),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Account type', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Text(role.displayName, style: TextStyle(color: AppColors.lightText)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUploadingPhoto ? null : onSave,
              icon: isUploadingPhoto
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 20),
              label: Text(isUploadingPhoto ? 'Saving...' : 'Save changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: isUploadingPhoto ? null : onSignOut,
            icon: const Icon(Icons.logout_outlined, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryRed),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}

