import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lagan_staff/features/worker/models/published_job.dart';
import 'package:lagan_staff/features/worker/models/worker_profile.dart';
import 'package:lagan_staff/features/worker/models/worker_skill.dart';
import 'package:lagan_staff/features/worker/presentation/worker_onboarding_notifier.dart';

void main() {
  group('Phase 3 - Worker Models Unit Tests', () {
    test('WorkerProfileModel parses from JSON correctly with active status', () {
      final json = {
        'worker_profile_id': 'wp-12345',
        'user_id': 'u-67890',
        'full_name': 'राम प्रवेश यादव',
        'phone': '9876543210',
        'locality': 'लंका',
        'city': 'Ghazipur',
        'district': 'Ghazipur',
        'pincode': '233001',
        'latitude': 25.5840,
        'longitude': 83.5770,
        'selfie_storage_path': 'u-67890/selfie_123.jpg',
        'status': 'active',
        'is_selfie_verified': true,
        'skills': [
          {
            'id': 'sk-1',
            'category_id': 'cat-w',
            'name': 'Table Service (टेबल सेवा)',
            'category_name': 'Waiters',
          }
        ],
      };

      final profile = WorkerProfileModel.fromJson(json);

      expect(profile.id, 'wp-12345');
      expect(profile.userId, 'u-67890');
      expect(profile.fullName, 'राम प्रवेश यादव');
      expect(profile.locality, 'लंका');
      expect(profile.city, 'Ghazipur');
      expect(profile.pincode, '233001');
      expect(profile.latitude, 25.5840);
      expect(profile.longitude, 83.5770);
      expect(profile.selfieStoragePath, 'u-67890/selfie_123.jpg');
      expect(profile.status, WorkerAccountStatus.active);
      expect(profile.isSelfieVerified, isTrue);
      expect(profile.isComplete, isTrue);
      expect(profile.skills.length, 1);
      expect(profile.skills.first.name, 'Table Service (टेबल सेवा)');
    });

    test('WorkerAccountStatus handles pending and suspended states correctly', () {
      expect(
        WorkerAccountStatus.fromString('pending_profile'),
        WorkerAccountStatus.pendingProfile,
      );
      expect(
        WorkerAccountStatus.fromString('suspended'),
        WorkerAccountStatus.suspended,
      );
      expect(
        WorkerAccountStatus.fromString('active'),
        WorkerAccountStatus.active,
      );
      expect(
        WorkerAccountStatus.fromString(null),
        WorkerAccountStatus.pendingProfile,
      );

      expect(WorkerAccountStatus.active.isActive, isTrue);
      expect(WorkerAccountStatus.suspended.isSuspended, isTrue);
      expect(WorkerAccountStatus.pendingProfile.isPending, isTrue);
    });

    test('SkillCategory and WorkerSkillItem parse and serialize correctly', () {
      final category = SkillCategory(
        id: 'cat-waiters',
        name: 'Waiters (वेटर)',
        slug: 'waiters',
        description: 'Event waiters',
        skills: [
          const WorkerSkillItem(
            id: 'sk-1',
            categoryId: 'cat-waiters',
            name: 'Table Service',
            categoryName: 'Waiters',
          ),
        ],
      );

      expect(category.skills.length, 1);
      expect(category.skills.first.name, 'Table Service');
      final json = category.skills.first.toJson();
      expect(json['id'], 'sk-1');
      expect(json['name'], 'Table Service');
    });

    test('PublishedJob calculates remaining spots and wages accurately', () {
      final json = {
        'id': 'job-101',
        'title': 'शादी वेटर शिफ्ट',
        'description': 'रात 11 बजे तक टेबल सेवा',
        'shift_date': '2026-11-20',
        'start_time': '18:00',
        'end_time': '23:30',
        'wage_amount': 650.00,
        'wage_rate_unit': 'per_shift',
        'workers_needed': 5,
        'workers_confirmed': 2,
        'status': 'published',
        'businesses': {
          'name': 'राजवाड़ा मैरिज लॉन',
          'locality': 'लंका',
        },
        'categories': {
          'name': 'Waiters',
        },
      };

      final job = PublishedJob.fromJson(json);

      expect(job.id, 'job-101');
      expect(job.title, 'शादी वेटर शिफ्ट');
      expect(job.businessName, 'राजवाड़ा मैरिज लॉन');
      expect(job.businessLocality, 'लंका');
      expect(job.categoryName, 'Waiters');
      expect(job.wageAmount, 650.0);
      expect(job.wageRateUnit, 'प्रति शिफ्ट');
      expect(job.workersNeeded, 5);
      expect(job.workersConfirmed, 2);
      expect(job.spotsRemaining, 3);
    });
  });

  group('Phase 3 - Worker Onboarding State Step Validations', () {
    test('Step 1 validation: Full Name requires at least 2 characters', () {
      const invalidState = WorkerOnboardingState(fullName: ' ');
      expect(invalidState.isStep1Valid, isFalse);

      const singleCharState = WorkerOnboardingState(fullName: 'A');
      expect(singleCharState.isStep1Valid, isFalse);

      const validState = WorkerOnboardingState(fullName: 'राकेश सिंह');
      expect(validState.isStep1Valid, isTrue);
    });

    test('Step 2 validation: At least one skill must be selected', () {
      const noSkillsState = WorkerOnboardingState(selectedSkillIds: {});
      expect(noSkillsState.isStep2Valid, isFalse);

      const withSkillState = WorkerOnboardingState(selectedSkillIds: {'sk-1'});
      expect(withSkillState.isStep2Valid, isTrue);
    });

    test('Step 3 validation: Locality and 6-digit Indian PIN are mandatory', () {
      const invalidLocality = WorkerOnboardingState(
        locality: ' ',
        pincode: '233001',
      );
      expect(invalidLocality.isStep3Valid, isFalse);

      const invalidPincode = WorkerOnboardingState(
        locality: 'लंका',
        pincode: '2330', // not 6 digits
      );
      expect(invalidPincode.isStep3Valid, isFalse);

      const invalidPinLeadingZero = WorkerOnboardingState(
        locality: 'लंका',
        pincode: '033001', // Indian PIN cannot start with 0
      );
      expect(invalidPinLeadingZero.isStep3Valid, isFalse);

      const validLocationState = WorkerOnboardingState(
        locality: 'लंका, गाजीपुर',
        pincode: '233001',
      );
      expect(validLocationState.isStep3Valid, isTrue);
    });

    test('Step 4 validation: Selfie image bytes must be present', () {
      const noSelfieState = WorkerOnboardingState(selfieBytes: null);
      expect(noSelfieState.isStep4Valid, isFalse);

      final withSelfieState = WorkerOnboardingState(
        selfieBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
        selfieFileName: 'selfie.jpg',
      );
      expect(withSelfieState.isStep4Valid, isTrue);
    });
  });
}
