import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../models/user_role.dart';

class SessionState {
  const SessionState._({
    required this.role,
    required this.isGuest,
    this.user,
    this.profile,
  });

  final UserRole role;
  final bool isGuest;
  final User? user;
  final Profile? profile;

  factory SessionState.guest(UserRole role) => SessionState._(
        role: role,
        isGuest: true,
      );

  factory SessionState.authenticated({
    required UserRole role,
    required User user,
    required Profile profile,
  }) =>
      SessionState._(
        role: role,
        user: user,
        profile: profile,
        isGuest: false,
      );

  SessionState copyWith({
    UserRole? role,
    bool? isGuest,
    User? user,
    Profile? profile,
  }) {
    return SessionState._(
      role: role ?? this.role,
      isGuest: isGuest ?? this.isGuest,
      user: user ?? this.user,
      profile: profile ?? this.profile,
    );
  }
}

class SessionController extends ChangeNotifier {
  SessionState _state = SessionState.guest(UserRole.user);

  SessionState get state => _state;

  void setGuest(UserRole role) {
    _state = SessionState.guest(role);
    notifyListeners();
  }

  void setAuthenticated(User user, Profile profile) {
    _state = SessionState.authenticated(role: profile.role, user: user, profile: profile);
    notifyListeners();
  }

  void updateProfile(Profile profile) {
    _state = _state.copyWith(profile: profile, role: profile.role);
    notifyListeners();
  }

  void updateProfileFields({
    String? name,
    String? email,
    String? bio,
    String? phoneNumber,
    String? profilePhoto,
  }) {
    final current = _state.profile;
    if (current == null) return;
    final updated = current.copyWith(
      name: name,
      email: email,
      bio: bio,
      phoneNumber: phoneNumber,
      profilePhoto: profilePhoto,
    );
    updateProfile(updated);
  }

  void signOut() {
    _state = SessionState.guest(UserRole.user);
    notifyListeners();
  }
}