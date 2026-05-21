import 'package:shared_preferences/shared_preferences.dart';
import '../language/app_language_type.dart';

/// Service for managing language persistence.
class LanguageService {
  static const String _languageKey = 'app_language';

  /// Get the saved language preference.
  /// Returns [AppLanguageType.english] if no preference exists.
  Future<AppLanguageType> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageValue = prefs.getString(_languageKey);
    
    if (languageValue == null) {
      return AppLanguageType.english;
    }
    
    return AppLanguageType.fromValue(languageValue);
  }

  /// Save the language preference.
  Future<void> setLanguage(AppLanguageType language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.toValue());
  }
}
