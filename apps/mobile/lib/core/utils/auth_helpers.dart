class AuthHelpers {
  /// Cleans any non-digit characters and strips a leading country code (+91 or 91)
  static String cleanPhoneNumber(String rawPhone) {
    String digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 10 && digitsOnly.startsWith('91')) {
      digitsOnly = digitsOnly.substring(2);
    }
    return digitsOnly;
  }

  /// Formats a 10-digit Indian phone number to international E.164 (+91XXXXXXXXXX)
  static String formatToE164(String phone) {
    final cleaned = cleanPhoneNumber(phone);
    return '+91$cleaned';
  }

  /// Validates standard 10-digit Indian mobile number (begins with 6, 7, 8, or 9)
  static bool isValidIndianPhone(String phone) {
    final cleaned = cleanPhoneNumber(phone);
    return RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
  }

  /// Validates a standard 6-digit SMS OTP
  static bool isValidSixDigitOtp(String otp) {
    return RegExp(r'^\d{6}$').hasMatch(otp.trim());
  }

  /// Validates a 4-digit security PIN
  static bool isValidPin(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin.trim());
  }

  /// Maps a 10-digit phone number to a synthetic internal Supabase email
  static String formatPhoneToSyntheticEmail(String phone) {
    final cleaned = cleanPhoneNumber(phone);
    return '$cleaned@laganstaff.in';
  }

  /// Deterministically salts and pads a 4-digit PIN for synthetic auth
  static String formatPinToSyntheticPassword(String pin) {
    final cleanPin = pin.trim();
    return 'LaganStaff#$cleanPin*2026';
  }

  /// Extracts display 10-digit phone number from synthetic email
  static String extractPhoneFromSyntheticEmail(String email) {
    return email.split('@').first;
  }

  /// Extracts display 10-digit phone number from synthetic email or E.164 string
  static String extractPhoneDisplay(String phoneOrEmail) {
    if (phoneOrEmail.contains('@')) {
      return phoneOrEmail.split('@').first;
    }
    final cleaned = cleanPhoneNumber(phoneOrEmail);
    if (cleaned.length == 10) {
      return cleaned;
    }
    return phoneOrEmail;
  }
}
