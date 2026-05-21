/// Language type enumeration for the application.
enum AppLanguageType {
  english,
  arabic;

  /// Convert language type to string for persistence.
  String toValue() {
    switch (this) {
      case AppLanguageType.english:
        return 'english';
      case AppLanguageType.arabic:
        return 'arabic';
    }
  }

  /// Create language type from string value.
  static AppLanguageType fromValue(String value) {
    switch (value) {
      case 'arabic':
        return AppLanguageType.arabic;
      case 'english':
      default:
        return AppLanguageType.english;
    }
  }

  /// Get display name for the language.
  String get displayName {
    switch (this) {
      case AppLanguageType.english:
        return 'English';
      case AppLanguageType.arabic:
        return 'العربية';
    }
  }

  /// Get locale code (e.g., 'en', 'ar').
  String get localeCode {
    switch (this) {
      case AppLanguageType.english:
        return 'en';
      case AppLanguageType.arabic:
        return 'ar';
    }
  }

  /// Check if language is RTL (Right-to-Left).
  bool get isRTL {
    switch (this) {
      case AppLanguageType.english:
        return false;
      case AppLanguageType.arabic:
        return true;
    }
  }
}
