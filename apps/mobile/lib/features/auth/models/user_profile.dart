enum AppUserRole {
  worker,
  owner,
  admin;

  static AppUserRole? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'worker':
        return AppUserRole.worker;
      case 'owner':
        return AppUserRole.owner;
      case 'admin':
        return AppUserRole.admin;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case AppUserRole.worker:
        return 'कार्यकर्ता (Worker)';
      case AppUserRole.owner:
        return 'व्यापारी / मालिक (Business Owner)';
      case AppUserRole.admin:
        return 'प्रशासक (Administrator)';
    }
  }
}

class UserProfile {
  final String id;
  final String phone;
  final String? fullName;
  final String? avatarUrl;
  final AppUserRole? primaryRole;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.phone,
    this.fullName,
    this.avatarUrl,
    this.primaryRole,
    this.createdAt,
  });

  bool get hasRole => primaryRole != null;

  factory UserProfile.fromJson(Map<String, dynamic> json, {AppUserRole? role}) {
    return UserProfile(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      primaryRole: role ?? AppUserRole.fromString(json['role'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
