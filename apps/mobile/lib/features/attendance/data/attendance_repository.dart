import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(Supabase.instance.client);
});

class AttendanceRepository {
  final SupabaseClient _supabase;

  AttendanceRepository(this._supabase);

  /// Fetch full attendance roster and summary counts for an owner's job
  Future<JobAttendanceRosterModel> fetchOwnerJobRoster(String jobId) async {
    try {
      final res = await _supabase.rpc('get_owner_job_attendance_roster', params: {
        'p_job_id': jobId,
      });

      return JobAttendanceRosterModel.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      // Fallback empty roster structure if no records or during setup
      return JobAttendanceRosterModel(
        jobId: jobId,
        jobTitle: 'कार्य रोस्टर',
        shiftDate: '',
        startTime: '',
        endTime: '',
        workersNeeded: 0,
        metrics: const RosterMetricsModel(),
        roster: const [],
      );
    }
  }

  /// Worker self-check in with server timestamp and shift window validation
  Future<Map<String, dynamic>> workerCheckIn(
    String bookingId, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await _supabase.rpc('worker_check_in', params: {
        'p_booking_id': bookingId,
        'p_latitude': latitude,
        'p_longitude': longitude,
      });

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      throw Exception('चेक-इन विफल: $e');
    }
  }

  /// Owner marks worker attendance (present, absent, no_show)
  Future<Map<String, dynamic>> markAttendance({
    required String bookingId,
    required String status,
    String? notes,
  }) async {
    try {
      final res = await _supabase.rpc('mark_worker_attendance', params: {
        'p_booking_id': bookingId,
        'p_status': status,
        'p_notes': notes,
      });

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      throw Exception('उपस्थिति दर्ज करने में विफल: $e');
    }
  }

  /// Owner marks work completed for present workers
  Future<Map<String, dynamic>> completeWork({
    required String bookingId,
    String? notes,
  }) async {
    try {
      final res = await _supabase.rpc('complete_worker_work', params: {
        'p_booking_id': bookingId,
        'p_notes': notes,
      });

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      throw Exception('कार्य संपन्न चिह्नित करने में विफल: $e');
    }
  }

  /// Worker or Owner cancels a booking with reason capture
  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      final res = await _supabase.rpc('cancel_worker_booking', params: {
        'p_booking_id': bookingId,
        'p_reason': reason,
      });

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      throw Exception('बुकिंग रद्द करने में विफल: $e');
    }
  }

  /// Fetch worker bookings (upcoming, history, or all)
  Future<List<BookingModel>> fetchWorkerBookings({
    String filter = 'upcoming',
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await _supabase.rpc('get_worker_bookings', params: {
        'p_filter': filter,
        'p_limit': limit,
        'p_offset': offset,
      });

      return (res as List)
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
