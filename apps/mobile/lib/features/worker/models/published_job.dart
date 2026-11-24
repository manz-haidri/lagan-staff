import '../../../core/localization/app_language.dart';

class PublishedJob {
  final String id;
  final String title;
  final String? description;
  final String categoryName;
  final String businessName;
  final String businessLocality;
  final String reportingAddress;
  final String shiftDate;
  final String startTime;
  final String endTime;
  final double wageAmount;
  final String wageRateUnit;
  final int workersNeeded;
  final int workersConfirmed;
  final String status;

  const PublishedJob({
    required this.id,
    required this.title,
    this.description,
    required this.categoryName,
    required this.businessName,
    required this.businessLocality,
    required this.reportingAddress,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.wageAmount,
    this.wageRateUnit = 'प्रति शिफ्ट',
    required this.workersNeeded,
    this.workersConfirmed = 0,
    this.status = 'published',
  });

  String wageRateUnitFor(AppLanguage language) {
    if (!{'per_shift', '/ shift', 'प्रति शिफ्ट'}.contains(wageRateUnit)) return wageRateUnit;
    return switch (language) {
      AppLanguage.hindi => 'प्रति शिफ्ट',
      AppLanguage.hinglish => '/ shift',
      AppLanguage.english => '/ shift',
    };
  }

  int get spotsRemaining => (workersNeeded - workersConfirmed).clamp(0, workersNeeded);

  factory PublishedJob.fromJson(Map<String, dynamic> json) {
    final business = json['businesses'] as Map<String, dynamic>? ?? {};
    final category = json['categories'] as Map<String, dynamic>? ?? {};

    return PublishedJob(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Job Shift',
      description: json['description'] as String?,
      categoryName: category['name'] as String? ?? 'General Event',
      businessName: business['name'] as String? ?? 'Event Host',
      businessLocality: business['locality'] as String? ?? 'Ghazipur',
      reportingAddress: json['reporting_address'] as String? ?? 'Ghazipur, Uttar Pradesh',
      shiftDate: json['shift_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      wageAmount: double.tryParse(json['wage_amount']?.toString() ?? '500') ?? 500.0,
      wageRateUnit: json['wage_rate_unit'] == 'per_shift' ? 'प्रति शिफ्ट' : (json['wage_rate_unit'] as String? ?? 'प्रति शिफ्ट'),
      workersNeeded: int.tryParse(json['workers_needed']?.toString() ?? '1') ?? 1,
      workersConfirmed: int.tryParse(json['workers_confirmed']?.toString() ?? '0') ?? 0,
      status: json['status'] as String? ?? 'published',
    );
  }
}
