enum NotificationEventType {
  newJob,
  applicationReceived,
  applicationApproved,
  applicationRejected,
  bookingConfirmed,
  jobCancelled,
  shiftReminder,
  other;

  static NotificationEventType fromString(String? val) {
    switch (val) {
      case 'new_job':
        return NotificationEventType.newJob;
      case 'application_received':
        return NotificationEventType.applicationReceived;
      case 'application_approved':
        return NotificationEventType.applicationApproved;
      case 'application_rejected':
        return NotificationEventType.applicationRejected;
      case 'booking_confirmed':
        return NotificationEventType.bookingConfirmed;
      case 'job_cancelled':
        return NotificationEventType.jobCancelled;
      case 'shift_reminder':
        return NotificationEventType.shiftReminder;
      default:
        return NotificationEventType.other;
    }
  }

  String toDbString() {
    switch (this) {
      case NotificationEventType.newJob:
        return 'new_job';
      case NotificationEventType.applicationReceived:
        return 'application_received';
      case NotificationEventType.applicationApproved:
        return 'application_approved';
      case NotificationEventType.applicationRejected:
        return 'application_rejected';
      case NotificationEventType.bookingConfirmed:
        return 'booking_confirmed';
      case NotificationEventType.jobCancelled:
        return 'job_cancelled';
      case NotificationEventType.shiftReminder:
        return 'shift_reminder';
      case NotificationEventType.other:
        return 'other';
    }
  }
}

class NotificationItemModel {
  final String id;
  final NotificationEventType eventType;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String entityType;
  final String? entityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItemModel({
    required this.id,
    required this.eventType,
    required this.title,
    required this.body,
    required this.data,
    required this.entityType,
    this.entityId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id']?.toString() ?? '',
      eventType: NotificationEventType.fromString(json['event_type']?.toString()),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      entityType: json['entity_type']?.toString() ?? 'system',
      entityId: json['entity_id']?.toString(),
      isRead: json['is_read'] == true,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationItemModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationItemModel(
      id: id,
      eventType: eventType,
      title: title,
      body: body,
      data: data,
      entityType: entityType,
      entityId: entityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
