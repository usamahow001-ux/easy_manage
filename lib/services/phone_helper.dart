class PhoneHelper {
  /// Cleans and normalizes a phone number to standard E.164 format.
  /// Default country code is '+92' if 10-11 local digits starting with 0 or 3 are provided.
  static String normalize(String rawPhone, {String defaultCountryCode = '+92'}) {
    if (rawPhone.trim().isEmpty) return '';

    // Remove all non-digit and non-plus characters
    String cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Replace leading double zero '00' with '+'
    if (cleaned.startsWith('00')) {
      return '+${cleaned.substring(2)}';
    }

    // Handle local numbers like 03001234567 -> +923001234567
    if (cleaned.startsWith('0') && cleaned.length >= 10) {
      final withoutZero = cleaned.substring(1);
      final cleanCode = defaultCountryCode.startsWith('+')
          ? defaultCountryCode
          : '+$defaultCountryCode';
      return '$cleanCode$withoutZero';
    }

    // Handle 10-digit number without leading 0, e.g. 3001234567
    if (cleaned.length == 10 && cleaned.startsWith('3')) {
      final cleanCode = defaultCountryCode.startsWith('+')
          ? defaultCountryCode
          : '+$defaultCountryCode';
      return '$cleanCode$cleaned';
    }

    // If already has country digits without '+'
    if (cleaned.startsWith('92') && cleaned.length >= 12) {
      return '+$cleaned';
    }

    return cleaned.isNotEmpty ? '+$cleaned' : '';
  }

  /// Formats a normalized phone for friendly display: e.g. +92 300 1234567
  static String formatForDisplay(String phone) {
    final norm = normalize(phone);
    if (norm.startsWith('+92') && norm.length == 13) {
      return '${norm.substring(0, 3)} ${norm.substring(3, 6)} ${norm.substring(6)}';
    }
    return phone;
  }
}
