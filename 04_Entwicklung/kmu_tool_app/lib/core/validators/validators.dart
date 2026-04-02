/// Schweizer Telefonnummer-Validator.
/// Akzeptiert: +41 79 123 45 67, 079 123 45 67, 0791234567, etc.
class PhoneValidator {
  static final _phoneRegex = RegExp(
    r'^(\+41|0041|0)\s*'     // Ländervorwahl oder 0
    r'[1-9]\d'               // Vorwahl (2 Ziffern, erste nicht 0)
    r'[\s\-]*'
    r'\d{3}'                 // Block 1
    r'[\s\-]*'
    r'\d{2}'                 // Block 2
    r'[\s\-]*'
    r'\d{2}$',               // Block 3
  );

  /// Validiert eine Schweizer Telefonnummer.
  /// Gibt eine Fehlermeldung zurück oder null wenn gültig.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final cleaned = value.trim();
    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Ungueltige Telefonnummer (z.B. +41 79 123 45 67)';
    }
    return null;
  }

  /// Formatiert eine Nummer ins Schweizer Format: +41 79 123 45 67.
  static String? format(String? value) {
    if (value == null || value.trim().isEmpty) return value;
    // Alle nicht-Ziffern entfernen ausser +
    var digits = value.replaceAll(RegExp(r'[^\d+]'), '');

    // 0 am Anfang → +41
    if (digits.startsWith('0') && !digits.startsWith('00')) {
      digits = '+41${digits.substring(1)}';
    } else if (digits.startsWith('0041')) {
      digits = '+41${digits.substring(4)}';
    }

    // Formatieren: +41 XX XXX XX XX
    if (digits.startsWith('+41') && digits.length == 12) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 5)} '
          '${digits.substring(5, 8)} ${digits.substring(8, 10)} '
          '${digits.substring(10, 12)}';
    }
    return value; // Originalwert wenn Formatierung nicht möglich
  }
}

/// E-Mail-Validator.
class EmailValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Ungueltige E-Mail-Adresse';
    }
    return null;
  }
}
