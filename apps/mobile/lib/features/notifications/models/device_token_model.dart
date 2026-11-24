class DeviceTokenModel {
  final String id;
  final String userId;
  final String installationId;
  final String fcmToken;
  final String platform;
  final String? appVersion;
  final bool isActive;
  final DateTime lastSeenAt;

  const DeviceTokenModel({
    required this.id,
    required this.userId,
    required this.installationId,
    required this.fcmToken,
    required this.platform,
    this.appVersion,
    required this.isActive,
    required this.lastSeenAt,
  });

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      installationId: json['installation_id']?.toString() ?? '',
      fcmToken: json['fcm_token']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'android',
      appVersion: json['app_version']?.toString(),
      isActive: json['is_active'] == true,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
