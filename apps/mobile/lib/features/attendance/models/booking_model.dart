import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';

enum BookingStatus {
  confirmed,
  checkedIn,
  completed,
  cancelledByWorker,
  cancelledByOwner,
  noShow;

  static BookingStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'checked_in':
        return BookingStatus.checkedIn;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled_by_worker':
        return BookingStatus.cancelledByWorker;
      case 'cancelled_by_owner':
        return BookingStatus.cancelledByOwner;
      case 'no_show':
        return BookingStatus.noShow;
      default:
        return BookingStatus.confirmed;
    }
  }

  String get displayName => displayNameFor(AppLanguage.english);

  String displayNameFor(AppLanguage language) {
    switch (this) {
      case BookingStatus.confirmed:
        return switch (language) {
          AppLanguage.hindi => 'पुष्ट बुकिंग',
          AppLanguage.hinglish => 'Confirmed Booking',
          AppLanguage.english => 'Confirmed Booking',
        };
      case BookingStatus.checkedIn:
        return switch (language) {
          AppLanguage.hindi => 'चेक-इन पूर्ण',
          AppLanguage.hinglish => 'Checked-in',
          AppLanguage.english => 'Checked-in',
        };
      case BookingStatus.completed:
        return switch (language) {
          AppLanguage.hindi => 'कार्य संपन्न',
          AppLanguage.hinglish => 'Completed',
          AppLanguage.english => 'Completed',
        };
      case BookingStatus.cancelledByWorker:
        return switch (language) {
          AppLanguage.hindi => 'कार्यकर्ता द्वारा रद्द',
          AppLanguage.hinglish => 'Cancelled by Worker',
          AppLanguage.english => 'Cancelled by Worker',
        };
      case BookingStatus.cancelledByOwner:
        return switch (language) {
          AppLanguage.hindi => 'आयोजक द्वारा रद्द',
          AppLanguage.hinglish => 'Cancelled by Host',
          AppLanguage.english => 'Cancelled by Host',
        };
      case BookingStatus.noShow:
        return switch (language) {
          AppLanguage.hindi => 'नो-शो / अनुपस्थित',
          AppLanguage.hinglish => 'No Show / Absent',
          AppLanguage.english => 'No Show / Absent',
        };
    }
  }
}

enum AttendanceStatus {
  pending,
  checkedIn,
  present,
  absent,
  noShow;

  static AttendanceStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'checked_in':
        return AttendanceStatus.checkedIn;
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'no_show':
        return AttendanceStatus.noShow;
      case 'pending':
      default:
        return AttendanceStatus.pending;
    }
  }

  String get displayName => displayNameFor(AppLanguage.english);

  String displayNameFor(AppLanguage language) {
    switch (this) {
      case AttendanceStatus.pending:
        return switch (language) {
          AppLanguage.hindi => 'प्रतीक्षारत',
          AppLanguage.hinglish => 'Pending',
          AppLanguage.english => 'Pending',
        };
      case AttendanceStatus.checkedIn:
        return switch (language) {
          AppLanguage.hindi => 'स्थल पर चेक-इन',
          AppLanguage.hinglish => 'Checked In',
          AppLanguage.english => 'Checked In',
        };
      case AttendanceStatus.present:
        return switch (language) {
          AppLanguage.hindi => 'उपस्थित',
          AppLanguage.hinglish => 'Present',
          AppLanguage.english => 'Present',
        };
      case AttendanceStatus.absent:
        return switch (language) {
          AppLanguage.hindi => 'अनुपस्थित',
          AppLanguage.hinglish => 'Absent',
          AppLanguage.english => 'Absent',
        };
      case AttendanceStatus.noShow:
        return switch (language) {
          AppLanguage.hindi => 'नो-शो',
          AppLanguage.hinglish => 'No Show',
          AppLanguage.english => 'No Show',
        };
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.pending:
        return Colors.orange;
      case AttendanceStatus.checkedIn:
        return Colors.blue;
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.noShow:
        return Colors.deepPurple;
    }
  }
}

enum WorkCompletionStatus {
  pending,
  completed;

