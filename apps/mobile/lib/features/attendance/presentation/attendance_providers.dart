import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/attendance_repository.dart';
import '../models/booking_model.dart';

final ownerJobRosterProvider = FutureProvider.family<JobAttendanceRosterModel, String>(
  (ref, jobId) async {
    final repo = ref.watch(attendanceRepositoryProvider);
    return repo.fetchOwnerJobRoster(jobId);
  },
);

final workerBookingsProvider = FutureProvider.family<List<BookingModel>, String>(
  (ref, filter) async {
    final repo = ref.watch(attendanceRepositoryProvider);
    return repo.fetchWorkerBookings(filter: filter);
  },
);
