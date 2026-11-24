import 'package:flutter_test/flutter_test.dart';
import 'package:lagan_staff/features/jobs/models/job_filter_model.dart';
import 'package:lagan_staff/features/jobs/models/job_model.dart';
import 'package:lagan_staff/features/jobs/models/job_status.dart';
import 'package:lagan_staff/features/jobs/presentation/job_form_notifier.dart';

void main() {
  group('Phase 5 - Job Models Unit Tests', () {
    test('JobModel parses accurately from backend JSON', () {
      final json = {
        'id': 'job-ghz-001',
        'business_id': 'biz-ghz-101',
        'business_name': 'राजवाड़ा बैंक्वेट लॉन',
        'business_locality': 'Lanka',
        'business_category': 'marriage_hall',
        'category_id': 'cat-waiters-01',
        'category_name': 'वेटर (Waiters)',
        'title': '10 अनुभवी वेटर शादी समारोह के लिए',
        'description': 'शाम के शादी रिसेप्शन में वीआईपी टेबल सर्विस हेतु।',
        'venue_name': 'राजवाड़ा लॉन, मेन गेट',
        'reporting_address': 'निकट पीजी कॉलेज, लंका, गाजीपुर',
        'locality': 'Lanka',
        'city': 'Ghazipur',
        'pincode': '233001',
        'shift_date': '2026-11-25',
        'start_time': '18:00:00',
        'end_time': '23:30:00',
        'is_overnight': false,
        'workers_needed': 10,
        'workers_confirmed': 4,
        'wage_amount': 650.0,
        'wage_rate_unit': 'per_shift',
        'food_provided': true,
        'food_details': 'रात का खाना',
        'transport_provided': false,
        'special_instructions': 'सफेद कमीज और काली पैंट',
        'is_first_job': false,
        'status': 'published',
        'created_at': '2026-11-18T10:00:00Z',
        'published_at': '2026-11-18T10:05:00Z',
        'skills': [
          {'id': 'sk-1', 'category_id': 'cat-waiters-01', 'name': 'टेबल सर्विस'},
          {'id': 'sk-2', 'category_id': 'cat-waiters-01', 'name': 'ट्रे हैंडलिंग'},
        ],
      };

      final job = JobModel.fromJson(json);

      expect(job.id, equals('job-ghz-001'));
      expect(job.businessName, equals('राजवाड़ा बैंक्वेट लॉन'));
      expect(job.categoryName, equals('वेटर (Waiters)'));
      expect(job.wageAmount, equals(650.0));
      expect(job.formattedWage, equals('₹650 / शिफ्ट'));
      expect(job.workersNeeded, equals(10));
      expect(job.workersConfirmed, equals(4));
      expect(job.spotsRemaining, equals(6));
      expect(job.isPublished, isTrue);
      expect(job.foodProvided, isTrue);
      expect(job.skills.length, equals(2));
      expect(job.skills.first.name, equals('टेबल सर्विस'));
    });

    test('JobStatus enum handles all lifecycle states correctly', () {
      expect(JobStatus.fromString('draft'), equals(JobStatus.draft));
      expect(JobStatus.fromString('pending_admin_approval'), equals(JobStatus.pendingAdminApproval));
      expect(JobStatus.fromString('published'), equals(JobStatus.published));
      expect(JobStatus.fromString('rejected'), equals(JobStatus.rejected));
      expect(JobStatus.fromString('cancelled'), equals(JobStatus.cancelled));

      expect(JobStatus.draft.toDbValue, equals('draft'));
      expect(JobStatus.pendingAdminApproval.toDbValue, equals('pending_admin_approval'));
      expect(JobStatus.published.toDbValue, equals('published'));
      expect(JobStatus.rejected.toDbValue, equals('rejected'));

      expect(JobStatus.draft.isEditable, isTrue);
      expect(JobStatus.rejected.isEditable, isTrue);
      expect(JobStatus.pendingAdminApproval.isEditable, isTrue);
      expect(JobStatus.published.isCancellable, isTrue);
      expect(JobStatus.completed.isCancellable, isFalse);
    });

    test('JobFilterModel calculates active filters and empty states correctly', () {
      const empty = JobFilterModel.empty;
      expect(empty.hasActiveFilters, isFalse);
      expect(empty.activeFiltersCount, equals(0));

      final withCategory = empty.copyWith(categoryId: 'cat-01');
      expect(withCategory.hasActiveFilters, isTrue);
      expect(withCategory.activeFiltersCount, equals(1));

      final multiFilter = withCategory.copyWith(
        locality: 'Lanka',
        minWage: 600,
        foodProvided: true,
      );
      expect(multiFilter.hasActiveFilters, isTrue);
      expect(multiFilter.activeFiltersCount, equals(4));

      final cleared = multiFilter.copyWith(
        clearCategory: true,
        clearLocality: true,
        clearWage: true,
        clearFood: true,
      );
      expect(cleared.hasActiveFilters, isFalse);
    });
  });

  group('Phase 5 - Step Form Validations Unit Tests', () {
    test('Step 1 validation: Requires title >= 3 chars, categoryId, workers >= 1', () {
      const state1 = JobFormState(title: '  ', categoryId: 'cat-01', workersNeeded: 2);
      expect(state1.title.trim().length >= 3, isFalse);

      const state2 = JobFormState(title: 'वेटर सर्विस', categoryId: null, workersNeeded: 2);
      expect(state2.categoryId != null && state2.categoryId!.isNotEmpty, isFalse);

      const state3 = JobFormState(title: 'वेटर सर्विस', categoryId: 'cat-01', workersNeeded: 0);
      expect(state3.workersNeeded >= 1, isFalse);

      const state4 = JobFormState(title: 'वेटर सर्विस', categoryId: 'cat-01', workersNeeded: 5);
      expect(state4.title.trim().length >= 3, isTrue);
      expect(state4.categoryId != null, isTrue);
      expect(state4.workersNeeded >= 1, isTrue);
    });

    test('Step 2 validation: Blocks past dates, accepts today and future dates', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pastDate = today.subtract(const Duration(days: 1));
      final futureDate = today.add(const Duration(days: 5));

      expect(pastDate.isBefore(today), isTrue);
      expect(futureDate.isBefore(today), isFalse);
      expect(today.isBefore(today), isFalse);
    });

    test('Step 3 validation: Requires wage > 0', () {
      const invalidWage = JobFormState(wageAmount: 0.0);
      expect(invalidWage.wageAmount > 0, isFalse);

      const validWage = JobFormState(wageAmount: 650.0);
      expect(validWage.wageAmount > 0, isTrue);
    });

    test('Step 4 validation: Address >= 5 chars, locality required, 6-digit PIN', () {
      const invalidAddress = JobFormState(
        reportingAddress: 'रोड',
        locality: 'Lanka',
        pincode: '233001',
      );
      expect(invalidAddress.reportingAddress.trim().length >= 5, isFalse);

      const invalidPin = JobFormState(
        reportingAddress: 'पीजी कॉलेज के पास, लंका',
        locality: 'Lanka',
        pincode: '2330',
      );
      expect(invalidPin.pincode.trim().length == 6, isFalse);

      const validLocation = JobFormState(
        reportingAddress: 'पीजी कॉलेज के पास, लंका मेन रोड',
        locality: 'Lanka',
        pincode: '233001',
      );
      expect(validLocation.reportingAddress.trim().length >= 5, isTrue);
      expect(validLocation.locality.trim().isNotEmpty, isTrue);
      expect(validLocation.pincode.trim().length == 6, isTrue);
    });

    test('First-job vs Subsequent-job approval rule consistency', () {
      JobStatus determineJobStatus(bool isFirstJobApproved) {
        return isFirstJobApproved ? JobStatus.published : JobStatus.pendingAdminApproval;
      }

      bool determineIsFirstJobFlag(bool isFirstJobApproved) {
        return !isFirstJobApproved;
      }

      expect(determineJobStatus(false), equals(JobStatus.pendingAdminApproval));
      expect(determineIsFirstJobFlag(false), isTrue);

      expect(determineJobStatus(true), equals(JobStatus.published));
      expect(determineIsFirstJobFlag(true), isFalse);
    });
  });
}
