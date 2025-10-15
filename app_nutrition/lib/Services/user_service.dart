import 'dart:math';

import '../Entites/utilisateur.dart';
import 'database_helper.dart';
import 'email_service.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';

class UserService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Optional EmailService; configure in main or wherever you construct UserService.
  EmailService? emailService;

  /// Global default email service that can be set once (e.g. in main)
  static EmailService? defaultEmailService;

  /// Default constructor: copy the global default email service if set
  UserService() {
    emailService = UserService.defaultEmailService;
  }

  /// Crée un nouvel utilisateur et envoie un code de vérification.
  Future<int> creerUtilisateur(Utilisateur utilisateur) async {
    // Hash password before storing
    utilisateur.motDePasse = _hashPassword(utilisateur.motDePasse);

    // Vérifier si l'email existe déjà
    final utilisateurExistant = await _databaseHelper.getUtilisateurByEmail(
      utilisateur.email,
    );
    if (utilisateurExistant != null) {
      throw Exception('Un utilisateur avec cet email existe déjà');
    }

    // Generate verification code and expiry
    final code = _generateCode();
    utilisateur.verificationCode = code;
    utilisateur.verificationExpiry = DateTime.now().add(Duration(minutes: 30));
    utilisateur.isVerified = false;

    // Insérer le nouvel utilisateur
    final id = await _databaseHelper.insertUtilisateur(utilisateur);

    // Try to send verification email (if configured)
    if (emailService != null) {
      final sent = await emailService!.sendVerificationEmail(
        utilisateur.email,
        code,
      );
      print('Email send status: $sent');
      if (!sent) {
        // Fallback for development: print the code so the user can complete verification
        print('Warning: verification email failed to send. Code: $code');
      }
    } else {
      print('EmailService not configured: verification code: $code');
    }

    print('Utilisateur créé avec l\'ID: $id');
    return id;
  }

  String _generateCode({int length = 6}) {
    final rand = Random.secure();
    const chars = '0123456789';
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  String _hashPassword(String pw) {
    final bytes = utf8.encode(pw);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Resend a verification code to the user; returns the new code (or null if user not found)
  Future<String?> resendCode(String email) async {
    final utilisateur = await _databaseHelper.getUtilisateurByEmail(email);
    if (utilisateur == null) return null;
    final code = _generateCode();
    utilisateur.verificationCode = code;
    utilisateur.verificationExpiry = DateTime.now().add(Duration(minutes: 30));
    await _databaseHelper.updateUtilisateur(utilisateur);
    if (emailService != null) {
      await emailService!.sendVerificationEmail(email, code);
    } else {
      print('Resend code (no email service): $code');
    }
    return code;
  }

  /// Vérifie le code de l'utilisateur; retourne true si vérifié avec succès
  Future<bool> verifierCode(String email, String code) async {
    final utilisateur = await _databaseHelper.getUtilisateurByEmail(email);
    if (utilisateur == null) return false;
    if (utilisateur.isVerified) return true;
    if (utilisateur.verificationCode == code &&
        utilisateur.verificationExpiry != null &&
        utilisateur.verificationExpiry!.isAfter(DateTime.now())) {
      utilisateur.isVerified = true;
      utilisateur.verificationCode = null;
      utilisateur.verificationExpiry = null;
      await _databaseHelper.updateUtilisateur(utilisateur);
      return true;
    }
    return false;
  }

  /// Authentifie un utilisateur
  Future<Utilisateur?> authentifier(String email, String motDePasse) async {
    try {
      final utilisateur = await _databaseHelper.getUtilisateurByEmail(email);

      if (utilisateur != null) {
        // Stored password may be hashed (sha256) or plain (legacy/test data).
        // Hash the input and compare, but accept plain-text match if present.
        final hashedInput = _hashPassword(motDePasse);
        final passwordMatches =
            utilisateur.motDePasse == hashedInput ||
            utilisateur.motDePasse == motDePasse;
        if (passwordMatches) {
          print('Authentification réussie pour: ${utilisateur.email}');
          return utilisateur;
        }
      }
      print('Échec de l\'authentification pour: $email');
      return null;
    } catch (e) {
      print('Erreur lors de l\'authentification: $e');
      return null;
    }
  }

  /// Récupère un utilisateur par ID
  Future<Utilisateur?> obtenirUtilisateur(int id) async {
    try {
      return await _databaseHelper.getUtilisateurById(id);
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Récupère tous les utilisateurs
  Future<List<Utilisateur>> obtenirTousLesUtilisateurs() async {
    try {
      return await _databaseHelper.getAllUtilisateurs();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  /// Met à jour un utilisateur
  Future<bool> modifierUtilisateur(Utilisateur utilisateur) async {
    try {
      final result = await _databaseHelper.updateUtilisateur(utilisateur);
      if (result > 0) {
        utilisateur.modifierProfil(); // Appel de la méthode métier
        print('Utilisateur modifié avec succès');
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la modification de l\'utilisateur: $e');
      return false;
    }
  }

  /// Supprime un utilisateur
  Future<bool> supprimerUtilisateur(int id) async {
    try {
      final utilisateur = await _databaseHelper.getUtilisateurById(id);
      if (utilisateur != null) {
        final result = await _databaseHelper.deleteUtilisateur(id);
        if (result > 0) {
          utilisateur.supprimerProfil(); // Appel de la méthode métier
          print('Utilisateur supprimé avec succès');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur: $e');
      return false;
    }
  }

  /// Change le mot de passe d'un utilisateur
  Future<bool> changerMotDePasse(
    int id,
    String ancienMotDePasse,
    String nouveauMotDePasse,
  ) async {
    try {
      final utilisateur = await _databaseHelper.getUtilisateurById(id);
      if (utilisateur != null) {
        final hashedOld = _hashPassword(ancienMotDePasse);
        final oldMatches =
            utilisateur.motDePasse == hashedOld ||
            utilisateur.motDePasse == ancienMotDePasse;
        if (oldMatches) {
          // Store the new password hashed
          utilisateur.motDePasse = _hashPassword(nouveauMotDePasse);
          final result = await _databaseHelper.updateUtilisateur(utilisateur);
          return result > 0;
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors du changement de mot de passe: $e');
      return false;
    }
  }

  /// Valide le format de l'email
  bool validerEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Valide la force du mot de passe
  bool validerMotDePasse(String motDePasse) {
    // Au moins 8 caractères, une majuscule, une minuscule, un chiffre
    final motDePasseRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
    );
    return motDePasseRegex.hasMatch(motDePasse);
  }
}
