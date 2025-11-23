import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  SupabaseClient get _client => Supabase.instance.client;
  final _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      return image;
    } catch (e) {
      return null;
    }
  }

  Future<String> uploadImage({
    required XFile file,
    required String bucket,
    required String fileName,
  }) async {
    final bytes = await file.readAsBytes();

    try {
      await _client.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
    } on StorageException catch (e) {
      if (e.message.contains('Bucket not found') || e.statusCode == '404') {
        // Try to create the bucket and retry
        try {
          await _client.storage.createBucket(bucket, const BucketOptions(public: true));
          // Retry upload
          await _client.storage.from(bucket).uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              );
        } catch (createError) {
          // If creation fails or retry fails, rethrow the original or new error
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final response = _client.storage.from(bucket).getPublicUrl(fileName);
    return response;
  }

  Future<String> uploadProfilePhoto(XFile file, String userId) async {
    final fileName = 'profiles/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(
      file: file,
      bucket: 'avatars',
      fileName: fileName,
    );
  }

  Future<String> uploadRestaurantBanner(XFile file, String restaurantId) async {
    final fileName = 'restaurants/$restaurantId/banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(
      file: file,
      bucket: 'restaurants',
      fileName: fileName,
    );
  }

  Future<String> uploadMenuImage(XFile file, String restaurantId) async {
    final fileName =
        'restaurants/$restaurantId/menu_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(
      file: file,
      bucket: 'restaurants',
      fileName: fileName,
    );
  }

  Future<void> deleteImage(String bucket, String fileName) async {
    await _client.storage.from(bucket).remove([fileName]);
  }
}

