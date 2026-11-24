import 'package:flutter_test/flutter_test.dart';
import 'package:lagan_staff/core/localization/app_language.dart';
import 'package:lagan_staff/features/jobs/models/job_filter_model.dart';
import 'package:lagan_staff/features/jobs/models/job_model.dart';
import 'package:lagan_staff/features/jobs/models/job_status.dart';

void main() {
  group('Phase 6 - Job Discovery & Filters (JobFilterModel)', () {
    test('Empty filter has no active filters and zero count', () {
      const filter = JobFilterModel.empty;
      expect(filter.hasActiveFilters, isFalse);
      expect(filter.activeFiltersCount, equals(0));
      expect(filter.searchQuery, isNull);
      expect(filter.city, isNull);
      expect(filter.locality, isNull);
      expect(filter.shiftType, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
    });

    test('Search query activates filter count', () {
      const filter = JobFilterModel(searchQuery: 'वेटर');
      expect(filter.hasActiveFilters, isTrue);
      expect(filter.activeFiltersCount, equals(1));
    });

    test('City & Locality filters activate properly', () {
      const filter = JobFilterModel(city: 'Saidpur', locality: 'Station Road');
      expect(filter.hasActiveFilters, isTrue);
      expect(filter.activeFiltersCount, equals(2));
    });

    test('Date range & Shift type filters activate count', () {
      final now = DateTime.now();
      final filter = JobFilterModel(
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        shiftType: 'evening',
      );
      expect(filter.hasActiveFilters, isTrue);
      expect(filter.activeFiltersCount, equals(2)); // date range + shiftType
    });

    test('Multi-attribute combined filter calculates exact active count', () {
      final filter = JobFilterModel(
        searchQuery: 'हलवाई',
        categoryId: 'cat-halwai',
        city: 'Ghazipur',
        locality: 'Lanka',
        shiftDate: DateTime(2026, 11, 20),
        shiftType: 'morning',
        minWage: 600,
        foodProvided: true,
        transportProvided: true,
        skillIds: const ['skill-1', 'skill-2'],
      );
      expect(filter.hasActiveFilters, isTrue);
      // 10 distinct active filter facets
      expect(filter.activeFiltersCount, equals(10));
    });

    test('copyWith properly clears individual filter fields', () {
      const initial = JobFilterModel(
        searchQuery: 'वेटर',
        city: 'Zamania',
        locality: 'Station Road',
        shiftType: 'night',
        minWage: 500,
      );
      expect(initial.activeFiltersCount, equals(5));

      final cleared = initial.copyWith(
        clearSearch: true,
        clearCity: true,
        clearShiftType: true,
      );
      expect(cleared.searchQuery, isNull);
      expect(cleared.city, isNull);
      expect(cleared.shiftType, isNull);
      expect(cleared.locality, equals('Station Road'));
      expect(cleared.minWage, equals(500));
      expect(cleared.activeFiltersCount, equals(2));
    });
  });

  group('Phase 6 - JobModel Expiration & Availability Logic', () {
    test('JobModel correctly identifies expired shifts', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final pastDateStr = "${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}";

      final expiredJob = JobModel(
        id: 'job-past-1',
        businessId: 'biz-1',
        categoryId: 'cat-waiters',
        categoryName: 'वेटर',
        title: 'शादी में वेटर',
        reportingAddress: 'स्टेशन रोड',
        locality: 'गाजीपुर',
        shiftDate: pastDateStr,
        startTime: '10:00:00',
        endTime: '18:00:00',
        workersNeeded: 5,
        wageAmount: 600,
        status: JobStatus.published,
      );

      expect(expiredJob.isExpired, isTrue);
      expect(expiredJob.isAvailableForShift, isFalse);
      expect(expiredJob.availabilityStatusLabel, equals('Expired'));
      expect(expiredJob.availabilityStatusLabelFor(AppLanguage.hindi), equals('समाप्त'));
    });

    test('JobModel correctly identifies active future shifts', () {
      final futureDate = DateTime.now().add(const Duration(days: 3));
      final futureDateStr = "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

      final activeJob = JobModel(
        id: 'job-future-1',
        businessId: 'biz-1',
        categoryId: 'cat-waiters',
        categoryName: 'वेटर',
        title: 'इवेंट वेटर',
        reportingAddress: 'लंका',
        locality: 'गाजीपुर',
        shiftDate: futureDateStr,
        startTime: '16:00:00',
        endTime: '23:00:00',
        workersNeeded: 8,
        wageAmount: 700,
        status: JobStatus.published,
      );

      expect(activeJob.isExpired, isFalse);
      expect(activeJob.isAvailableForShift, isTrue);
      expect(activeJob.availabilityStatusLabel, equals('Open Shift'));
      expect(activeJob.availabilityStatusLabelFor(AppLanguage.hindi), equals('खुली शिफ्ट'));
    });

    test('JobModel availability status respects lifecycle states', () {
      const baseJob = JobModel(
        id: 'job-lifecycle-1',
        businessId: 'biz-1',
        categoryId: 'cat-cleaners',
        categoryName: 'सफाई कर्मी',
        title: 'सफाई कार्य',
        reportingAddress: 'रविन्द्रपुरी',
        locality: 'गाजीपुर',
        shiftDate: '2099-12-31',
        startTime: '08:00:00',
        endTime: '16:00:00',
        workersNeeded: 4,
        wageAmount: 500,
      );

      // Draft
      expect(baseJob.availabilityStatusLabel, equals('Draft'));
      expect(baseJob.availabilityStatusLabelFor(AppLanguage.hindi), equals('ड्राफ्ट'));
      expect(baseJob.isAvailableForShift, isFalse);

      // Pending
      final pendingJob = JobModel(
        id: baseJob.id,
        businessId: baseJob.businessId,
        categoryId: baseJob.categoryId,
        categoryName: baseJob.categoryName,
        title: baseJob.title,
        reportingAddress: baseJob.reportingAddress,
        locality: baseJob.locality,
        shiftDate: baseJob.shiftDate,
        startTime: baseJob.startTime,
        endTime: baseJob.endTime,
        workersNeeded: baseJob.workersNeeded,
        wageAmount: baseJob.wageAmount,
        status: JobStatus.pendingAdminApproval,
      );
      expect(pendingJob.availabilityStatusLabel, equals('Pending Review'));
      expect(pendingJob.availabilityStatusLabelFor(AppLanguage.hindi), equals('स्वीकृति प्रतीक्षित'));
      expect(pendingJob.isAvailableForShift, isFalse);

      // Cancelled
      final cancelledJob = JobModel(
        id: baseJob.id,
        businessId: baseJob.businessId,
        categoryId: baseJob.categoryId,
        categoryName: baseJob.categoryName,
        title: baseJob.title,
        reportingAddress: baseJob.reportingAddress,
        locality: baseJob.locality,
        shiftDate: baseJob.shiftDate,
        startTime: baseJob.startTime,
        endTime: baseJob.endTime,
        workersNeeded: baseJob.workersNeeded,
        wageAmount: baseJob.wageAmount,
        status: JobStatus.cancelled,
      );
      expect(cancelledJob.availabilityStatusLabel, equals('Cancelled'));
      expect(cancelledJob.availabilityStatusLabelFor(AppLanguage.hindi), equals('रद्द'));
      expect(cancelledJob.isAvailableForShift, isFalse);
    });
  });
}
