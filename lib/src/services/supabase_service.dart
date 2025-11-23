import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/user_role.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;
  static const _defaultAvatar =
      'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=800';

  Future<(User, Profile)> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role.name},
    );

    final user = authResponse.user;
    if (user == null) {
      throw const AuthException('Unable to create account.');
    }

    final profile = Profile(
      id: user.id,
      email: email,
      name: name,
      role: role,
      bio: 'Excited to explore new dining spots.',
      phoneNumber: '',
      profilePhoto: _defaultAvatar,
    );

    await _ensureProfileExists(profile);
    return (user, profile);
  }

  Future<(User, Profile)> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Invalid credentials');
    }

    try {
      final profile = await fetchProfile(user.id);
      return (user, profile);
    } on PostgrestException {
      final fallback = _profileFromUser(user);
      await _ensureProfileExists(fallback);
      return (user, fallback);
    }
  }

  Future<Profile> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) {
      throw const AuthException('Profile missing');
    }
    return Profile.fromJson(data);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> updateProfile(Profile profile) async {
    await _client.from('profiles').upsert(profile.toJson());
  }

  Future<void> _ensureProfileExists(Profile profile) async {
    await _client.from('profiles').upsert(profile.toJson()).catchError((_) => null);
  }

  Profile _profileFromUser(User user) {
    final metadata = user.userMetadata ?? {};
    return Profile(
      id: user.id,
      email: user.email ?? '',
      name: (metadata['name'] as String?) ?? user.email ?? '',
      role: (metadata['role'] as String?) == UserRole.owner.name ? UserRole.owner : UserRole.user,
      bio: metadata['bio'] as String?,
      phoneNumber: metadata['phoneNumber'] as String?,
      profilePhoto: metadata['profilePhoto'] as String? ?? _defaultAvatar,
    );
  }
}