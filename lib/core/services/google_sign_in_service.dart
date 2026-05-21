import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';

/// Initializes [GoogleSignIn] once before any sign-in calls (required in v7+).
class GoogleSignInService {
  GoogleSignInService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await GoogleSignIn.instance.initialize(
      clientId: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? GoogleAuthConfig.iosClientId
          : null,
      serverClientId: GoogleAuthConfig.webClientId,
    );

    _initialized = true;
  }
}
