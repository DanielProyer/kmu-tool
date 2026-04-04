/// Multi-Country Telefonnummer-Validator (CH, LI, DE, FR, IT).
/// Akzeptiert internationale (+XX) und lokale (0XX) Formate.
class PhoneValidator {
  static const _countryRules = <String, _CountryRule>{
    '+41': _CountryRule(name: 'CH', prefix: '+41', localPrefix: '0', digitsAfterPrefix: 9),
    '+423': _CountryRule(name: 'LI', prefix: '+423', localPrefix: '00423', digitsAfterPrefix: 7),
    '+49': _CountryRule(name: 'DE', prefix: '+49', localPrefix: '0', minDigits: 3, maxDigits: 15),
    '+33': _CountryRule(name: 'FR', prefix: '+33', localPrefix: '0', digitsAfterPrefix: 9),
    '+39': _CountryRule(name: 'IT', prefix: '+39', localPrefix: '0', minDigits: 6, maxDigits: 12),
  };

  // Alle Ziffern (ohne +) extrahieren
  static String _extractDigits(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Normalisiert eine Nummer ins internationale Format.
  /// Gibt null zurück bei leerem Input.
  static String? normalize(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var cleaned = value.trim().replaceAll(RegExp(r'[\s\-\.\(\)]'), '');

    // Bereits internationales Format
    if (cleaned.startsWith('+')) return cleaned;

    // 00XX → +XX
    if (cleaned.startsWith('00')) {
      return '+${cleaned.substring(2)}';
    }

    // 0XX... → +41 (Schweiz als Default für lokale Nummern)
    if (cleaned.startsWith('0')) {
      return '+41${cleaned.substring(1)}';
    }

    return cleaned;
  }

  /// Validiert eine Telefonnummer aus CH, LI, DE, FR oder IT.
  /// Gibt eine Fehlermeldung zurück oder null wenn gültig.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional

    final normalized = normalize(value);
    if (normalized == null || !normalized.startsWith('+')) {
      return 'Bitte mit Laendervorwahl eingeben (z.B. +41 79 123 45 67)';
    }

    final digits = _extractDigits(normalized);

    // Passende Country-Rule finden (längster Prefix zuerst)
    for (final prefix in ['+423', '+41', '+49', '+39', '+33']) {
      if (normalized.startsWith(prefix)) {
        final rule = _countryRules[prefix]!;
        final prefixDigits = _extractDigits(prefix);
        final numberDigits = digits.substring(prefixDigits.length);

        if (rule.digitsAfterPrefix != null) {
          if (numberDigits.length != rule.digitsAfterPrefix) {
            return 'Ungueltige ${rule.name}-Nummer '
                '(${rule.digitsAfterPrefix} Ziffern nach $prefix erwartet)';
          }
          // CH: erste Ziffer nach +41 muss 2-9 sein
          if (prefix == '+41' && numberDigits.isNotEmpty) {
            final first = numberDigits[0];
            if (first == '0' || first == '1') {
              return 'Ungueltige CH-Nummer (erste Ziffer nach +41 muss 2-9 sein)';
            }
          }
        } else {
          if (numberDigits.length < rule.minDigits! ||
              numberDigits.length > rule.maxDigits!) {
            return 'Ungueltige ${rule.name}-Nummer '
                '(${rule.minDigits}-${rule.maxDigits} Ziffern nach $prefix erwartet)';
          }
        }
        return null; // Gültig
      }
    }

    // Unbekannter Prefix — einfach Mindestlänge prüfen
    if (digits.length < 7 || digits.length > 18) {
      return 'Ungueltige Telefonnummer';
    }
    return null;
  }

  /// Formatiert eine Nummer ins internationale Format mit Leerzeichen.
  static String? format(String? value) {
    if (value == null || value.trim().isEmpty) return value;
    final normalized = normalize(value);
    if (normalized == null) return value;

    // CH: +41 XX XXX XX XX
    if (normalized.startsWith('+41') && _extractDigits(normalized).length == 11) {
      final d = _extractDigits(normalized);
      return '+41 ${d.substring(2, 4)} ${d.substring(4, 7)} ${d.substring(7, 9)} ${d.substring(9, 11)}';
    }

    // LI: +423 XXX XX XX
    if (normalized.startsWith('+423') && _extractDigits(normalized).length == 10) {
      final d = _extractDigits(normalized);
      return '+423 ${d.substring(3, 6)} ${d.substring(6, 8)} ${d.substring(8, 10)}';
    }

    // FR: +33 X XX XX XX XX
    if (normalized.startsWith('+33') && _extractDigits(normalized).length == 11) {
      final d = _extractDigits(normalized);
      return '+33 ${d.substring(2, 3)} ${d.substring(3, 5)} ${d.substring(5, 7)} ${d.substring(7, 9)} ${d.substring(9, 11)}';
    }

    // DE / IT: +XX XXXXXXXXX (keine feste Blockgrösse)
    return normalized;
  }
}

class _CountryRule {
  final String name;
  final String prefix;
  final String localPrefix;
  final int? digitsAfterPrefix;
  final int? minDigits;
  final int? maxDigits;

  const _CountryRule({
    required this.name,
    required this.prefix,
    required this.localPrefix,
    this.digitsAfterPrefix,
    this.minDigits,
    this.maxDigits,
  });
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
