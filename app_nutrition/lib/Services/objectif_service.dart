import '../Entites/objectif.dart';
import 'database_helper.dart';

class ObjectifService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Crée un nouvel objectif
  Future<int> creerObjectif(Objectif objectif) async {
    try {
      objectif.fixerObjectif(
        objectif.type,
        objectif.valeurCible,
        objectif.dateFixee,
      );
      final id = await _databaseHelper.insertObjectif(objectif);
      print('Objectif créé avec l\'ID: $id');
      return id;
    } catch (e) {
      print('Erreur lors de la création de l\'objectif: $e');
      rethrow;
    }
  }

  /// Récupère un objectif par ID
  Future<Objectif?> obtenirObjectif(int id) async {
    try {
      return await _databaseHelper.getObjectifById(id);
    } catch (e) {
      print('Erreur lors de la récupération de l\'objectif: $e');
      return null;
    }
  }

  /// Récupère tous les objectifs
  Future<List<Objectif>> obtenirTousLesObjectifs() async {
    try {
      return await _databaseHelper.getAllObjectifs();
    } catch (e) {
      print('Erreur lors de la récupération des objectifs: $e');
      return [];
    }
  }

  /// Récupère les objectifs par type
  Future<List<Objectif>> obtenirObjectifsParType(String type) async {
    try {
      return await _databaseHelper.getObjectifsByType(type);
    } catch (e) {
      print('Erreur lors de la récupération des objectifs par type: $e');
      return [];
    }
  }

  /// Met à jour un objectif
  Future<bool> modifierObjectif(Objectif objectif) async {
    try {
      final result = await _databaseHelper.updateObjectif(objectif);
      if (result > 0) {
        print('Objectif modifié avec succès');
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la modification de l\'objectif: $e');
      return false;
    }
  }

  /// Supprime un objectif
  Future<bool> supprimerObjectif(int id) async {
    try {
      final result = await _databaseHelper.deleteObjectif(id);
      if (result > 0) {
        print('Objectif supprimé avec succès');
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression de l\'objectif: $e');
      return false;
    }
  }

  /// Met à jour la progression d'un objectif
  Future<bool> mettreAJourProgression(
    int id,
    double nouvelleProgression,
  ) async {
    try {
      final objectif = await _databaseHelper.getObjectifById(id);
      if (objectif != null) {
        objectif.mettreAJourProgression(nouvelleProgression);
        final result = await _databaseHelper.updateObjectif(objectif);
        return result > 0;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour de la progression: $e');
      return false;
    }
  }

  /// Récupère les objectifs atteints
  Future<List<Objectif>> obtenirObjectifsAtteints() async {
    try {
      final tousLesObjectifs = await _databaseHelper.getAllObjectifs();
      return tousLesObjectifs
          .where((objectif) => objectif.estAtteint())
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des objectifs atteints: $e');
      return [];
    }
  }

  /// Récupère les objectifs en retard
  Future<List<Objectif>> obtenirObjectifsEnRetard() async {
    try {
      final tousLesObjectifs = await _databaseHelper.getAllObjectifs();
      return tousLesObjectifs
          .where((objectif) => objectif.estEnRetard())
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des objectifs en retard: $e');
      return [];
    }
  }

  /// Récupère les objectifs en cours (non atteints et non en retard)
  Future<List<Objectif>> obtenirObjectifsEnCours() async {
    try {
      final tousLesObjectifs = await _databaseHelper.getAllObjectifs();
      return tousLesObjectifs
          .where(
            (objectif) => !objectif.estAtteint() && !objectif.estEnRetard(),
          )
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des objectifs en cours: $e');
      return [];
    }
  }

  /// Calcule le pourcentage global de progression de tous les objectifs
  Future<double> calculerProgressionGlobale() async {
    try {
      final objectifs = await _databaseHelper.getAllObjectifs();
      if (objectifs.isEmpty) return 0.0;

      double progressionTotale = 0.0;
      for (final objectif in objectifs) {
        progressionTotale += objectif.calculerProgression();
      }

      return progressionTotale / objectifs.length;
    } catch (e) {
      print('Erreur lors du calcul de la progression globale: $e');
      return 0.0;
    }
  }

  /// Valide les données d'un objectif
  bool validerObjectif(Objectif objectif) {
    if (objectif.type.trim().isEmpty) {
      print('Le type d\'objectif ne peut pas être vide');
      return false;
    }

    if (objectif.valeurCible <= 0) {
      print('La valeur cible doit être positive');
      return false;
    }

    if (objectif.dateFixee.isBefore(DateTime.now())) {
      print('La date fixée ne peut pas être dans le passé');
      return false;
    }

    return true;
  }

  /// Récupère les types d'objectifs disponibles
  List<String> obtenirTypesObjectifs() {
    return [
      'Perte de poids',
      'Prise de masse',
      'Calories quotidiennes',
      'Exercice physique',
      'Hydratation',
      'Sommeil',
      'Méditation',
      'Autre',
    ];
  }

  /// Récupère les objectifs d'un utilisateur spécifique
  Future<List<Objectif>> obtenirObjectifsParUtilisateur(
    int utilisateurId,
  ) async {
    try {
      return await _databaseHelper.getObjectifsByUtilisateur(utilisateurId);
    } catch (e) {
      print(
        'Erreur lors de la récupération des objectifs de l\'utilisateur: $e',
      );
      return [];
    }
  }
}
