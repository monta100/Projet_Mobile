import '../Entites/rappel.dart';
import 'database_helper.dart';

class RappelService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Crée un nouveau rappel
  Future<int> creerRappel(Rappel rappel) async {
    try {
      final id = await _databaseHelper.insertRappel(rappel);
      print('Rappel créé avec l\'ID: $id');
      return id;
    } catch (e) {
      print('Erreur lors de la création du rappel: $e');
      rethrow;
    }
  }

  /// Récupère un rappel par ID
  Future<Rappel?> obtenirRappel(int id) async {
    try {
      return await _databaseHelper.getRappelById(id);
    } catch (e) {
      print('Erreur lors de la récupération du rappel: $e');
      return null;
    }
  }

  /// Récupère tous les rappels
  Future<List<Rappel>> obtenirTousLesRappels() async {
    try {
      return await _databaseHelper.getAllRappels();
    } catch (e) {
      print('Erreur lors de la récupération des rappels: $e');
      return [];
    }
  }

  /// Récupère les rappels non lus
  Future<List<Rappel>> obtenirRappelsNonLus() async {
    try {
      return await _databaseHelper.getRappelsNonLus();
    } catch (e) {
      print('Erreur lors de la récupération des rappels non lus: $e');
      return [];
    }
  }

  /// Récupère les rappels dus
  Future<List<Rappel>> obtenirRappelsDus() async {
    try {
      return await _databaseHelper.getRappelsDus();
    } catch (e) {
      print('Erreur lors de la récupération des rappels dus: $e');
      return [];
    }
  }

  /// Met à jour un rappel
  Future<bool> modifierRappel(Rappel rappel) async {
    try {
      final result = await _databaseHelper.updateRappel(rappel);
      if (result > 0) {
        print('Rappel modifié avec succès');
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la modification du rappel: $e');
      return false;
    }
  }

  /// Supprime un rappel
  Future<bool> supprimerRappel(int id) async {
    try {
      final result = await _databaseHelper.deleteRappel(id);
      if (result > 0) {
        print('Rappel supprimé avec succès');
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression du rappel: $e');
      return false;
    }
  }

  /// Marque un rappel comme lu
  Future<bool> marquerCommeLu(int id) async {
    try {
      final rappel = await _databaseHelper.getRappelById(id);
      if (rappel != null) {
        rappel.marquerCommeLu();
        final result = await _databaseHelper.updateRappel(rappel);
        return result > 0;
      }
      return false;
    } catch (e) {
      print('Erreur lors du marquage comme lu: $e');
      return false;
    }
  }

  /// Marque un rappel comme non lu
  Future<bool> marquerCommeNonLu(int id) async {
    try {
      final rappel = await _databaseHelper.getRappelById(id);
      if (rappel != null) {
        rappel.marquerCommeNonLu();
        final result = await _databaseHelper.updateRappel(rappel);
        return result > 0;
      }
      return false;
    } catch (e) {
      print('Erreur lors du marquage comme non lu: $e');
      return false;
    }
  }

  /// Reporte un rappel à une nouvelle date
  Future<bool> reporterRappel(int id, DateTime nouvelleDate) async {
    try {
      final rappel = await _databaseHelper.getRappelById(id);
      if (rappel != null) {
        rappel.reporter(nouvelleDate);
        final result = await _databaseHelper.updateRappel(rappel);
        return result > 0;
      }
      return false;
    } catch (e) {
      print('Erreur lors du report du rappel: $e');
      return false;
    }
  }

  /// Envoie les notifications pour tous les rappels dus
  Future<void> envoyerNotificationsDues() async {
    try {
      final rappelsDus = await obtenirRappelsDus();
      for (final rappel in rappelsDus) {
        rappel.envoyerNotification();
      }
      print('${rappelsDus.length} notifications envoyées');
    } catch (e) {
      print('Erreur lors de l\'envoi des notifications: $e');
    }
  }

  /// Récupère les rappels d'aujourd'hui
  Future<List<Rappel>> obtenirRappelsAujourdhui() async {
    try {
      final tousLesRappels = await _databaseHelper.getAllRappels();
      return tousLesRappels.where((rappel) => rappel.estAujourdhui()).toList();
    } catch (e) {
      print('Erreur lors de la récupération des rappels d\'aujourd\'hui: $e');
      return [];
    }
  }

  /// Récupère les rappels de la semaine prochaine
  Future<List<Rappel>> obtenirRappelsSemaineProchaine() async {
    try {
      final maintenant = DateTime.now();
      final debutSemaine = maintenant.add(Duration(days: 1));
      final finSemaine = maintenant.add(Duration(days: 7));
      
      final tousLesRappels = await _databaseHelper.getAllRappels();
      return tousLesRappels.where((rappel) => 
        rappel.date.isAfter(debutSemaine) && 
        rappel.date.isBefore(finSemaine)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des rappels de la semaine: $e');
      return [];
    }
  }

  /// Compte le nombre de rappels non lus
  Future<int> compterRappelsNonLus() async {
    try {
      final rappelsNonLus = await obtenirRappelsNonLus();
      return rappelsNonLus.length;
    } catch (e) {
      print('Erreur lors du comptage des rappels non lus: $e');
      return 0;
    }
  }

  /// Valide les données d'un rappel
  bool validerRappel(Rappel rappel) {
    if (rappel.message.trim().isEmpty) {
      print('Le message du rappel ne peut pas être vide');
      return false;
    }
    
    if (rappel.date.isBefore(DateTime.now())) {
      print('La date du rappel ne peut pas être dans le passé');
      return false;
    }
    
    return true;
  }

  /// Planifie un rappel récurrent (quotidien, hebdomadaire, mensuel)
  Future<List<int>> planifierRappelRecurrent(
    String message,
    DateTime dateDebut,
    String frequence, // 'quotidien', 'hebdomadaire', 'mensuel'
    int nombreRepetitions,
  ) async {
    List<int> idsCreated = [];
    
    try {
      for (int i = 0; i < nombreRepetitions; i++) {
        DateTime dateRappel;
        
        switch (frequence.toLowerCase()) {
          case 'quotidien':
            dateRappel = dateDebut.add(Duration(days: i));
            break;
          case 'hebdomadaire':
            dateRappel = dateDebut.add(Duration(days: i * 7));
            break;
          case 'mensuel':
            dateRappel = DateTime(
              dateDebut.year,
              dateDebut.month + i,
              dateDebut.day,
              dateDebut.hour,
              dateDebut.minute,
            );
            break;
          default:
            throw Exception('Fréquence non supportée: $frequence');
        }
        
        final rappel = Rappel(
          message: '$message (${i + 1}/$nombreRepetitions)',
          date: dateRappel,
        );
        
        final id = await creerRappel(rappel);
        idsCreated.add(id);
      }
      
      print('$nombreRepetitions rappels récurrents créés');
      return idsCreated;
    } catch (e) {
      print('Erreur lors de la création des rappels récurrents: $e');
      return idsCreated;
    }
  }
}