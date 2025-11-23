import 'user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.bio,
    this.phoneNumber,
    this.profilePhoto,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? bio;
  final String? phoneNumber;
  final String? profilePhoto;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      role: (json['role'] as String?) == 'owner' ? UserRole.owner : UserRole.user,
      bio: json['bio'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'profilePhoto': profilePhoto,
    };
  }

  Profile copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? bio,
    String? phoneNumber,
    String? profilePhoto,
  }) {
    return Profile(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
    );
  }
}