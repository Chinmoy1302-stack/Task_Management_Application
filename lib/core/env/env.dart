// ignore_for_file: constant_identifier_names

import 'package:envied/envied.dart';

part 'env.g.dart';

/// Environment configuration class
///
/// This class uses ENVied to securely load environment variables
/// from the .env file at build time.
///
/// **IMPORTANT**:
/// - Add `.env` and `env.g.dart` to `.gitignore`
/// - Run `dart run build_runner build --delete-conflicting-outputs`
///   after modifying .env file
///
/// **Usage**:
/// ```dart
/// import 'package:flutter_base_project/core/env/env.dart';
///
/// final baseUrl = Env.baseUrl;
/// ```
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  // =====================================================================
  // NETWORK CONFIGURATION
  // =====================================================================

  /// Base URL for API endpoints
  /// Environment variable: BASE_URL
  @EnviedField(varName: 'BASE_URL')
  static final String baseUrl = _Env.baseUrl;

  /// AccuWeather API Key
  /// Environment variable: ACCUWEATHER_API_KEY
  @EnviedField(varName: 'ACCUWEATHER_API_KEY')
  static final String accuWeatherApiKey = _Env.accuWeatherApiKey;

  /// Unsplash Access Key
  /// Environment variable: UNSPLASH_ACCESS_KEY
  @EnviedField(varName: 'UNSPLASH_ACCESS_KEY')
  static final String unsplashAccessKey = _Env.unsplashAccessKey;

  /// Pexels API Key
  /// Environment variable: PEXELS_API_KEY
  @EnviedField(varName: 'PEXELS_API_KEY')
  static final String pexelsApiKey = _Env.pexelsApiKey;

  // =====================================================================
  // ADD MORE ENVIRONMENT VARIABLES BELOW
  // =====================================================================
  //
  // For required fields:
  //   @EnviedField(varName: 'VARIABLE_NAME')
  //   static final String variableName = _Env.variableName;
  //
  // For optional fields (with default value):
  //   @EnviedField(varName: 'VARIABLE_NAME', defaultValue: 'default')
  //   static final String variableName = _Env.variableName;
  //
  // For optional nullable fields:
  //   @EnviedField(varName: 'VARIABLE_NAME', optional: true)
  //   static final String? variableName = _Env.variableName;
  //
  // For non-obfuscated fields (use static const):
  //   @EnviedField(varName: 'PUBLIC_VAR', obfuscate: false)
  //   static const String publicVar = _Env.publicVar;
  // =====================================================================
}
