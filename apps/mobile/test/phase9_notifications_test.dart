import 'package:lagan_staff/features/auth/models/user_profile.dart';
import 'package:lagan_staff/features/notifications/notification_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lagan_staff/features/notifications/models/notification_item_model.dart';
import 'package:lagan_staff/features/notifications/models/notification_preferences_model.dart';
import 'package:lagan_staff/features/notifications/models/device_token_model.dart';

void main() {
  group('Phase 9 - Notification Models Unit Tests', () {
    test('NotificationEventType handles all event types correctly', () {
      expect(
          NotificationEventType.fromString('new_job'), NotificationEventType.newJob);
      expect(NotificationEventType.fromString('booking_confirmed'),
          NotificationEventType.bookingConfirmed);
      expect(NotificationEventType.fromString('job_cancelled'),
          NotificationEventType.jobCancelled);
      expect(NotificationEventType.fromString('shift_reminder'),
          NotificationEventType.shiftReminder);
      expect(NotificationEventType.fromString('application_received'),
          NotificationEventType.applicationReceived);
      expect(NotificationEventType.fromString('application_approved'),
          NotificationEventType.applicationApproved);
      expect(NotificationEventType.fromString('application_rejected'),
          NotificationEventType.applicationRejected);
      expect(
          NotificationEventType.fromString('unknown_event'), NotificationEventType.other);

      expect(NotificationEventType.newJob.toDbString(), 'new_job');
      expect(NotificationEventType.bookingConfirmed.toDbString(),
          'booking_confirmed');
      expect(NotificationEventType.jobCancelled.toDbString(), 'job_cancelled');
      expect(NotificationEventType.shiftReminder.toDbString(), 'shift_reminder');
    });

    test('NotificationItemModel parses accurately from backend RPC JSON', () {
      final json = {
        'id': 'notif-12345',
        'event_type': 'shift_reminder',
        'title': 'शिफ्ट 2 घंटे में शुरू होगी!',
        'body': 'शाही दरबार पैलेस में आपकी ड्यूटी 2 घंटे में शुरू होगी। गेट पास पिन तैयार रखें।',
        'data': {
          'booking_id': 'bk-ghz-503',
          'job_id': 'job-ghz-101',
          'channel_id': 'shift_reminders',
          'entity_type': 'booking',
          'entity_id': 'bk-ghz-503',
        },
        'entity_type': 'booking',
        'entity_id': 'bk-ghz-503',
        'is_read': false,
        'read_at': null,
        'created_at': '2026-11-18T18:00:00Z',
      };

      final item = NotificationItemModel.fromJson(json);

      expect(item.id, 'notif-12345');
      expect(item.eventType, NotificationEventType.shiftReminder);
      expect(item.title, 'शिफ्ट 2 घंटे में शुरू होगी!');
      expect(item.body, contains('शाही दरबार पैलेस'));
      expect(item.entityType, 'booking');
      expect(item.entityId, 'bk-ghz-503');
      expect(item.isRead, isFalse);
      expect(item.readAt, isNull);
      expect(item.data['channel_id'], 'shift_reminders');

      // Test copyWith
      final readItem = item.copyWith(isRead: true, readAt: DateTime(2026, 11, 18, 18, 30));
      expect(readItem.isRead, isTrue);
      expect(readItem.readAt, isNotNull);
      expect(readItem.id, item.id);
    });

    test('NotificationPreferencesModel handles defaults, JSON conversion, and toggles', () {
      final defaults = NotificationPreferencesModel.defaults();
      expect(defaults.newJobAlerts, isTrue);
      expect(defaults.applicationUpdates, isTrue);
      expect(defaults.bookingUpdates, isTrue);
      expect(defaults.shiftReminders, isTrue);

      final customJson = {
        'new_job_alerts': false,
        'application_updates': true,
        'booking_updates': true,
        'shift_reminders': false,
        'updated_at': '2026-11-18T10:00:00Z',
      };

      final prefs = NotificationPreferencesModel.fromJson(customJson);
      expect(prefs.newJobAlerts, isFalse);
      expect(prefs.applicationUpdates, isTrue);
      expect(prefs.bookingUpdates, isTrue);
      expect(prefs.shiftReminders, isFalse);

      final serialized = prefs.toJson();
      expect(serialized['new_job_alerts'], isFalse);
      expect(serialized['shift_reminders'], isFalse);
      expect(serialized['booking_updates'], isTrue);

      final updated = prefs.copyWith(newJobAlerts: true);
      expect(updated.newJobAlerts, isTrue);
      expect(updated.shiftReminders, isFalse);
    });

    test('DeviceTokenModel parses device registration data properly', () {
      final json = {
        'id': 'dt-001',
        'user_id': 'user-123',
        'installation_id': 'inst-abc',
        'fcm_token': 'fcm-sample-token-12345',
        'platform': 'android',
        'app_version': '1.0.0',
        'is_active': true,
        'created_at': '2026-11-18T00:00:00Z',
        'last_seen_at': '2026-11-18T12:00:00Z',
      };

      final device = DeviceTokenModel.fromJson(json);
      expect(device.id, 'dt-001');
      expect(device.userId, 'user-123');
      expect(device.fcmToken, 'fcm-sample-token-12345');
      expect(device.platform, 'android');
      expect(device.isActive, isTrue);
    });
  });

  group('Phase 9 - Deep Link Resolution Logic Unit Tests', () {
    test('Resolves job alerts to Worker Job Details screen', () {
      expect(notificationRoute('job', 'job-ghz-001', AppUserRole.worker), '/worker/jobs/job-ghz-001');
    });

    test('Resolves booking alerts to Worker Bookings screen', () {
      expect(notificationRoute('booking', 'bk-ghz-503', AppUserRole.worker), '/worker/bookings');
      expect(notificationRoute('booking', null, AppUserRole.worker), '/worker/bookings');
    });

    test('Resolves roster / application alerts to Owner Attendance Roster screen', () {
      expect(notificationRoute('roster', 'job-ghz-001', AppUserRole.owner), '/owner/attendance/job-ghz-001');
      expect(notificationRoute('application', 'job-ghz-001', AppUserRole.owner), '/owner/attendance/job-ghz-001');
    });

    test('Uses the job ID for owner booking and cancellation notifications', () {
      expect(notificationRoute('booking', 'booking-1', AppUserRole.owner, jobId: 'job-1'), '/owner/attendance/job-1');
      expect(notificationRoute('booking', 'booking-1', AppUserRole.owner), '/notifications');
      expect(notificationRoute('job', 'job-1', AppUserRole.owner, event: 'job_cancelled'), '/jobs/detail/job-1');
      expect(notificationRoute('job', 'job-1', AppUserRole.worker, event: 'job_cancelled'), '/worker/bookings');
    });

    test('Falls back to Notification Center when entity is empty or unknown', () {
      expect(notificationRoute('unknown', null, AppUserRole.worker), '/notifications');
      expect(notificationRoute('job', '', AppUserRole.worker), '/notifications');
    });
  });

  group('Phase 9 - Shift Reminders Window Unit Tests', () {
    bool isWithin24HourWindow(DateTime shiftStart, DateTime evaluationTime) {
      final diff = shiftStart.difference(evaluationTime);
      return diff.inMinutes >= (24 * 60 - 30) && diff.inMinutes <= (24 * 60 + 30);
    }

    bool isWithin2HourWindow(DateTime shiftStart, DateTime evaluationTime) {
      final diff = shiftStart.difference(evaluationTime);
      return diff.inMinutes >= (2 * 60 - 15) && diff.inMinutes <= (2 * 60 + 15);
    }

    test('Evaluates 24-hour reminder window correctly (23.5h - 24.5h range)', () {
      final shift = DateTime(2026, 11, 20, 18, 0); // Nov 20 6:00 PM

      // Exactly 24h before
      expect(isWithin24HourWindow(shift, DateTime(2026, 11, 19, 18, 0)), isTrue);
      // 23h 45m before (in window)
      expect(isWithin24HourWindow(shift, DateTime(2026, 11, 19, 18, 15)), isTrue);
      // 25h before (outside window)
      expect(isWithin24HourWindow(shift, DateTime(2026, 11, 19, 17, 0)), isFalse);
    });

    test('Evaluates 2-hour reminder window correctly (1h45m - 2h15m range)', () {
      final shift = DateTime(2026, 11, 20, 18, 0); // Nov 20 6:00 PM

      // Exactly 2h before
      expect(isWithin2HourWindow(shift, DateTime(2026, 11, 20, 16, 0)), isTrue);
      // 1h 50m before (in window)
      expect(isWithin2HourWindow(shift, DateTime(2026, 11, 20, 16, 10)), isTrue);
      // 3h before (outside window)
      expect(isWithin2HourWindow(shift, DateTime(2026, 11, 20, 15, 0)), isFalse);
    });
  });
}
