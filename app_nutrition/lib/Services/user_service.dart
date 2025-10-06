import '../Entites/utilisateur.dart';
import 'database_helper.dart';

class UserService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Crée un nouvel utilisateur
  Future<int> creerUtilisateur(Utilisateur utilisateur) async {
    try {
      // Vérifier si l'email existe déjà
      final utilisateurExistant = await _databaseHelper.getUtilisateurByEmail(utilisateur.email);
      if (utilisateurExistant != null) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Insérer le nouvel utilisateur
      final id = await _databaseHelper.insertUtilisateur(utilisateur);
      print('Utilisateur créé avec l\'ID: $id');
      return id;
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
  }

  /// Authentifie un utilisateur
  Future<Utilisateur?> authentifier(String email, String motDePasse) async {
    try {
      final utilisateur = await _databaseHelper.getUtilisateurByEmail(email);
      
      if (utilisateur != null && utilisateur.seConnecter(email, motDePasse)) {
        print('Authentification réussie pour: ${utilisateur.email}');
        return utilisateur;
      } else {
        print('Échec de l\'authentification pour: $email');
        return null;
      }
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
  Future<bool> changerMotDePasse(int id, String ancienMotDePasse, String nouveauMotDePasse) async {
    try {
      final utilisateur = await _databaseHelper.getUtilisateurById(id);
      if (utilisateur != null && utilisateur.motDePasse == ancienMotDePasse) {
        utilisateur.motDePasse = nouveauMotDePasse;
        final result = await _databaseHelper.updateUtilisateur(utilisateur);
        return result > 0;
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
    final motDePasseRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$');
    return motDePasseRegex.hasMatch(motDePasse);
  }
}