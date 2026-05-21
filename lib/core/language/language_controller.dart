import 'package:get/get.dart';
import '../services/language_service.dart';
import 'app_language_type.dart';
import '../../i18n/strings.g.dart';

/// Controller for managing app language state.
class LanguageController extends GetxController {
  final LanguageService _languageService = LanguageService();
  
  final _currentLanguage = AppLanguageType.english.obs;
  final bool _hasInitialLanguage;

  /// Constructor with optional initial language.
  LanguageController({AppLanguageType? initialLanguage})
      : _hasInitialLanguage = initialLanguage != null {
    if (initialLanguage != null) {
      _currentLanguage.value = initialLanguage;
      _updateSlangLocale();
    }
  }

  /// Get the current language.
  AppLanguageType get currentLanguage => _currentLanguage.value;

  /// Get the current locale code.
  String get currentLocaleCode => _currentLanguage.value.localeCode;

  /// Check if current language is RTL.
  bool get isRTL => _currentLanguage.value.isRTL;

  /// Get the current AppLocale from slang.
  AppLocale get currentAppLocale {
    return _currentLanguage.value == AppLanguageType.arabic
        ? AppLocale.ar
        : AppLocale.en;
  }

  @override
  void onInit() {
    super.onInit();
    // Only load if language wasn't set via constructor
    if (!_hasInitialLanguage) {
      _loadLanguage();
    }
  }

  /// Load language from persistent storage.
  Future<void> _loadLanguage() async {
    final language = await _languageService.getLanguage();
    _currentLanguage.value = language;
    _updateSlangLocale();
  }

  /// Change the app language and persist the selection.
  Future<void> changeLanguage(AppLanguageType language) async {
    _currentLanguage.value = language;
    await _languageService.setLanguage(language);
    _updateSlangLocale();
    update(); // Trigger GetBuilder rebuild
  }

  /// Update slang's LocaleSettings.
  void _updateSlangLocale() {
    final appLocale = currentAppLocale;
    LocaleSettings.setLocaleSync(appLocale);
  }
}
