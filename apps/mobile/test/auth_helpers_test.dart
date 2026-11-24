import 'package:flutter_test/flutter_test.dart';
import 'package:lagan_staff/core/utils/auth_helpers.dart';
import 'package:lagan_staff/features/auth/models/user_profile.dart';

void main() {
  group('AuthHelpers Phone & OTP Validation and Formatting', () {
    test('Cleans 10-digit phone number with or without +91 prefix', () {
      expect(AuthHelpers.cleanPhoneNumber('+91 98765 43210'), '9876543210');
      expect(AuthHelpers.cleanPhoneNumber('919876543210'), '9876543210');
      expect(AuthHelpers.cleanPhoneNumber('9876543210'), '9876543210');
    });

    test('Formats 10-digit phone number to international E.164 (+91XXXXXXXXXX)', () {
      expect(AuthHelpers.formatToE164('9876543210'), '+919876543210');
      expect(AuthHelpers.formatToE164('+91 98765 43210'), '+919876543210');
    });

    test('Validates Indian phone numbers correctly', () {
      expect(AuthHelpers.isValidIndianPhone('9876543210'), isTrue);
      expect(AuthHelpers.isValidIndianPhone('7000123456'), isTrue);
      expect(AuthHelpers.isValidIndianPhone('5000123456'), isFalse); // Does not start with 6-9
      expect(AuthHelpers.isValidIndianPhone('12345'), isFalse); // Too short
      expect(AuthHelpers.isValidIndianPhone('98765432100'), isFalse); // Too long
    });

    test('Validates 6-digit SMS OTP correctly', () {
      expect(AuthHelpers.isValidSixDigitOtp('123456'), isTrue);
      expect(AuthHelpers.isValidSixDigitOtp('000000'), isTrue);
      expect(AuthHelpers.isValidSixDigitOtp('12345'), isFalse); // 5 digits
      expect(AuthHelpers.isValidSixDigitOtp('1234567'), isFalse); // 7 digits
      expect(AuthHelpers.isValidSixDigitOtp('12345a'), isFalse); // Non-numeric
    });

    test('Validates 4-digit PINs correctly', () {
      expect(AuthHelpers.isValidPin('1234'), isTrue);
      expect(AuthHelpers.isValidPin('0000'), isTrue);
      expect(AuthHelpers.isValidPin('123'), isFalse);
      expect(AuthHelpers.isValidPin('12345'), isFalse);
    });

    test('Extracts display phone number cleanly', () {
      expect(AuthHelpers.extractPhoneDisplay('+919876543210'), '9876543210');
      expect(AuthHelpers.extractPhoneDisplay('9876543210@laganstaff.in'), '9876543210');
    });
  });

  group('UserProfile and AppUserRole Models', () {
    test('Converts role strings correctly to AppUserRole enum', () {
      expect(AppUserRole.fromString('worker'), AppUserRole.worker);
      expect(AppUserRole.fromString('owner'), AppUserRole.owner);
      expect(AppUserRole.fromString('admin'), AppUserRole.admin);
      expect(AppUserRole.fromString('invalid'), isNull);
      expect(AppUserRole.fromString(null), isNull);
    });

    test('Parses UserProfile from JSON', () {
      final json = {
        'id': 'usr-123',
        'phone': '+919876543210',
        'full_name': 'Rahul Kumar',
        'role': 'worker',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.id, 'usr-123');
      expect(profile.fullName, 'Rahul Kumar');
      expect(profile.primaryRole, AppUserRole.worker);
      expect(profile.hasRole, isTrue);
    });
  });
}
