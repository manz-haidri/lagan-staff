import '../auth/models/user_profile.dart';

String notificationRoute(String? type, String? id, AppUserRole? role,
    {String? jobId, String? event}) {
  final job = jobId?.isNotEmpty == true ? jobId : null;
  final entity = id?.isNotEmpty == true ? id : null;
  if (role == AppUserRole.worker) {
    if (type == 'booking' || (type == 'job' && event == 'job_cancelled')) {
      return '/worker/bookings';
    }
    if (type == 'job' && (entity ?? job) != null) return '/worker/jobs/${entity ?? job}';
  }
  if (role == AppUserRole.owner) {
    if (type == 'job' && (entity ?? job) != null) return '/jobs/detail/${entity ?? job}';
    final rosterJob = type == 'booking' ? job : job ?? entity;
    if (rosterJob != null && {'booking', 'application', 'roster'}.contains(type)) {
      return '/owner/attendance/$rosterJob';
    }
  }
  return '/notifications';
}
