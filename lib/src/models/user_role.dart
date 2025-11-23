enum UserRole { user, owner }

extension UserRoleLabel on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Diner';
      case UserRole.owner:
        return 'Owner';
    }
  }
}