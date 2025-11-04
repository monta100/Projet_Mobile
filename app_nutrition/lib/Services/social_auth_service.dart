import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialAuthService {
  // 🔐 Ton Client ID OAuth 2.0 (Google Cloud Console)
  static const String _googleClientId =
      '656462210891-v9bhissbnm1r43d3ki74jgti7rt2651c.apps.googleusercontent.com';

  /// 🔹 Connexion avec Google (retourne un Map avecexit les infos de l'utilisateur)
  Future<Map<String, dynamic>?> signInWithGoogle({
    bool forceAccountPicker = true,
  }) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _googleClientId, // ✅ Ton client ID ici
      );

      if (forceAccountPicker) {
        // Force à afficher le choix de compte Google
        try {
          await googleSignIn.signOut();
        } catch (_) {}
      }

      // Ouvre la fenêtre de connexion Google
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) return null; // utilisateur a annulé

      // Récupère les tokens OAuth
      final auth = await account.authentication;

      // Retourne les infos utiles
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
        print('❌ Google sign-in error: $e\n$st');
      }
      return null;
    }
  }

  /// 🔹 Déconnexion sécurisée de Google
  Future<void> signOutGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }
}
