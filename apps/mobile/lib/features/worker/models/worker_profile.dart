import '../../../core/localization/app_language.dart';
import 'worker_skill.dart';

enum WorkerAccountStatus {
  pendingProfile,
  active,
  suspended;

  static WorkerAccountStatus fromString(String? value) {
    if (value == null) return WorkerAccountStatus.pendingProfile;
    switch (value.toLowerCase()) {
      case 'active':
        return WorkerAccountStatus.active;
      case 'suspended':
        return WorkerAccountStatus.suspended;
      case 'pending_profile':
      default:
        return WorkerAccountStatus.pendingProfile;
    }
  }

  String get displayName => displayNameFor(AppLanguage.english);

  String displayNameFor(AppLanguage language) {
    switch (this) {
      case WorkerAccountStatus.active:
        return switch (language) {
          AppLanguage.hindi => 'खाता सक्रिय',
          AppLanguage.hinglish => 'Active',
          AppLanguage.english => 'Active',
        };
      case WorkerAccountStatus.suspended:
        return switch (language) {
          AppLanguage.hindi => 'खाता निलंबित',
          AppLanguage.hinglish => 'Suspended',
          AppLanguage.english => 'Suspended',
        };
      case WorkerAccountStatus.pendingProfile:
        return switch (language) {
          AppLanguage.hindi => 'प्रोफाइल अधूरी',
          AppLanguage.hinglish => 'Profile Incomplete',
          AppLanguage.english => 'Profile Incomplete',
        };
    }
  }

  bool get isActive => this == WorkerAccountStatus.active;
  bool get isSuspended => this == WorkerAccountStatus.suspended;
  bool get isPending => this == WorkerAccountStatus.pendingProfile;
}

class WorkerProfileModel {
  final String? id;
  final String userId;
  final String fullName;
  final String phone;
  final String locality;
  final String city;
  final String district;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? selfieStoragePath;
  final WorkerAccountStatus status;
  final bool isSelfieVerified;
  final List<WorkerSkillItem> skills;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkerProfileModel({
    this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.locality,
    this.city = 'Ghazipur',
    this.district = 'Ghazipur',
    required this.pincode,
    this.latitude,
    this.longitude,
    this.selfieStoragePath,
    this.status = WorkerAccountStatus.pendingProfile,
    this.isSelfieVerified = false,
    this.skills = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isComplete => status == WorkerAccountStatus.active;

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    List<WorkerSkillItem> parsedSkills = [];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List)
          .map((item) => WorkerSkillItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return WorkerProfileModel(
      id: json['worker_profile_id'] as String? ?? json['id'] as String?,
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      locality: json['locality'] as String? ?? '',
      city: json['city'] as String? ?? 'Ghazipur',
      district: json['district'] as String? ?? 'Ghazipur',
      pincode: json['pincode'] as String? ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      selfieStoragePath: json['selfie_storage_path'] as String?,
      status: WorkerAccountStatus.fromString(json['status'] as String?),
      isSelfieVerified: json['is_selfie_verified'] as bool? ?? false,
      skills: parsedSkills,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  WorkerProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? locality,
    String? city,
    String? district,
    String? pincode,
    double? latitude,
    double? longitude,
    String? selfieStoragePath,
    WorkerAccountStatus? status,
    bool? isSelfieVerified,
    List<WorkerSkillItem>? skills,
  }) {
    return WorkerProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      district: district ?? this.district,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      selfieStoragePath: selfieStoragePath ?? this.selfieStoragePath,
      status: status ?? this.status,
      isSelfieVerified: isSelfieVerified ?? this.isSelfieVerified,
      skills: skills ?? this.skills,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
