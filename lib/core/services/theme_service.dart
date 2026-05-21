import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme_type.dart';

/// Service for persisting theme preferences.
class ThemeService {
  static const String _themeKey = 'app_theme';

  /// Get the saved theme preference.
  Future<AppThemeMode> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue =
        prefs.getString(_themeKey) ?? AppThemeMode.system.toValue();
    return AppThemeMode.fromValue(themeValue);
  }

  /// Save the theme preference.
  Future<void> setTheme(AppThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.toValue());
  }
}
