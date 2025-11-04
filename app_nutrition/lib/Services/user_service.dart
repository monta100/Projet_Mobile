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

    // Generate verification code and expiry (10 minutes)
    final code = _generateCode();
    utilisateur.verificationCode = code;
    utilisateur.verificationExpiry = DateTime.now().add(Duration(minutes: 10));
    utilisateur.isVerified = false;

    // Insérer le nouvel utilisateur
    final id = await _databaseHelper.insertUtilisateur(utilisateur);

    // Try to send verification email (if configured) using the rich template
    if (emailService != null) {
      final displayName = '${utilisateur.prenom} ${utilisateur.nom}'.trim();
      final sent = await emailService!.sendVerificationEmailRich(
        toEmail: utilisateur.email,
        code: code,
        userName: displayName.isEmpty ? utilisateur.email : displayName,
        action: 'activer',
        appName: 'App Nutrition',
        validityMinutes: 10,
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

  /// Créé (si besoin) ou récupère un utilisateur à partir d'un compte social (Google/Facebook)
  /// - Si l'utilisateur (par email) existe déjà, il est retourné tel quel.
  /// - Sinon, on crée un nouvel utilisateur "vérifié" sans étape d'email, avec un mot de passe généré.
  Future<Utilisateur> upsertSocialUser({
    required String email,
    String? displayName,
    String? photoUrl,
    String provider = 'google',
  }) async {
    // 1) Existe déjà ?
    final existing = await _databaseHelper.getUtilisateurByEmail(email);
    if (existing != null) {
      return existing;
    }

    // 2) Construire nom/prénom à partir de displayName si possible
    String nom = '';
    String prenom = '';
    if (displayName != null && displayName.trim().isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r"\s+"));
      if (parts.length == 1) {
        nom = parts.first;
        prenom = '';
      } else {
        prenom = parts.sublist(0, parts.length - 1).join(' ');
        nom = parts.last;
      }
    } else {
      // Fallback: dériver quelque chose depuis l'email
      final local = email.split('@').first;
      nom = local;
      prenom = '';
    }

    // 3) Générer un mot de passe interne (jamais utilisé par l'utilisateur)
    final internalPassword = _generateCode(length: 12) + provider;

    // 4) Initiales pour avatar si possible
    String? initials;
    final all = (prenom + ' ' + nom).trim();
    if (all.isNotEmpty) {
      final words = all.split(RegExp(r"\s+"));
      initials = words
          .take(2)
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
          .join();
      if (initials.isEmpty) initials = null;
    }

    // 5) Créer l'utilisateur vérifié directement
    final newUser = Utilisateur(
      nom: nom,
      prenom: prenom,
      email: email,
      motDePasse:
          internalPassword, // sera hashé si on passait par creerUtilisateur, ici on hash nous-même
      role: 'User',
      isVerified: true,
      avatarPath: photoUrl,
      avatarInitials: initials,
    );

    // On stocke hashé car on insère via DatabaseHelper directement
    newUser.motDePasse = _hashPassword(newUser.motDePasse);
    final id = await _databaseHelper.insertUtilisateur(newUser);
    newUser.id = id;
    return newUser;
  }

  /// Resend a verification code to the user; returns the new code (or null if user not found)
  Future<String?> resendCode(String email) async {
    final utilisateur = await _databaseHelper.getUtilisateurByEmail(email);
    if (utilisateur == null) return null;
    final code = _generateCode();
    utilisateur.verificationCode = code;
    utilisateur.verificationExpiry = DateTime.now().add(Duration(minutes: 10));
    await _databaseHelper.updateUtilisateur(utilisateur);
    if (emailService != null) {
      final displayName = '${utilisateur.prenom} ${utilisateur.nom}'.trim();
      await emailService!.sendVerificationEmailRich(
        toEmail: email,
        code: code,
        userName: displayName.isEmpty ? email : displayName,
        action: 'activer',
        appName: 'App Nutrition',
        validityMinutes: 10,
      );
    } else {
      print('Resend code (no email service): $code');
    }
    return code;
  }

  /// Demande une réinitialisation de mot de passe.
  /// Génère un code (réutilise le champ verificationCode) et une expiration,
  /// l'envoie par email si possible. Retourne true si l'utilisateur existe.
  Future<bool> requestPasswordReset(String email) async {
    final utilisateur = await _databaseHelper.getUtilisateurByEmail(email);
    if (utilisateur == null) return false;

    final code = _generateCode();
    utilisateur.verificationCode = code;
    utilisateur.verificationExpiry = DateTime.now().add(Duration(minutes: 10));
    await _databaseHelper.updateUtilisateur(utilisateur);

    if (emailService != null) {
      final displayName = '${utilisateur.prenom} ${utilisateur.nom}'.trim();
      final sent = await emailService!.sendVerificationEmailRich(
        toEmail: email,
        code: code,
        userName: displayName.isEmpty ? email : displayName,
        action: 'réinitialiser',
        appName: 'App Nutrition',
        validityMinutes: 10,
      );
      // Dev aid: also echo the code to console to unblock if mail filters delay delivery
      // Remove or guard this log for production if needed.
      print('Password reset code (debug echo): $code (sent=$sent)');
    } else {
      print('Password reset code (dev): $code');
    }
    return true;
  }

  /// Réinitialise le mot de passe si le code est valide et non expiré
  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final utilisateur = await _databaseHelper.getUtilisateurByEmail(email);
    if (utilisateur == null) return false;

    final isCodeValid =
        utilisateur.verificationCode == code &&
        utilisateur.verificationExpiry != null &&
        utilisateur.verificationExpiry!.isAfter(DateTime.now());
    if (!isCodeValid) return false;

    utilisateur.motDePasse = _hashPassword(newPassword);
    utilisateur.verificationCode = null;
    utilisateur.verificationExpiry = null;
    await _databaseHelper.updateUtilisateur(utilisateur);
    return true;
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

  /// Récupère un utilisateur par email, ou null s'il n'existe pas
  Future<Utilisateur?> obtenirUtilisateurParEmail(String email) async {
    return await _databaseHelper.getUtilisateurByEmail(email);
  }

  /// Crée ou récupère un utilisateur à partir d'un compte Google,
  /// marque l'utilisateur comme vérifié et retourne l'entité complète.
  /// - email: requis (fourni par Google)
  /// - name: optionnel (displayName Google, utilisé pour nom/prénom si disponible)
  Future<Utilisateur> signInOrCreateFromGoogle({
    required String email,
    String? name,
  }) async {
    // 1) Existe déjà ? le retourner (et s'assurer qu'il est vérifié)
    final existing = await _databaseHelper.getUtilisateurByEmail(email);
    if (existing != null) {
      if (!existing.isVerified) {
        existing.isVerified = true;
        existing.verificationCode = null;
        existing.verificationExpiry = null;
        await _databaseHelper.updateUtilisateur(existing);
      }
      return existing;
    }

    // 2) Créer un nouveau compte local à partir des infos Google
    String prenom = '';
    String nom = '';
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r"\s+"));
      if (parts.length == 1) {
        prenom = parts.first;
      } else {
        prenom = parts.first;
        nom = parts.sublist(1).join(' ');
      }
    } else {
      // fallback: utiliser le préfixe de l'email comme prénom
      prenom = email.split('@').first;
    }

    // Générer un mot de passe placeholder (hashé) pour les comptes sociaux
    final placeholderPw = _hashPassword('google:$email');

    final user = Utilisateur(
      nom: nom.isEmpty ? ' ' : nom,
      prenom: prenom,
      email: email,
      motDePasse: placeholderPw,
      role: 'User',
      isVerified: true,
      verificationCode: null,
      verificationExpiry: null,
    );

    final id = await _databaseHelper.insertUtilisateur(user);
    return user..id = id;
  }
}
