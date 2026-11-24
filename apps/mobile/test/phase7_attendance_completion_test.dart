import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lagan_staff/features/attendance/models/booking_model.dart';

void main() {
  group('Phase 7 - Attendance & Booking Models Unit Tests', () {
    test('BookingStatus parses all enum values correctly from string', () {
      expect(BookingStatus.fromString('confirmed'), equals(BookingStatus.confirmed));
      expect(BookingStatus.fromString('checked_in'), equals(BookingStatus.checkedIn));
      expect(BookingStatus.fromString('completed'), equals(BookingStatus.completed));
      expect(BookingStatus.fromString('cancelled_by_worker'), equals(BookingStatus.cancelledByWorker));
      expect(BookingStatus.fromString('cancelled_by_owner'), equals(BookingStatus.cancelledByOwner));
      expect(BookingStatus.fromString('no_show'), equals(BookingStatus.noShow));
      expect(BookingStatus.fromString(null), equals(BookingStatus.confirmed));
    });

    test('AttendanceStatus parses all values and has distinct display names & colors', () {
      expect(AttendanceStatus.fromString('pending'), equals(AttendanceStatus.pending));
      expect(AttendanceStatus.fromString('checked_in'), equals(AttendanceStatus.checkedIn));
      expect(AttendanceStatus.fromString('present'), equals(AttendanceStatus.present));
      expect(AttendanceStatus.fromString('absent'), equals(AttendanceStatus.absent));
      expect(AttendanceStatus.fromString('no_show'), equals(AttendanceStatus.noShow));

      expect(AttendanceStatus.present.color, equals(Colors.green));
      expect(AttendanceStatus.absent.color, equals(Colors.red));
      expect(AttendanceStatus.checkedIn.color, equals(Colors.blue));
    });

    test('BookingModel parses accurately from backend RPC JSON', () {
      final json = {
        'booking_id': 'bk-001',
        'job_id': 'job-101',
        'business_name': 'Royal Lawn & Banquet',
        'category_name': 'वेटर',
        'job_title': 'शादी में वेटर आवश्यक',
        'venue_name': 'रॉयल लान',
        'reporting_address': 'स्टेशन रोड',
        'locality': 'गाजीपुर',
        'city': 'Ghazipur',
        'shift_date': '2026-11-20',
        'start_time': '16:00:00',
        'end_time': '23:00:00',
        'is_overnight': false,
        'agreed_wage': 700,
        'booking_status': 'confirmed',
        'checkin_code': '4821',
        'attendance_status': 'pending',
        'completion_status': 'pending',
      };

      final model = BookingModel.fromJson(json);

      expect(model.bookingId, equals('bk-001'));
      expect(model.jobId, equals('job-101'));
      expect(model.businessName, equals('Royal Lawn & Banquet'));
      expect(model.agreedWage, equals(700.0));
      expect(model.bookingStatus, equals(BookingStatus.confirmed));
      expect(model.checkinCode, equals('4821'));
      expect(model.attendanceStatus, equals(AttendanceStatus.pending));
      expect(model.completionStatus, equals(WorkCompletionStatus.pending));
      expect(model.isCompleted, isFalse);
      expect(model.isPresent, isFalse);
      expect(model.isCheckedIn, isFalse);
      expect(model.isCancelled, isFalse);
    });

    test('BookingModel Check-in window validation (Asia/Kolkata)', () {
      const shiftDateStr = '2026-11-20';
      const startTimeStr = '16:00:00'; // 4:00 PM shift

      const booking = BookingModel(
        bookingId: 'bk-win-1',
        jobId: 'job-win-1',
        businessName: 'Lawn',
        categoryName: 'वेटर',
        jobTitle: 'वेटर शिफ्ट',
        reportingAddress: 'लंका',
        locality: 'गाजीपुर',
        shiftDate: shiftDateStr,
        startTime: startTimeStr,
        endTime: '22:00:00',
        agreedWage: 600,
        bookingStatus: BookingStatus.confirmed,
      );

      // 1. Too early: 1:00 PM (3 hours before shift start) -> Window opens at 2:00 PM
      final tooEarly = DateTime(2026, 11, 20, 13, 0);
      expect(booking.isCheckInEligible(tooEarly), isFalse);

      // 2. Exactly within window: 2:30 PM (1.5 hours before start) -> Eligible!
      final inWindowEarly = DateTime(2026, 11, 20, 14, 30);
      expect(booking.isCheckInEligible(inWindowEarly), isTrue);

      // 3. Exactly at shift start: 4:00 PM -> Eligible!
      final atStart = DateTime(2026, 11, 20, 16, 0);
      expect(booking.isCheckInEligible(atStart), isTrue);

      // 4. Within late window: 6:00 PM (2 hours after start) -> Eligible!
      final inWindowLate = DateTime(2026, 11, 20, 18, 0);
      expect(booking.isCheckInEligible(inWindowLate), isTrue);

      // 5. Too late: 9:00 PM (5 hours after start) -> Window closed!
      final tooLate = DateTime(2026, 11, 20, 21, 0);
      expect(booking.isCheckInEligible(tooLate), isFalse);
    });

    test('BookingModel Check-in is blocked if already checked in or cancelled', () {
      final now = DateTime(2026, 11, 20, 15, 0);

      const checkedInBooking = BookingModel(
        bookingId: 'bk-chk-1',
        jobId: 'job-1',
        businessName: 'Lawn',
        categoryName: 'वेटर',
        jobTitle: 'वेटर',
        reportingAddress: 'लंका',
        locality: 'गाजीपुर',
        shiftDate: '2026-11-20',
        startTime: '16:00:00',
        endTime: '22:00:00',
        agreedWage: 600,
        bookingStatus: BookingStatus.checkedIn,
        attendanceStatus: AttendanceStatus.checkedIn,
      );
      expect(checkedInBooking.isCheckInEligible(now), isFalse);

      const cancelledBooking = BookingModel(
        bookingId: 'bk-cnl-1',
        jobId: 'job-1',
        businessName: 'Lawn',
        categoryName: 'वेटर',
        jobTitle: 'वेटर',
        reportingAddress: 'लंका',
        locality: 'गाजीपुर',
        shiftDate: '2026-11-20',
        startTime: '16:00:00',
        endTime: '22:00:00',
        agreedWage: 600,
        bookingStatus: BookingStatus.cancelledByWorker,
      );
      expect(cancelledBooking.isCheckInEligible(now), isFalse);
    });
  });

  group('Phase 7 - Owner Attendance Roster & Metrics Unit Tests', () {
    test('RosterMetricsModel correctly parses summary counts', () {
      final json = {
        'total_confirmed': 10,
        'checked_in': 8,
        'present': 7,
        'absent': 1,
        'no_show': 1,
        'completed': 5,
      };

      final metrics = RosterMetricsModel.fromJson(json);
      expect(metrics.totalConfirmed, equals(10));
      expect(metrics.checkedIn, equals(8));
      expect(metrics.present, equals(7));
      expect(metrics.absent, equals(1));
      expect(metrics.noShow, equals(1));
      expect(metrics.completed, equals(5));
    });

    test('JobAttendanceRosterModel parses full roster with worker skills and states', () {
      final json = {
        'job_id': 'job-roster-101',
        'job_title': '10 Waiters for Evening Banquet',
        'shift_date': '2026-11-22',
        'start_time': '17:00:00',
        'end_time': '23:30:00',
        'workers_needed': 10,
        'metrics': {
          'total_confirmed': 2,
          'checked_in': 1,
          'present': 1,
          'absent': 0,
          'no_show': 0,
          'completed': 0,
        },
        'roster': [
          {
            'booking_id': 'bk-w1',
            'worker_profile_id': 'wp-1',
            'full_name': 'अमित कुमार',
            'mobile_number': '+919876543210',
            'agreed_wage': 750,
            'booking_status': 'checked_in',
            'checkin_code': '5621',
            'attendance_status': 'checked_in',
            'skills': ['टेबल सर्विस', 'प्लेट हैंडलिंग'],
          },
          {
            'booking_id': 'bk-w2',
            'worker_profile_id': 'wp-2',
            'full_name': 'सुरेश यादव',
            'mobile_number': '+919876543211',
            'agreed_wage': 750,
            'booking_status': 'confirmed',
            'checkin_code': '9012',
            'attendance_status': 'present',
            'skills': ['भोजन परोसना'],
          }
        ],
      };

      final roster = JobAttendanceRosterModel.fromJson(json);

      expect(roster.jobId, equals('job-roster-101'));
      expect(roster.workersNeeded, equals(10));
      expect(roster.metrics.totalConfirmed, equals(2));
      expect(roster.roster.length, equals(2));

      final w1 = roster.roster[0];
      expect(w1.fullName, equals('अमित कुमार'));
      expect(w1.isCheckedIn, isTrue);
      expect(w1.isPresent, isFalse);
      expect(w1.skills, contains('टेबल सर्विस'));

      final w2 = roster.roster[1];
      expect(w2.fullName, equals('सुरेश यादव'));
      expect(w2.isPresent, isTrue);
      expect(w2.skills, contains('भोजन परोसना'));
    });
  });
}
