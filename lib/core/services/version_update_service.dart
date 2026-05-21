import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';

/// Service to handle app version updates and in-app update flows
class VersionUpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check_timestamp';
  static const String _updateDismissedKey = 'update_dismissed_version';
  static const Duration _updateCheckInterval = Duration(hours: 24);

  static const String _androidPackageName = 'assignment.app';
  static String get _iosBundleId =>
      DefaultFirebaseOptions.ios.iosBundleId ?? 'assignment.app';

  /// Check for app updates and show dialog if available
  ///
  /// [context] - BuildContext for showing dialogs
  /// [forceCheck] - If true, bypasses the 24-hour check interval
  /// Returns true if update dialog was shown, false otherwise
  Future<bool> checkForUpdates(
    BuildContext context, {
    bool forceCheck = false,
  }) async {
    try {
      // Check if we should skip update check (not forced and checked recently)
      if (!forceCheck) {
        final shouldSkip = await _shouldSkipUpdateCheck();
        if (shouldSkip) {
          return false;
        }
      }

      final result = await PlayxVersionUpdate.checkVersion(
        options: PlayxUpdateOptions(
          androidPackageName: _androidPackageName,
          iosBundleId: _iosBundleId,
        ),
      );

      return result.when(
        success: (info) async {
          if (info.canUpdate) {
            // Save the check timestamp
            await _saveUpdateCheckTimestamp();

            // Show update dialog
            await _showUpdateDialog(context, info);
            return true;
          }
          return false;
        },
        error: (error) {
          debugPrint('Version update check error: ${error.message}');
          return false;
        },
      );
    } catch (e) {
      debugPrint('Version update service error: $e');
      return false;
    }
  }

  /// Show in-app update dialog (Android) or update page (iOS)
  ///
  /// For Android: Uses native in-app update flow
  /// For iOS: Shows customizable Flutter dialog
  Future<void> showInAppUpdateDialog(
    BuildContext context, {
    PlayxAppUpdateType androidUpdateType = PlayxAppUpdateType.flexible,
  }) async {
    try {
      final result = await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: androidUpdateType,
        iosOptions: PlayxUpdateOptions(iosBundleId: _iosBundleId),
        iosUiOptions: PlayxUpdateUIOptions(
          showReleaseNotes: true,
          releaseNotesTitle: (info) => 'What\'s New in ${info.newVersion}?',
          displayType: PlayxUpdateDisplayType.dialog,
          isDismissible: true, // Can be dismissed for non-forced updates
        ),
      );

      result.when(
        success: (isShown) {
          if (isShown) {
            debugPrint('In-app update dialog shown');
          }
        },
        error: (error) {
          debugPrint('In-app update dialog error: ${error.message}');
        },
      );
    } catch (e) {
      debugPrint('In-app update service error: $e');
    }
  }

  /// Show simple update dialog (cross-platform Flutter UI)
  Future<void> showUpdateDialog(BuildContext context) async {
    try {
      final result = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        options: PlayxUpdateOptions(
          androidPackageName: _androidPackageName,
          iosBundleId: _iosBundleId,
        ),
        uiOptions: PlayxUpdateUIOptions(
          title: (info) => 'Update Available',
          description: (info) =>
              'A new version (${info.newVersion}) is available. '
              'Please update to get the latest features and improvements.',
          showReleaseNotes: false,
          updateButtonText: 'Update Now',
          dismissButtonText: 'Later',
        ),
      );

      result.when(
        success: (isShown) {
          if (isShown) {
            debugPrint('Update dialog shown');
          }
        },
        error: (error) {
          debugPrint('Update dialog error: ${error.message}');
        },
      );
    } catch (e) {
      debugPrint('Update dialog service error: $e');
    }
  }

  /// Check if update check should be skipped (based on last check time)
  Future<bool> _shouldSkipUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckTimestamp = prefs.getInt(_lastUpdateCheckKey);

    if (lastCheckTimestamp == null) {
      return false;
    }

    final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTimestamp);
    final now = DateTime.now();
    final difference = now.difference(lastCheck);

    return difference < _updateCheckInterval;
  }

  /// Save the timestamp of the last update check
  Future<void> _saveUpdateCheckTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastUpdateCheckKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Show update dialog based on update info
  Future<void> _showUpdateDialog(
    BuildContext context,
    PlayxVersionUpdateInfo info,
  ) async {
    if (info.forceUpdate) {
      // For forced updates, show non-dismissible dialog
      await showUpdateDialog(context);
    } else {
      // For optional updates, show dismissible dialog
      await showUpdateDialog(context);
    }
  }
}
