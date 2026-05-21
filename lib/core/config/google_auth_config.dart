/// OAuth client IDs from Firebase project `task-63673`.
/// Regenerate via Firebase Console or `firebase apps:sdkconfig` after changing auth setup.
abstract final class GoogleAuthConfig {
  /// Web client (client_type 3) — required as [serverClientId] on Android for google_sign_in 7+.
  static const String webClientId =
      '155162726583-5r5c64rdqintglu2aq7e7jkgutbo2hij.apps.googleusercontent.com';

  /// iOS client from GoogleService-Info.plist [CLIENT_ID].
  static const String iosClientId =
      '155162726583-ep362hokc5qg0ir85rehuosdj85gqs87.apps.googleusercontent.com';

  /// Reversed iOS client ID for URL scheme in Info.plist.
  static const String iosReversedClientId =
      'com.googleusercontent.apps.155162726583-ep362hokc5qg0ir85rehuosdj85gqs87';
}
