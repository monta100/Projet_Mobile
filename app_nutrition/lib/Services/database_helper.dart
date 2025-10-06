// Database helper using in-memory storage (no sqflite dependency)
import '../Entites/utilisateur.dart';
import '../Entites/objectif.dart';
import '../Entites/rappel.dart';

class DatabaseHelper {
  // --- Singleton ---
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // --- Noms des tables ---
  static const String tableUtilisateurs = 'utilisateurs';
  static const String tableObjectifs = 'objectifs';
  static const String tableRappels = 'rappels';

  // --- Mock data storage ---
  static List<Utilisateur> _utilisateurs = [];
  static List<Objectif> _objectifs = [];
  static List<Rappel> _rappels = [];
  static int _nextUserId = 1;
  static int _nextObjectifId = 1;
  static int _nextRappelId = 1;

  // --- Méthodes génériques ---

  /// Insère une nouvelle ligne dans la table spécifiée.
  /// Retourne l'ID de la nouvelle ligne.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    // Simulation d'insertion avec des données en mémoire
    await Future.delayed(
      Duration(milliseconds: 10),
    ); // Simulate async operation

    switch (table) {
      case tableUtilisateurs:
        final utilisateur = Utilisateur.fromMap({...data, 'id': _nextUserId});
        _utilisateurs.add(utilisateur);
        return _nextUserId++;
      case tableObjectifs:
        final objectif = Objectif.fromMap({...data, 'id': _nextObjectifId});
        _objectifs.add(objectif);
        return _nextObjectifId++;
      case tableRappels:
        final rappel = Rappel.fromMap({...data, 'id': _nextRappelId});
        _rappels.add(rappel);
        return _nextRappelId++;
      default:
        throw Exception('Table inconnue: $table');
    }
  }

  /// Récupère toutes les lignes d'une table.
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    await Future.delayed(Duration(milliseconds: 10));

    switch (table) {
      case tableUtilisateurs:
        return _utilisateurs.map((u) => u.toMap()).toList();
      case tableObjectifs:
        return _objectifs.map((o) => o.toMap()).toList();
      case tableRappels:
        return _rappels.map((r) => r.toMap()).toList();
      default:
        return [];
    }
  }

  /// Met à jour une ligne dans une table en fonction de son ID.
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    await Future.delayed(Duration(milliseconds: 10));

    switch (table) {
      case tableUtilisateurs:
        final index = _utilisateurs.indexWhere((u) => u.id == id);
        if (index != -1) {
          _utilisateurs[index] = Utilisateur.fromMap({...data, 'id': id});
          return 1;
        }
        break;
      case tableObjectifs:
        final index = _objectifs.indexWhere((o) => o.id == id);
        if (index != -1) {
          _objectifs[index] = Objectif.fromMap({...data, 'id': id});
          return 1;
        }
        break;
      case tableRappels:
        final index = _rappels.indexWhere((r) => r.id == id);
        if (index != -1) {
          _rappels[index] = Rappel.fromMap({...data, 'id': id});
          return 1;
        }
        break;
    }
    return 0;
  }

  /// Supprime une ligne d'une table en fonction de son ID.
  Future<int> delete(String table, int id) async {
    await Future.delayed(Duration(milliseconds: 10));

    switch (table) {
      case tableUtilisateurs:
        final initialLength = _utilisateurs.length;
        _utilisateurs.removeWhere((u) => u.id == id);
        return initialLength > _utilisateurs.length ? 1 : 0;
      case tableObjectifs:
        final initialLength = _objectifs.length;
        _objectifs.removeWhere((o) => o.id == id);
        return initialLength > _objectifs.length ? 1 : 0;
      case tableRappels:
        final initialLength = _rappels.length;
        _rappels.removeWhere((r) => r.id == id);
        return initialLength > _rappels.length ? 1 : 0;
      default:
        return 0;
    }
  }

  // --- Méthodes spécifiques pour Utilisateur ---

  Future<int> insertUtilisateur(Utilisateur utilisateur) async {
    return await insert(tableUtilisateurs, utilisateur.toMap());
  }

  Future<List<Utilisateur>> getAllUtilisateurs() async {
    return List.from(_utilisateurs);
  }

  Future<Utilisateur?> getUtilisateurById(int id) async {
    try {
      return _utilisateurs.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Utilisateur?> getUtilisateurByEmail(String email) async {
    try {
      return _utilisateurs.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateUtilisateur(Utilisateur utilisateur) async {
    return await update(
      tableUtilisateurs,
      utilisateur.toMap(),
      utilisateur.id!,
    );
  }

  Future<int> deleteUtilisateur(int id) async {
    return await delete(tableUtilisateurs, id);
  }

  // --- Méthodes spécifiques pour Objectif ---

  Future<int> insertObjectif(Objectif objectif) async {
    return await insert(tableObjectifs, objectif.toMap());
  }

  Future<List<Objectif>> getAllObjectifs() async {
    return List.from(_objectifs);
  }

  Future<Objectif?> getObjectifById(int id) async {
    try {
      return _objectifs.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Objectif>> getObjectifsByType(String type) async {
    return _objectifs.where((o) => o.type == type).toList();
  }

  Future<List<Objectif>> getObjectifsByUtilisateur(int utilisateurId) async {
    return _objectifs.where((o) => o.utilisateurId == utilisateurId).toList();
  }

  Future<int> updateObjectif(Objectif objectif) async {
    return await update(tableObjectifs, objectif.toMap(), objectif.id!);
  }

  Future<int> deleteObjectif(int id) async {
    return await delete(tableObjectifs, id);
  }

  // --- Méthodes spécifiques pour Rappel ---

  Future<int> insertRappel(Rappel rappel) async {
    return await insert(tableRappels, rappel.toMap());
  }

  Future<List<Rappel>> getAllRappels() async {
    return List.from(_rappels);
  }

  Future<Rappel?> getRappelById(int id) async {
    try {
      return _rappels.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Rappel>> getRappelsNonLus() async {
    return _rappels.where((r) => !r.statut).toList();
  }

  Future<List<Rappel>> getRappelsDus() async {
    final maintenant = DateTime.now();
    return _rappels
        .where((r) => r.date.isBefore(maintenant) && !r.statut)
        .toList();
  }

  Future<List<Rappel>> getRappelsByUtilisateur(int utilisateurId) async {
    return _rappels.where((r) => r.utilisateurId == utilisateurId).toList();
  }

  Future<List<Rappel>> getRappelsNonLusByUtilisateur(int utilisateurId) async {
    return _rappels
        .where((r) => r.utilisateurId == utilisateurId && !r.statut)
        .toList();
  }

  Future<int> updateRappel(Rappel rappel) async {
    return await update(tableRappels, rappel.toMap(), rappel.id!);
  }

  Future<int> deleteRappel(int id) async {
    return await delete(tableRappels, id);
  }

  // --- Méthodes utilitaires ---

  /// Initialise quelques données de test
  Future<void> initTestData() async {
    if (_utilisateurs.isEmpty) {
      // Créer un utilisateur de test
      final testUser = Utilisateur(
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean.dupont@test.com',
        motDePasse: 'Test123!',
        role: 'Utilisateur',
      );
      await insertUtilisateur(testUser);

      // Créer un objectif de test
      final testObjectif = Objectif(
        utilisateurId: 1,
        type: 'Perte de poids',
        valeurCible: 5.0,
        dateFixee: DateTime.now().add(Duration(days: 30)),
        progression: 1.5,
      );
      await insertObjectif(testObjectif);

      // Créer un rappel de test
      final testRappel = Rappel(
        utilisateurId: 1,
        message: 'Boire un verre d\'eau',
        date: DateTime.now().add(Duration(hours: 1)),
      );
      await insertRappel(testRappel);
    }
  }

  /// Efface toutes les données
  void clearAllData() {
    _utilisateurs.clear();
    _objectifs.clear();
    _rappels.clear();
    _nextUserId = 1;
    _nextObjectifId = 1;
    _nextRappelId = 1;
  }
}
