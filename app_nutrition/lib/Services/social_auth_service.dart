import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialAuthService {
  // Sign in with Google. Returns a map with user info or null if canceled.
  // Set forceAccountPicker=true to always show the account chooser.
  Future<Map<String, dynamic>?> signInWithGoogle({
    String? serverClientId,
    bool forceAccountPicker = true,
  }) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: serverClientId,
      );
      if (forceAccountPicker) {
        // Ensure the chooser appears by clearing any previous cached account
        try {
          await googleSignIn.signOut();
        } catch (_) {}
      }
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) return null; // user canceled

      final auth = await account.authentication;
      return {
        'id': account.id,
        'email': account.email,
        'name': account.displayName,
        'photo': account.photoUrl,
        'accessToken': auth.accessToken,
        'idToken': auth.idToken,
      };
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Google sign-in error: $e\n$st');
      }
      return null;
    }
  }

  /// Signs out from Google if previously signed-in. Safe to call even if not signed-in.
  Future<void> signOutGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }
}