  static WorkCompletionStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'completed':
        return WorkCompletionStatus.completed;
      case 'pending':
      default:
        return WorkCompletionStatus.pending;
    }
  }
}

class BookingModel {
  final String bookingId;
  final String jobId;
  final String businessName;
  final String categoryName;
  final String jobTitle;
  final String? venueName;
  final String reportingAddress;
  final String locality;
  final String city;
  final String shiftDate;
  final String startTime;
  final String endTime;
  final bool isOvernight;
  final double agreedWage;
  final BookingStatus bookingStatus;
  final String? checkinCode;
  final AttendanceStatus attendanceStatus;
  final DateTime? checkInAt;
  final WorkCompletionStatus completionStatus;
  final DateTime? completedAt;
  final String? specialInstructions;

  const BookingModel({
    required this.bookingId,
    required this.jobId,
    required this.businessName,
    required this.categoryName,
    required this.jobTitle,
    this.venueName,
    required this.reportingAddress,
    required this.locality,
    this.city = 'Ghazipur',
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.isOvernight = false,
    required this.agreedWage,
    required this.bookingStatus,
    this.checkinCode,
    this.attendanceStatus = AttendanceStatus.pending,
    this.checkInAt,
    this.completionStatus = WorkCompletionStatus.pending,
    this.completedAt,
    this.specialInstructions,
  });

  bool get isCompleted => completionStatus == WorkCompletionStatus.completed;
  bool get isPresent => attendanceStatus == AttendanceStatus.present;
  bool get isCheckedIn => attendanceStatus == AttendanceStatus.checkedIn || bookingStatus == BookingStatus.checkedIn;
  bool get isCancelled =>
      bookingStatus == BookingStatus.cancelledByWorker ||
      bookingStatus == BookingStatus.cancelledByOwner;

  /// Check whether shift is eligible for check-in based on shift_date and start_time (Asia/Kolkata)
  bool isCheckInEligible(DateTime now) {
    if (isCancelled || isCompleted || isCheckedIn || isPresent) return false;
    final parsedDate = DateTime.tryParse(shiftDate);
    if (parsedDate == null) return false;

    // Parse start_time (e.g. "16:00:00" or "09:30")
    final timeParts = startTime.split(':');
    final startHour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final startMinute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    final shiftStart = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, startHour, startMinute);
    final earliestCheckIn = shiftStart.subtract(const Duration(hours: 2));
    final latestCheckIn = shiftStart.add(const Duration(hours: 4));

    return now.isAfter(earliestCheckIn) && now.isBefore(latestCheckIn);
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['booking_id']?.toString() ?? json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? 'सत्यापित आयोजक',
      categoryName: json['category_name']?.toString() ?? 'इवेंट',
      jobTitle: json['job_title']?.toString() ?? json['title']?.toString() ?? '',
      venueName: json['venue_name']?.toString(),
      reportingAddress: json['reporting_address']?.toString() ?? '',
      locality: json['locality']?.toString() ?? 'गाजीपुर',
      city: json['city']?.toString() ?? 'Ghazipur',
      shiftDate: json['shift_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isOvernight: json['is_overnight'] as bool? ?? false,
      agreedWage: double.tryParse(json['agreed_wage']?.toString() ?? '500') ?? 500.0,
      bookingStatus: BookingStatus.fromString(json['booking_status']?.toString() ?? json['status']?.toString()),
      checkinCode: json['checkin_code']?.toString(),
      attendanceStatus: AttendanceStatus.fromString(json['attendance_status']?.toString()),
      checkInAt: json['check_in_at'] != null ? DateTime.tryParse(json['check_in_at'].toString()) : null,
      completionStatus: WorkCompletionStatus.fromString(json['completion_status']?.toString()),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      specialInstructions: json['special_instructions']?.toString(),
    );
  }
}

class RosterWorkerModel {
  final String bookingId;
  final String workerProfileId;
  final String fullName;
  final String? mobileNumber;
  final String? selfieUrl;
  final double agreedWage;
  final BookingStatus bookingStatus;
  final String? checkinCode;
  final AttendanceStatus attendanceStatus;
  final DateTime? checkInAt;
  final DateTime? markedAt;
  final WorkCompletionStatus completionStatus;
  final DateTime? completedAt;
  final String? notes;
  final List<String> skills;

