import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Google Sign-In instance.
  ///
  /// Note: The 'scopes' are optional but recommended.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // --- Social Auth (Real) ---

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // if (googleUser == null) {
      //   // The user canceled the sign-in
      //   return null;
      // }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        // accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String _sha256of(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256of(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create an `OAuthCredential` from the credential returned by Apple.
      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Apple Sign-In failed: $e');
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  // --- Mock Auth (Simulated) ---

  Future<void> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'error@test.com') {
      throw Exception('Invalid credentials');
    }
    // Success implies no exception thrown
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'exists@test.com') {
      throw Exception('Email already exists');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  User? get currentUser => _firebaseAuth.currentUser;
}
