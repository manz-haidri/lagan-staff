import 'package:flutter_test/flutter_test.dart';
import 'package:lagan_staff/features/owner/models/business_document_model.dart';
import 'package:lagan_staff/features/owner/models/business_model.dart';
import 'package:lagan_staff/features/owner/models/owner_job_history_item.dart';
import 'package:lagan_staff/features/owner/presentation/owner_onboarding_notifier.dart';

void main() {
  group('Phase 4 - Owner Business Models Unit Tests', () {
    test('BusinessModel parses from JSON correctly with all metadata', () {
      final json = {
        'id': 'biz-100',
        'created_by': 'owner-1',
        'name': 'राजवाड़ा मैरिज लॉन',
        'business_type': 'marriage_hall',
        'description': '1500 व्यक्तियों की क्षमता वाला विशाल लॉन',
        'contact_person': 'सुनील सिंह',
        'contact_phone': '9876543210',
        'country': 'India',
        'state': 'Uttar Pradesh',
        'district': 'Ghazipur',
        'city': 'Ghazipur',
        'locality': 'लंका',
        'address': 'निकट पीजी कॉलेज गेट, लंका',
        'pincode': '233001',
        'latitude': 25.5840,
        'longitude': 83.5770,
        'gst_or_trade_id': '09AAAAA0000A1Z5',
        'verification_status': 'verified',
        'is_first_job_approved': false,
        'created_at': '2026-11-18T10:00:00Z',
        'documents': [
          {
            'id': 'doc-1',
            'business_id': 'biz-100',
            'document_type': 'visiting_card',
            'storage_path': 'biz-100/card.jpg',
            'file_name': 'card.jpg',
            'file_size_bytes': 204800,
            'mime_type': 'image/jpeg',
          }
        ],
      };

      final biz = BusinessModel.fromJson(json);

      expect(biz.id, 'biz-100');
      expect(biz.name, 'राजवाड़ा मैरिज लॉन');
      expect(biz.categoryType, BusinessCategoryType.marriageHall);
      expect(biz.locality, 'लंका');
      expect(biz.pincode, '233001');
      expect(biz.contactPhone, '9876543210');
      expect(biz.gstOrTradeId, '09AAAAA0000A1Z5');
      expect(biz.verificationStatus, BusinessVerificationStatus.verified);
      expect(biz.verificationStatus.isVerified, isTrue);
      expect(biz.canEdit, isFalse); // Verified cannot be directly edited
      expect(biz.documents.length, 1);
    });

    test('BusinessVerificationStatus covers all states accurately', () {
      expect(
        BusinessVerificationStatus.fromString('draft'),
        BusinessVerificationStatus.draft,
      );
      expect(
        BusinessVerificationStatus.fromString('pending'),
        BusinessVerificationStatus.pending,
      );
      expect(
        BusinessVerificationStatus.fromString('under_review'),
        BusinessVerificationStatus.underReview,
      );
      expect(
        BusinessVerificationStatus.fromString('verified'),
        BusinessVerificationStatus.verified,
      );
      expect(
        BusinessVerificationStatus.fromString('rejected'),
        BusinessVerificationStatus.rejected,
      );
      expect(
        BusinessVerificationStatus.fromString('suspended'),
        BusinessVerificationStatus.suspended,
      );

      expect(BusinessVerificationStatus.draft.isDraft, isTrue);
      expect(BusinessVerificationStatus.pending.isPending, isTrue);
      expect(BusinessVerificationStatus.underReview.isUnderReview, isTrue);
      expect(BusinessVerificationStatus.verified.isVerified, isTrue);
      expect(BusinessVerificationStatus.rejected.isRejected, isTrue);
      expect(BusinessVerificationStatus.suspended.isSuspended, isTrue);
    });

    test('BusinessCategoryType correctly converts codes and labels', () {
      expect(
        BusinessCategoryType.fromString('catering_agency'),
        BusinessCategoryType.cateringAgency,
      );
      expect(
        BusinessCategoryType.fromString('tent_house'),
        BusinessCategoryType.tentHouse,
      );
      expect(
        BusinessCategoryType.fromString('event_organizer'),
        BusinessCategoryType.eventOrganizer,
      );
      expect(
        BusinessCategoryType.fromString('dj_sound'),
        BusinessCategoryType.djSound,
      );
      expect(
        BusinessCategoryType.fromString('other'),
        BusinessCategoryType.other,
      );

      expect(BusinessCategoryType.cateringAgency.code, 'catering_agency');
      expect(BusinessCategoryType.tentHouse.code, 'tent_house');
      expect(BusinessCategoryType.djSound.code, 'dj_sound');
    });

    test('BusinessDocumentModel formats file sizes and types accurately', () {
      final docSmall = BusinessDocumentModel.fromJson({
        'id': 'd-1',
        'business_id': 'b-1',
        'document_type': 'visiting_card',
        'storage_path': 'b-1/card.jpg',
        'file_name': 'visiting_card.jpg',
        'file_size_bytes': 51200, // 50 KB
        'mime_type': 'image/jpeg',
      });

      expect(docSmall.typeDisplayName, contains('Visiting Card'));
      expect(docSmall.fileSizeFormatted, '50.0 KB');

      final docLarge = BusinessDocumentModel.fromJson({
        'id': 'd-2',
        'business_id': 'b-1',
        'document_type': 'gst_certificate',
        'storage_path': 'b-1/gst.pdf',
        'file_name': 'gst.pdf',
        'file_size_bytes': 2097152, // 2 MB
        'mime_type': 'application/pdf',
      });

      expect(docLarge.typeDisplayName, contains('GST Certificate'));
      expect(docLarge.fileSizeFormatted, '2.0 MB');
    });

    test('OwnerJobHistoryItem parses accurately', () {
      final item = OwnerJobHistoryItem.fromJson({
        'id': 'j-1',
        'title': 'शादी वेटर शिफ्ट',
        'reporting_address': 'राजवाड़ा लॉन, लंका',
        'shift_date': '2026-11-20',
        'start_time': '18:00',
        'end_time': '23:30',
        'workers_needed': 6,
        'workers_confirmed': 4,
        'wage_amount': 650.0,
        'wage_rate_unit': 'per_shift',
        'status': 'published',
        'categories': {'name': 'Waiters'},
      });

      expect(item.id, 'j-1');
      expect(item.categoryName, 'Waiters');
      expect(item.workersNeeded, 6);
      expect(item.workersConfirmed, 4);
      expect(item.wageAmount, 650.0);
      expect(item.statusDisplayName, contains('Published'));
    });
  });

  group('Phase 4 - Owner Onboarding State Validations', () {
    test('Step 2 validation: Requires business name >= 2 chars and contact phone', () {
      const invalidNameState = OwnerOnboardingState(
        businessName: ' ',
        contactPhone: '9876543210',
      );
      expect(invalidNameState.isStep2Valid, isFalse);

      const invalidPhoneState = OwnerOnboardingState(
        businessName: 'राज मैरिज लॉन',
        contactPhone: '123',
        verifiedMobile: '',
      );
      expect(invalidPhoneState.isStep2Valid, isFalse);

      const validState = OwnerOnboardingState(
        businessName: 'राज मैरिज लॉन',
        contactPhone: '9876543210',
      );
      expect(validState.isStep2Valid, isTrue);
    });

    test('Step 3 validation: Requires locality >= 2 chars and 6-digit Indian PIN', () {
      const invalidLocality = OwnerOnboardingState(
        locality: ' ',
        pincode: '233001',
      );
      expect(invalidLocality.isStep3Valid, isFalse);

      const invalidPincode = OwnerOnboardingState(
        locality: 'लंका',
        pincode: '2330', // not 6 digits
      );
      expect(invalidPincode.isStep3Valid, isFalse);

      const validLocationState = OwnerOnboardingState(
        locality: 'लंका, गाजीपुर',
        pincode: '233001',
      );
      expect(validLocationState.isStep3Valid, isTrue);
    });

    test('Step 4 validation: Documents are strictly optional for MVP', () {
      const stateWithNoDocs = OwnerOnboardingState(uploadedDocuments: []);
      expect(stateWithNoDocs.isStep4Valid, isTrue);
    });
  });
}
