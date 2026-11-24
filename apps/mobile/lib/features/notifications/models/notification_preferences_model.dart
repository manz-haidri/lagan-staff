class NotificationPreferencesModel {
  final bool newJobAlerts;
  final bool applicationUpdates;
  final bool bookingUpdates;
  final bool shiftReminders;
  final DateTime? updatedAt;

  const NotificationPreferencesModel({
    this.newJobAlerts = true,
    this.applicationUpdates = true,
    this.bookingUpdates = true,
    this.shiftReminders = true,
    this.updatedAt,
  });

  factory NotificationPreferencesModel.defaults() {
    return const NotificationPreferencesModel(
      newJobAlerts: true,
      applicationUpdates: true,
      bookingUpdates: true,
      shiftReminders: true,
    );
  }

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      newJobAlerts: json['new_job_alerts'] ?? true,
      applicationUpdates: json['application_updates'] ?? true,
      bookingUpdates: json['booking_updates'] ?? true,
      shiftReminders: json['shift_reminders'] ?? true,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_job_alerts': newJobAlerts,
      'application_updates': applicationUpdates,
      'booking_updates': bookingUpdates,
      'shift_reminders': shiftReminders,
    };
  }

  NotificationPreferencesModel copyWith({
    bool? newJobAlerts,
    bool? applicationUpdates,
    bool? bookingUpdates,
    bool? shiftReminders,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesModel(
      newJobAlerts: newJobAlerts ?? this.newJobAlerts,
      applicationUpdates: applicationUpdates ?? this.applicationUpdates,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      shiftReminders: shiftReminders ?? this.shiftReminders,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