  const RosterWorkerModel({
    required this.bookingId,
    required this.workerProfileId,
    required this.fullName,
    this.mobileNumber,
    this.selfieUrl,
    required this.agreedWage,
    required this.bookingStatus,
    this.checkinCode,
    this.attendanceStatus = AttendanceStatus.pending,
    this.checkInAt,
    this.markedAt,
    this.completionStatus = WorkCompletionStatus.pending,
    this.completedAt,
    this.notes,
    this.skills = const [],
  });

  bool get isPresent => attendanceStatus == AttendanceStatus.present;
  bool get isCheckedIn => attendanceStatus == AttendanceStatus.checkedIn || bookingStatus == BookingStatus.checkedIn;
  bool get isCompleted => completionStatus == WorkCompletionStatus.completed;

  factory RosterWorkerModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = [];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List).map((s) => s.toString()).toList();
    }

    return RosterWorkerModel(
      bookingId: json['booking_id']?.toString() ?? '',
      workerProfileId: json['worker_profile_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'कार्यकर्ता',
      mobileNumber: json['mobile_number']?.toString(),
      selfieUrl: json['selfie_url']?.toString(),
      agreedWage: double.tryParse(json['agreed_wage']?.toString() ?? '500') ?? 500.0,
      bookingStatus: BookingStatus.fromString(json['booking_status']?.toString()),
      checkinCode: json['checkin_code']?.toString(),
      attendanceStatus: AttendanceStatus.fromString(json['attendance_status']?.toString()),
      checkInAt: json['check_in_at'] != null ? DateTime.tryParse(json['check_in_at'].toString()) : null,
      markedAt: json['marked_at'] != null ? DateTime.tryParse(json['marked_at'].toString()) : null,
      completionStatus: WorkCompletionStatus.fromString(json['completion_status']?.toString()),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      notes: json['notes']?.toString(),
      skills: parsedSkills,
    );
  }
}

class RosterMetricsModel {
  final int totalConfirmed;
  final int checkedIn;
  final int present;
  final int absent;
  final int noShow;
  final int completed;

  const RosterMetricsModel({
    this.totalConfirmed = 0,
    this.checkedIn = 0,
    this.present = 0,
    this.absent = 0,
    this.noShow = 0,
    this.completed = 0,
  });

  factory RosterMetricsModel.fromJson(Map<String, dynamic> json) {
    return RosterMetricsModel(
      totalConfirmed: int.tryParse(json['total_confirmed']?.toString() ?? '0') ?? 0,
      checkedIn: int.tryParse(json['checked_in']?.toString() ?? '0') ?? 0,
      present: int.tryParse(json['present']?.toString() ?? '0') ?? 0,
      absent: int.tryParse(json['absent']?.toString() ?? '0') ?? 0,
      noShow: int.tryParse(json['no_show']?.toString() ?? '0') ?? 0,
      completed: int.tryParse(json['completed']?.toString() ?? '0') ?? 0,
    );
  }
}

class JobAttendanceRosterModel {
  final String jobId;
  final String jobTitle;
  final String shiftDate;
  final String startTime;
  final String endTime;
  final int workersNeeded;
  final RosterMetricsModel metrics;
  final List<RosterWorkerModel> roster;

  const JobAttendanceRosterModel({
    required this.jobId,
    required this.jobTitle,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.workersNeeded,
    required this.metrics,
    this.roster = const [],
  });

  factory JobAttendanceRosterModel.fromJson(Map<String, dynamic> json) {
    List<RosterWorkerModel> parsedRoster = [];
    if (json['roster'] is List) {
      parsedRoster = (json['roster'] as List)
          .map((item) => RosterWorkerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return JobAttendanceRosterModel(
      jobId: json['job_id']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      shiftDate: json['shift_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      workersNeeded: int.tryParse(json['workers_needed']?.toString() ?? '0') ?? 0,
      metrics: json['metrics'] is Map<String, dynamic>
          ? RosterMetricsModel.fromJson(json['metrics'] as Map<String, dynamic>)
          : const RosterMetricsModel(),
      roster: parsedRoster,
    );
  }
}
