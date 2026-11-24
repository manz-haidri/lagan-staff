import '../../../core/localization/app_language.dart';
import 'category_model.dart';
import 'job_status.dart';

class JobModel {
  final String id;
  final String businessId;
  final String? businessName;
  final String? businessLocality;
  final String? businessCategory;
  final String categoryId;
  final String categoryName;
  final String? createdById;
  final String title;
  final String? description;
  final String? venueName;
  final String reportingAddress;
  final String locality;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String shiftDate;
  final String startTime;
  final String endTime;
  final bool isOvernight;
  final int workersNeeded;
  final int workersConfirmed;
  final double wageAmount;
  final String wageRateUnit;
  final String? paymentInstructions;
  final bool foodProvided;
  final String? foodDetails;
  final bool transportProvided;
  final String? transportDetails;
  final String? specialInstructions;
  final bool isFirstJob;
  final JobStatus status;
  final String? adminRejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? publishedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SkillModel> skills;

  const JobModel({
    required this.id,
    required this.businessId,
    this.businessName,
    this.businessLocality,
    this.businessCategory,
    required this.categoryId,
    required this.categoryName,
    this.createdById,
    required this.title,
    this.description,
    this.venueName,
    required this.reportingAddress,
    required this.locality,
    this.city = 'Ghazipur',
    this.district = 'Ghazipur',
    this.state = 'Uttar Pradesh',
    this.pincode = '233001',
    this.latitude,
    this.longitude,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.isOvernight = false,
    required this.workersNeeded,
    this.workersConfirmed = 0,
    required this.wageAmount,
    this.wageRateUnit = 'per_shift',
    this.paymentInstructions,
    this.foodProvided = false,
    this.foodDetails,
    this.transportProvided = false,
    this.transportDetails,
    this.specialInstructions,
    this.isFirstJob = false,
    this.status = JobStatus.draft,
    this.adminRejectionReason,
    this.approvedBy,
    this.approvedAt,
    this.publishedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
    this.skills = const [],
  });

  int get spotsRemaining => (workersNeeded - workersConfirmed).clamp(0, workersNeeded);

  String get formattedWage => '₹${wageAmount.toStringAsFixed(0)} / शिफ्ट';

  String get formattedShiftTime => '$startTime से $endTime${isOvernight ? ' (रात की शिफ्ट)' : ''}';

  bool get isPublished => status == JobStatus.published;
  bool get isPendingApproval => status == JobStatus.pendingAdminApproval;
  bool get isRejected => status == JobStatus.rejected;
  bool get isDraft => status == JobStatus.draft;
  bool get isCancelled => status == JobStatus.cancelled;

  /// Determines if the job shift date has already passed.
  bool get isExpired {
    final parsedDate = DateTime.tryParse(shiftDate);
    if (parsedDate == null) return false;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final jobDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    return jobDay.isBefore(today);
  }

  /// Whether the job is actively open for worker shifts
  bool get isAvailableForShift => isPublished && !isExpired;

  String wageRateUnitFor(AppLanguage language) {
    return switch (language) {
      AppLanguage.hindi => '/ प्रति शिफ्ट',
      AppLanguage.hinglish => '/ shift',
      AppLanguage.english => '/ shift',
    };
  }

  /// Availability status badge label with language support
  String get availabilityStatusLabel => availabilityStatusLabelFor(AppLanguage.english);

  String availabilityStatusLabelFor(AppLanguage language) {
    if (status == JobStatus.cancelled) {
      return switch (language) {
        AppLanguage.hindi => 'रद्द',
        AppLanguage.hinglish => 'Cancelled',
        AppLanguage.english => 'Cancelled',
      };
    }
    if (isExpired) {
      return switch (language) {
        AppLanguage.hindi => 'समाप्त',
        AppLanguage.hinglish => 'Expired',
        AppLanguage.english => 'Expired',
      };
    }
    if (status == JobStatus.published) {
      return switch (language) {
        AppLanguage.hindi => 'खुली शिफ्ट',
        AppLanguage.hinglish => 'Open Shift',
        AppLanguage.english => 'Open Shift',
      };
    }
    if (status == JobStatus.pendingAdminApproval) {
      return switch (language) {
        AppLanguage.hindi => 'स्वीकृति प्रतीक्षित',
        AppLanguage.hinglish => 'Pending Review',
        AppLanguage.english => 'Pending Review',
      };
    }
    if (status == JobStatus.rejected) {
      return switch (language) {
        AppLanguage.hindi => 'अस्वीकृत',
        AppLanguage.hinglish => 'Rejected',
        AppLanguage.english => 'Rejected',
      };
    }
    if (status == JobStatus.draft) {
      return switch (language) {
        AppLanguage.hindi => 'ड्राफ्ट',
        AppLanguage.hinglish => 'Draft',
        AppLanguage.english => 'Draft',
      };
    }
    return status.displayNameFor(language);
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    // Parse skills list
    List<SkillModel> parsedSkills = [];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List).map((s) {
        if (s is Map<String, dynamic>) {
          return SkillModel(
            id: s['id']?.toString() ?? '',
            categoryId: s['category_id']?.toString() ?? '',
            name: s['name']?.toString() ?? '',
          );
        }
        return SkillModel(id: '', categoryId: '', name: s.toString());
      }).toList();
    }

    return JobModel(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      businessName: json['business_name'] as String? ??
          (json['businesses'] != null ? json['businesses']['name'] as String? : null),
      businessLocality: json['business_locality'] as String? ??
          (json['businesses'] != null ? json['businesses']['locality'] as String? : null),
      businessCategory: json['business_category'] as String?,
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['category_name'] as String? ??
          (json['categories'] is Map ? json['categories']['name'] as String? ?? 'इवेंट' : 'इवेंट'),
      createdById: json['created_by'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      venueName: json['venue_name'] as String?,
      reportingAddress: json['reporting_address'] as String? ?? '',
      locality: json['locality'] as String? ?? 'गाजीपुर',
      city: json['city'] as String? ?? 'Ghazipur',
      district: json['district'] as String? ?? 'Ghazipur',
      state: json['state'] as String? ?? 'Uttar Pradesh',
      pincode: json['pincode'] as String? ?? '233001',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      shiftDate: json['shift_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      isOvernight: json['is_overnight'] as bool? ?? false,
      workersNeeded: int.tryParse(json['workers_needed']?.toString() ?? '1') ?? 1,
      workersConfirmed: int.tryParse(json['workers_confirmed']?.toString() ?? '0') ?? 0,
      wageAmount: double.tryParse(json['wage_amount']?.toString() ?? '500') ?? 500.0,
      wageRateUnit: json['wage_rate_unit'] as String? ?? 'per_shift',
      paymentInstructions: json['payment_instructions'] as String?,
      foodProvided: json['food_provided'] as bool? ?? false,
      foodDetails: json['food_details'] as String?,
      transportProvided: json['transport_provided'] as bool? ?? false,
      transportDetails: json['transport_details'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      isFirstJob: json['is_first_job'] as bool? ?? false,
      status: JobStatus.fromString(json['status'] as String?),
      adminRejectionReason: json['admin_rejection_reason'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'].toString()) : null,
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.tryParse(json['cancelled_at'].toString()) : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      skills: parsedSkills,
    );
  }
}
