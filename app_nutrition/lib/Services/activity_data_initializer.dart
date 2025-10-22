import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../Entites/programme.dart';
import '../Entites/session.dart';
import '../Entites/exercice.dart';
import '../Entites/progression.dart';
import 'database_helper.dart';
import 'programme_service.dart';
import 'session_service.dart';
import 'exercice_service.dart';
import 'progression_service.dart';

/// 🚀 Service d'initialisation des données de test pour le module activité physique
class ActivityDataInitializer {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ProgrammeService _programmeService = ProgrammeService();
  final SessionService _sessionService = SessionService();
  final ExerciceService _exerciceService = ExerciceService();
  final ProgressionService _progressionService = ProgressionService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Initialiser toutes les données de test
  Future<void> initAll() async {
    // Vérifier si des programmes existent déjà
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${Programme.tableName}');
    final count = Sqflite.firstIntValue(result) ?? 0;
    
    if (count > 0) {
      print('✅ Données activité physique déjà initialisées ($count programmes)');
      return;
    }

    print('🚀 Initialisation des données activité physique...');

    await _initProgrammes();
    await _initSessions();
    
    print('✅ Données activité physique initialisées avec succès !');
  }

  /// Initialiser les programmes de test
  Future<void> _initProgrammes() async {
    final now = DateTime.now();
    final programmes = [
      Programme(
        nom: 'Prise de masse 💪',
        objectif: 'Gagner 5kg de muscle',
        dateDebut: _dateFormat.format(now.subtract(const Duration(days: 30))),
        dateFin: _dateFormat.format(now.add(const Duration(days: 60))),
      ),
      Programme(
        nom: 'Cardio intensif 🏃',
        objectif: 'Améliorer endurance',
        dateDebut: _dateFormat.format(now.subtract(const Duration(days: 15))),
        dateFin: _dateFormat.format(now.add(const Duration(days: 45))),
      ),
      Programme(
        nom: 'Perte de poids 🔥',
        objectif: 'Perdre 8kg',
        dateDebut: _dateFormat.format(now),
        dateFin: _dateFormat.format(now.add(const Duration(days: 90))),
      ),
    ];

    for (final programme in programmes) {
      final id = await _programmeService.insertProgramme(programme);
      print('✅ Programme créé : ${programme.nom} (ID: $id)');
      
      // Ajouter des exercices pour chaque programme
      await _initExercicesForProgramme(id, programme.nom);
    }
  }

  /// Initialiser les exercices pour un programme
  Future<void> _initExercicesForProgramme(int programmeId, String programmeName) async {
    List<Exercice> exercices = [];

    if (programmeName.contains('masse')) {
      exercices = [
        Exercice(
          nom: 'Développé couché',
          description: 'Exercice pour les pectoraux',
          repetitions: 12,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
        Exercice(
          nom: 'Squat',
          description: 'Exercice pour les jambes',
          repetitions: 15,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
        Exercice(
          nom: 'Rowing',
          description: 'Exercice pour le dos',
          repetitions: 10,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
      ];
    } else if (programmeName.contains('Cardio')) {
      exercices = [
        Exercice(
          nom: 'Course à pied',
          description: '30 min de course',
          repetitions: 1,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
        Exercice(
          nom: 'Burpees',
          description: 'Exercice full body',
          repetitions: 20,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
        Exercice(
          nom: 'Corde à sauter',
          description: '15 min de corde',
          repetitions: 1,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
      ];
    } else {
      exercices = [
        Exercice(
          nom: 'HIIT',
          description: 'Entraînement haute intensité',
          repetitions: 8,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
        Exercice(
          nom: 'Abdos',
          description: 'Renforcement abdominal',
          repetitions: 25,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
        Exercice(
          nom: 'Vélo elliptique',
          description: '25 min de cardio',
          repetitions: 1,
          imagePath: '',
          videoPath: '',
          programmeId: programmeId,
        ),
      ];
    }

    for (final exercice in exercices) {
      await _exerciceService.insertExercice(exercice);
    }
    print('  ✅ ${exercices.length} exercices ajoutés');
  }

  /// Initialiser les sessions de test
  Future<void> _initSessions() async {
    final now = DateTime.now();
    final sessions = [
      // Sessions récentes
      Session(
        typeActivite: 'Musculation',
        duree: 60,
        intensite: 'Élevée',
        calories: 450,
        date: _dateFormat.format(now.subtract(const Duration(days: 1))),
        programmeId: null,
      ),
      Session(
        typeActivite: 'Cardio',
        duree: 45,
        intensite: 'Moyenne',
        calories: 320,
        date: _dateFormat.format(now.subtract(const Duration(days: 2))),
        programmeId: null,
      ),
      Session(
        typeActivite: 'Yoga',
        duree: 30,
        intensite: 'Faible',
        calories: 150,
        date: _dateFormat.format(now.subtract(const Duration(days: 3))),
        programmeId: null,
      ),
      // Sessions plus anciennes
      Session(
        typeActivite: 'Course',
        duree: 40,
        intensite: 'Élevée',
        calories: 400,
        date: _dateFormat.format(now.subtract(const Duration(days: 5))),
        programmeId: null,
      ),
      Session(
        typeActivite: 'Natation',
        duree: 50,
        intensite: 'Moyenne',
        calories: 380,
        date: _dateFormat.format(now.subtract(const Duration(days: 7))),
        programmeId: null,
      ),
    ];

    for (final session in sessions) {
      final id = await _sessionService.insertSession(session);
      
      // Créer une progression pour chaque session
      await _progressionService.insertProgression(
        Progression(
          date: session.date,
          caloriesBrulees: session.calories,
          dureeTotale: session.duree,
          commentaire: 'Séance ${session.typeActivite} - Intensité ${session.intensite}',
          sessionId: id,
        ),
      );
    }
    print('✅ ${sessions.length} sessions créées avec progressions');
  }

  /// Réinitialiser toutes les données (pour test)
  Future<void> reset() async {
    print('🗑️ Suppression des données activité physique...');
    
    final db = await _dbHelper.database;
    await db.delete('progressions');
    await db.delete('exercices');
    await db.delete('sessions');
    await db.delete('programmes');
    
    print('✅ Données supprimées, réinitialisation...');
    await initAll();
  }
}

