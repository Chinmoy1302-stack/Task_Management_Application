import 'package:get/get.dart';
import '../services/theme_service.dart';
import 'app_theme_type.dart';

/// Controller for managing app theme state.
class ThemeController extends GetxController {
  final ThemeService _themeService = ThemeService();

  final _currentTheme = AppThemeMode.system.obs;
  final bool _hasInitialTheme;

  /// Constructor with optional initial theme.
  ThemeController({AppThemeMode? initialTheme})
    : _hasInitialTheme = initialTheme != null {
    if (initialTheme != null) {
      _currentTheme.value = initialTheme;
    }
  }

  /// Get the current theme.
  AppThemeMode get currentTheme => _currentTheme.value;

  @override
  void onInit() {
    super.onInit();
    // Only load if theme wasn't set via constructor
    if (!_hasInitialTheme) {
      _loadTheme();
    }
  }

  /// Load theme from persistent storage.
  Future<void> _loadTheme() async {
    final theme = await _themeService.getTheme();
    _currentTheme.value = theme;
  }

  /// Change the app theme and persist the selection.
  Future<void> changeTheme(AppThemeMode theme) async {
    _currentTheme.value = theme;
    await _themeService.setTheme(theme);
    update(); // Trigger GetBuilder rebuild
  }
}
