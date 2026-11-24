import '../../../core/localization/app_language.dart';

class OwnerJobHistoryItem {
  final String id;
  final String title;
  final String categoryName;
  final String reportingAddress;
  final String shiftDate;
  final String startTime;
  final String endTime;
  final int workersNeeded;
  final int workersConfirmed;
  final double wageAmount;
  final String wageRateUnit;
  final String status;
  final DateTime? createdAt;

  const OwnerJobHistoryItem({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.reportingAddress,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.workersNeeded,
    this.workersConfirmed = 0,
    required this.wageAmount,
    this.wageRateUnit = '/ shift',
    required this.status,
    this.createdAt,
  });

  String wageRateUnitFor(AppLanguage language) {
    return switch (language) {
      AppLanguage.hindi => '/ प्रति शिफ्ट',
      AppLanguage.hinglish => '/ shift',
      AppLanguage.english => '/ shift',
    };
  }

  String get statusDisplayName => statusDisplayNameFor(AppLanguage.english);

  String statusDisplayNameFor(AppLanguage language) {
    switch (status.toLowerCase()) {
      case 'published':
        return switch (language) {
          AppLanguage.hindi => 'प्रकाशित',
          AppLanguage.hinglish => 'Published',
          AppLanguage.english => 'Published',
        };
      case 'in_progress':
        return switch (language) {
          AppLanguage.hindi => 'प्रगति पर',
          AppLanguage.hinglish => 'In Progress',
          AppLanguage.english => 'In Progress',
        };
      case 'completed':
        return switch (language) {
          AppLanguage.hindi => 'पूर्ण',
          AppLanguage.hinglish => 'Completed',
          AppLanguage.english => 'Completed',
        };
      case 'cancelled':
        return switch (language) {
          AppLanguage.hindi => 'रद्द',
          AppLanguage.hinglish => 'Cancelled',
          AppLanguage.english => 'Cancelled',
        };
      case 'pending_admin_approval':
        return switch (language) {
          AppLanguage.hindi => 'समीक्षा प्रतीक्षित',
          AppLanguage.hinglish => 'Pending Approval',
          AppLanguage.english => 'Pending Approval',
        };
      case 'draft':
      default:
        return switch (language) {
          AppLanguage.hindi => 'ड्राफ्ट',
          AppLanguage.hinglish => 'Draft',
          AppLanguage.english => 'Draft',
        };
    }
  }

  factory OwnerJobHistoryItem.fromJson(Map<String, dynamic> json) {
    final cat = json['categories'] as Map<String, dynamic>? ?? {};

    return OwnerJobHistoryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'कार्य शिफ्ट',
      categoryName: cat['name'] as String? ?? 'General Event',
      reportingAddress: json['reporting_address'] as String? ?? 'गाजीपुर',
      shiftDate: json['shift_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      workersNeeded: int.tryParse(json['workers_needed']?.toString() ?? '1') ?? 1,
      workersConfirmed: int.tryParse(json['workers_confirmed']?.toString() ?? '0') ?? 0,
      wageAmount: double.tryParse(json['wage_amount']?.toString() ?? '500') ?? 500.0,
      wageRateUnit: json['wage_rate_unit'] == 'per_shift' ? 'प्रति शिफ्ट' : (json['wage_rate_unit'] as String? ?? 'प्रति शिफ्ट'),
      status: json['status'] as String? ?? 'published',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
