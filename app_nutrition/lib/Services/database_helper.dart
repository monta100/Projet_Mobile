// Database helper using sqflite for persistent storage
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../Entites/utilisateur.dart';
import '../Entites/objectif.dart';
import '../Entites/rappel.dart';
import '../Entites/message.dart';
import '../Entites/exercise.dart';
import '../Entites/exercise_plan.dart';
import '../Entites/exercise_session.dart';
import '../Entites/plan_exercise_assignment.dart';
import '../Entites/user_plan_assignment.dart';
import '../Entites/user_objective.dart';

class DatabaseHelper {
  // --- Singleton ---
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // bumped to 6 to add exercise tables
  static const int _dbVersion = 7;
  static const String _dbName = 'app_nutrition.db';

  // Table names
  static const String tableUtilisateurs = 'utilisateurs';
  static const String tableObjectifs = 'objectifs';
  static const String tableRappels = 'rappels';
  static const String tableMessages = 'messages';
  static const String tableExercises = 'exercises';
  static const String tableExercisePlans = 'exercise_plans';
  static const String tableExerciseSessions = 'exercise_sessions';
  static const String tablePlanExerciseAssignments = 'plan_exercise_assignments';
  static const String tableUserPlanAssignments = 'user_plan_assignments';
  static const String tableUserObjectives = 'user_objectives';
  static const String tableProgressTracking = 'progress_tracking';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    // Vérifier et créer la table user_objectives si elle n'existe pas
    await _ensureUserObjectivesTable(db);
    
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUtilisateurs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT,
        prenom TEXT,
        email TEXT UNIQUE,
        motDePasse TEXT,
        role TEXT,
        coach_id INTEGER,
        isVerified INTEGER,
        verificationCode TEXT,
        verificationExpiry TEXT
      )
    ''');
    // If DB version >=3 we expect avatar columns to exist; add them
    try {
      await db.execute(
        'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarPath TEXT',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarColor TEXT',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarInitials TEXT',
      );
    } catch (_) {}

    await db.execute('''
      CREATE TABLE $tableObjectifs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utilisateur_id INTEGER,
        type TEXT,
        valeurCible REAL,
        dateFixee TEXT,
        progression REAL,
        FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableRappels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utilisateur_id INTEGER,
        message TEXT,
        date TEXT,
        statut INTEGER,
        FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableMessages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER,
        receiver_id INTEGER,
        content TEXT,
        type TEXT,
        created_at TEXT,
        read INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
      )
    ''');

    // Exercise tables
    await db.execute('''
      CREATE TABLE $tableExercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        partie_corps TEXT NOT NULL,
        niveau TEXT NOT NULL,
        objectif TEXT NOT NULL,
        materiel TEXT NOT NULL,
        video_url TEXT,
        image_url TEXT,
        duree_estimee INTEGER NOT NULL,
        calories_estimees INTEGER NOT NULL,
        instructions TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableExercisePlans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        coach_id INTEGER NOT NULL,
        nom TEXT NOT NULL,
        description TEXT,
        date_creation TEXT NOT NULL,
        date_debut TEXT,
        date_fin TEXT,
        is_active INTEGER DEFAULT 1,
        notes_coach TEXT,
        FOREIGN KEY (coach_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePlanExerciseAssignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        ordre INTEGER NOT NULL,
        nombre_series INTEGER NOT NULL,
        repetitions_par_serie INTEGER NOT NULL,
        temps_repos INTEGER NOT NULL,
        notes_personnalisees TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (plan_id) REFERENCES $tableExercisePlans(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES $tableExercises(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableUserPlanAssignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utilisateur_id INTEGER NOT NULL,
        plan_id INTEGER NOT NULL,
        date_attribution TEXT NOT NULL,
        date_debut TEXT,
        date_fin TEXT,
        is_active INTEGER DEFAULT 1,
        message_coach TEXT,
        progression INTEGER DEFAULT 0,
        FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE,
        FOREIGN KEY (plan_id) REFERENCES $tableExercisePlans(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableUserObjectives (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utilisateurId INTEGER NOT NULL,
        typeObjectif TEXT NOT NULL,
        description TEXT NOT NULL,
        poidsActuel REAL NOT NULL,
        poidsCible REAL NOT NULL,
        taille REAL NOT NULL,
        age INTEGER NOT NULL,
        niveauActivite TEXT NOT NULL,
        dureeObjectif INTEGER NOT NULL,
        coachId INTEGER NOT NULL,
        dateCreation TEXT NOT NULL,
        dateDebut TEXT NOT NULL,
        dateFin TEXT NOT NULL,
        progression REAL NOT NULL DEFAULT 0.0,
        estAtteint INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (utilisateurId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE,
        FOREIGN KEY (coachId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableProgressTracking (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utilisateur_id INTEGER NOT NULL,
        plan_id INTEGER,
        objective_id INTEGER,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        metric TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT,
        notes TEXT,
        metadata TEXT,
        date_created TEXT NOT NULL,
        FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE,
        FOREIGN KEY (plan_id) REFERENCES $tableExercisePlans(id) ON DELETE CASCADE,
        FOREIGN KEY (objective_id) REFERENCES $tableUserObjectives(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableExerciseSessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        utilisateur_id INTEGER NOT NULL,
        nombre_series INTEGER NOT NULL,
        repetitions_par_serie INTEGER NOT NULL,
        temps_repos INTEGER NOT NULL,
        duree_reelle INTEGER,
        date_debut TEXT,
        date_fin TEXT,
        est_terminee INTEGER DEFAULT 0,
        difficulte INTEGER,
        commentaire_utilisateur TEXT,
        notes_coach TEXT,
        calories_brulées INTEGER,
        FOREIGN KEY (plan_id) REFERENCES $tableExercisePlans(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES $tableExercises(id) ON DELETE CASCADE,
        FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add avatarPath and avatarColor
      try {
        await db.execute(
          'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarPath TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarColor TEXT',
        );
      } catch (_) {}
      oldVersion = 2;
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarInitials TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE $tableUtilisateurs ADD COLUMN coach_id INTEGER',
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE $tableMessages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_id INTEGER,
            receiver_id INTEGER,
            content TEXT,
            type TEXT,
            created_at TEXT,
            read INTEGER DEFAULT 0,
            FOREIGN KEY (sender_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE,
            FOREIGN KEY (receiver_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      // Add exercise tables
      try {
        await db.execute('''
          CREATE TABLE $tableExercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL,
            partie_corps TEXT NOT NULL,
            niveau TEXT NOT NULL,
            objectif TEXT NOT NULL,
            materiel TEXT NOT NULL,
            video_url TEXT,
            image_url TEXT,
            duree_estimee INTEGER NOT NULL,
            calories_estimees INTEGER NOT NULL,
            instructions TEXT,
            is_active INTEGER DEFAULT 1
          )
        ''');
      } catch (_) {}
      
      try {
        await db.execute('''
          CREATE TABLE $tableExercisePlans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            coach_id INTEGER NOT NULL,
            nom TEXT NOT NULL,
            description TEXT,
            date_creation TEXT NOT NULL,
            date_debut TEXT,
            date_fin TEXT,
            is_active INTEGER DEFAULT 1,
            notes_coach TEXT,
            FOREIGN KEY (coach_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
      
      try {
        await db.execute('''
          CREATE TABLE $tablePlanExerciseAssignments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_id INTEGER NOT NULL,
            exercise_id INTEGER NOT NULL,
            ordre INTEGER NOT NULL,
            nombre_series INTEGER NOT NULL,
            repetitions_par_serie INTEGER NOT NULL,
            temps_repos INTEGER NOT NULL,
            notes_personnalisees TEXT,
            is_active INTEGER DEFAULT 1,
            FOREIGN KEY (plan_id) REFERENCES $tableExercisePlans(id) ON DELETE CASCADE,
            FOREIGN KEY (exercise_id) REFERENCES $tableExercises(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
      
      try {
        await db.execute('''
          CREATE TABLE $tableUserPlanAssignments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            utilisateur_id INTEGER NOT NULL,
            plan_id INTEGER NOT NULL,
            date_attribution TEXT NOT NULL,
            date_debut TEXT,
            date_fin TEXT,
            is_active INTEGER DEFAULT 1,
            message_coach TEXT,
            progression INTEGER DEFAULT 0,
            FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE,
            FOREIGN KEY (plan_id) REFERENCES $tableExercisePlans(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
      
      try {
        await db.execute('''
          CREATE TABLE $tableExerciseSessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_id INTEGER NOT NULL,
            exercise_id INTEGER NOT NULL,
            utilisateur_id INTEGER NOT NULL,
            nombre_series INTEGER NOT NULL,
            repetitions_par_serie INTEGER NOT NULL,
            temps_repos INTEGER NOT NULL,
            duree_reelle INTEGER,
            date_debut TEXT,
            date_fin TEXT,
            est_terminee INTEGER DEFAULT 0,
            difficulte INTEGER,
            commentaire_utilisateur TEXT,
            notes_coach TEXT,
            calories_brulées INTEGER,
            FOREIGN KEY (plan_id) REFERENCES $tableExercisePlans(id) ON DELETE CASCADE,
            FOREIGN KEY (exercise_id) REFERENCES $tableExercises(id) ON DELETE CASCADE,
            FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      // Add user_objectives table
      try {
        await db.execute('''
          CREATE TABLE $tableUserObjectives (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            utilisateurId INTEGER NOT NULL,
            typeObjectif TEXT NOT NULL,
            description TEXT NOT NULL,
            poidsActuel REAL NOT NULL,
            poidsCible REAL NOT NULL,
            taille REAL NOT NULL,
            age INTEGER NOT NULL,
            niveauActivite TEXT NOT NULL,
            dureeObjectif INTEGER NOT NULL,
            coachId INTEGER NOT NULL,
            dateCreation TEXT NOT NULL,
            dateDebut TEXT NOT NULL,
            dateFin TEXT NOT NULL,
            progression REAL NOT NULL DEFAULT 0.0,
            estAtteint INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            FOREIGN KEY (utilisateurId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE,
            FOREIGN KEY (coachId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
  }

  // Generic helper methods
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // --- Utilisateur ---
  Future<int> insertUtilisateur(Utilisateur utilisateur) async {
    final data = utilisateur.toMap();
    data.remove('id');
    // Store boolean as integer
    data['isVerified'] = utilisateur.isVerified ? 1 : 0;
    return await insert(tableUtilisateurs, data);
  }

  Future<List<Utilisateur>> getAllUtilisateurs() async {
    final rows = await queryAll(tableUtilisateurs);
    return rows.map((r) => Utilisateur.fromMap(r)).toList();
  }

  Future<Utilisateur?> getUtilisateurById(int id) async {
    final db = await database;
    final rows = await db.query(
      tableUtilisateurs,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Utilisateur.fromMap(rows.first);
  }

  Future<Utilisateur?> getUtilisateurByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      tableUtilisateurs,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (rows.isEmpty) return null;
    return Utilisateur.fromMap(rows.first);
  }

  /// Récupère les clients d'un coach (utilisateurs ayant coach_id = coachId)
  Future<List<Utilisateur>> getClientsByCoach(int coachId) async {
    final db = await database;
    final rows = await db.query(
      tableUtilisateurs,
      where: 'coach_id = ?',
      whereArgs: [coachId],
    );
    return rows.map((r) => Utilisateur.fromMap(r)).toList();
  }

  Future<int> updateUtilisateur(Utilisateur utilisateur) async {
    final data = utilisateur.toMap();
    data.remove('id');
    data['isVerified'] = utilisateur.isVerified ? 1 : 0;
    return await update(tableUtilisateurs, data, utilisateur.id!);
  }

  Future<int> deleteUtilisateur(int id) async {
    return await delete(tableUtilisateurs, id);
  }

  // --- Objectif ---
  Future<int> insertObjectif(Objectif objectif) async {
    final data = objectif.toMap();
    data['utilisateur_id'] = objectif.utilisateurId;
    data.remove('id');
    return await insert(tableObjectifs, {
      'utilisateur_id': data['utilisateur_id'],
      'type': data['type'],
      'valeurCible': data['valeurCible'],
      'dateFixee': data['dateFixee'],
      'progression': data['progression'],
    });
  }

  Future<List<Objectif>> getAllObjectifs() async {
    final rows = await queryAll(tableObjectifs);
    return rows.map((r) => Objectif.fromMap(r)).toList();
  }

  Future<Objectif?> getObjectifById(int id) async {
    final db = await database;
    final rows = await db.query(
      tableObjectifs,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Objectif.fromMap(rows.first);
  }

  Future<List<Objectif>> getObjectifsByType(String type) async {
    final db = await database;
    final rows = await db.query(
      tableObjectifs,
      where: 'type = ?',
      whereArgs: [type],
    );
    return rows.map((r) => Objectif.fromMap(r)).toList();
  }

  Future<List<Objectif>> getObjectifsByUtilisateur(int utilisateurId) async {
    final db = await database;
    final rows = await db.query(
      tableObjectifs,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );
    return rows.map((r) => Objectif.fromMap(r)).toList();
  }

  Future<int> updateObjectif(Objectif objectif) async {
    final data = objectif.toMap();
    data['utilisateur_id'] = objectif.utilisateurId;
    data.remove('id');
    return await update(tableObjectifs, {
      'utilisateur_id': data['utilisateur_id'],
      'type': data['type'],
      'valeurCible': data['valeurCible'],
      'dateFixee': data['dateFixee'],
      'progression': data['progression'],
    }, objectif.id!);
  }

  Future<int> deleteObjectif(int id) async {
    return await delete(tableObjectifs, id);
  }

  // --- Rappel ---
  Future<int> insertRappel(Rappel rappel) async {
    final data = rappel.toMap();
    data['utilisateur_id'] = rappel.utilisateurId;
    data.remove('id');
    data['statut'] = rappel.statut ? 1 : 0;
    return await insert(tableRappels, {
      'utilisateur_id': data['utilisateur_id'],
      'message': data['message'],
      'date': data['date'],
      'statut': data['statut'],
    });
  }

  Future<List<Rappel>> getAllRappels() async {
    final rows = await queryAll(tableRappels);
    return rows.map((r) => Rappel.fromMap(r)).toList();
  }

  Future<Rappel?> getRappelById(int id) async {
    final db = await database;
    final rows = await db.query(tableRappels, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Rappel.fromMap(rows.first);
  }

  Future<List<Rappel>> getRappelsNonLus() async {
    final db = await database;
    final rows = await db.query(
      tableRappels,
      where: 'statut = ?',
      whereArgs: [0],
    );
    return rows.map((r) => Rappel.fromMap(r)).toList();
  }

  Future<List<Rappel>> getRappelsDus() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT * FROM $tableRappels WHERE datetime(date) < datetime(?) AND statut = 0',
      [DateTime.now().toIso8601String()],
    );
    return rows.map((r) => Rappel.fromMap(r)).toList();
  }

  Future<List<Rappel>> getRappelsByUtilisateur(int utilisateurId) async {
    final db = await database;
    final rows = await db.query(
      tableRappels,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );
    return rows.map((r) => Rappel.fromMap(r)).toList();
  }

  Future<List<Rappel>> getRappelsNonLusByUtilisateur(int utilisateurId) async {
    final db = await database;
    final rows = await db.query(
      tableRappels,
      where: 'utilisateur_id = ? AND statut = 0',
      whereArgs: [utilisateurId],
    );
    return rows.map((r) => Rappel.fromMap(r)).toList();
  }

  Future<int> updateRappel(Rappel rappel) async {
    final data = rappel.toMap();
    data['statut'] = rappel.statut ? 1 : 0;
    data['utilisateur_id'] = rappel.utilisateurId;
    data.remove('id');
    return await update(tableRappels, {
      'utilisateur_id': data['utilisateur_id'],
      'message': data['message'],
      'date': data['date'],
      'statut': data['statut'],
    }, rappel.id!);
  }

  Future<int> deleteRappel(int id) async {
    return await delete(tableRappels, id);
  }

  // --- Messages ---
  Future<int> insertMessage(Message message) async {
    final db = await database;
    final data = message.toMap();
    data.remove('id');
    return await db.insert(tableMessages, data);
  }

  Future<List<Message>> getMessagesBetween(int userA, int userB) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT * FROM $tableMessages WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?) ORDER BY datetime(created_at) ASC',
      [userA, userB, userB, userA],
    );
    return rows.map((r) => Message.fromMap(r)).toList();
  }

  Future<List<Message>> getMessagesForUser(int userId) async {
    final db = await database;
    final rows = await db.query(
      tableMessages,
      where: 'sender_id = ? OR receiver_id = ?',
      whereArgs: [userId, userId],
      orderBy: 'datetime(created_at) ASC',
    );
    return rows.map((r) => Message.fromMap(r)).toList();
  }

  Future<int> markMessageAsRead(int messageId) async {
    final db = await database;
    return await db.update(
      tableMessages,
      {'read': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // --- Utilities ---
  /// Vérifie et crée la table user_objectives si elle n'existe pas
  Future<void> _ensureUserObjectivesTable(Database db) async {
    try {
      // Vérifier si la table existe en essayant de la requêter
      await db.query(tableUserObjectives, limit: 1);
    } catch (e) {
      // Si la table n'existe pas, la créer
      await db.execute('''
        CREATE TABLE $tableUserObjectives (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          utilisateurId INTEGER NOT NULL,
          typeObjectif TEXT NOT NULL,
          description TEXT NOT NULL,
          poidsActuel REAL NOT NULL,
          poidsCible REAL NOT NULL,
          taille REAL NOT NULL,
          age INTEGER NOT NULL,
          niveauActivite TEXT NOT NULL,
          dureeObjectif INTEGER NOT NULL,
          coachId INTEGER NOT NULL,
          dateCreation TEXT NOT NULL,
          dateDebut TEXT NOT NULL,
          dateFin TEXT NOT NULL,
          progression REAL NOT NULL DEFAULT 0.0,
          estAtteint INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          FOREIGN KEY (utilisateurId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE,
          FOREIGN KEY (coachId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  /// Initialise quelques données de test (toujours disponibles)
  Future<void> initTestData() async {
    // Vérifier si les utilisateurs de test existent déjà
    final existingTestUser = await getUtilisateurByEmail('jean.dupont@test.com');
    final existingCoach = await getUtilisateurByEmail('coach@test.com');
    
    int coachId;
    int userId;
    
    if (existingCoach == null) {
      // Créer un coach de test
      final testCoach = Utilisateur(
        nom: 'Martin',
        prenom: 'Pierre',
        email: 'coach@test.com',
        motDePasse: 'Test123!',
        role: 'Coach',
        isVerified: true,
      );
      coachId = await insertUtilisateur(testCoach);
    } else {
      coachId = existingCoach.id!;
    }
    
    if (existingTestUser == null) {
      // Créer un utilisateur de test avec le coach assigné
      final testUser = Utilisateur(
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean.dupont@test.com',
        motDePasse: 'Test123!',
        role: 'Utilisateur',
        coachId: coachId,
        isVerified: true,
      );
      userId = await insertUtilisateur(testUser);
    } else {
      userId = existingTestUser.id!;
    }

    // Créer les données de test seulement si l'utilisateur de test n'existait pas
    if (existingTestUser == null) {
      final testObjectif = Objectif(
        utilisateurId: userId,
        type: 'Perte de poids',
        valeurCible: 5.0,
        dateFixee: DateTime.now().add(const Duration(days: 30)),
        progression: 1.5,
      );
      await insertObjectif(testObjectif);

      final testRappel = Rappel(
        utilisateurId: userId,
        message: 'Boire un verre d\'eau',
        date: DateTime.now().add(const Duration(hours: 1)),
      );
      await insertRappel(testRappel);
      
      // Créer un plan de test et l'assigner à l'utilisateur
      final testPlan = ExercisePlan(
        coachId: coachId,
        nom: 'Plan Débutant',
        description: 'Plan d\'entraînement pour débutant avec exercices de base',
        dateCreation: DateTime.now(),
        notesCoach: 'Commencez doucement et augmentez progressivement l\'intensité.',
      );
      final planId = await insertExercisePlan(testPlan);
      
      // Assigner le plan à l'utilisateur
      final userPlanAssignment = UserPlanAssignment(
        utilisateurId: userId,
        planId: planId,
        dateAttribution: DateTime.now(),
        messageCoach: 'Bienvenue ! Votre coach vous a préparé un plan personnalisé. 💪',
      );
      await insertUserPlanAssignment(userPlanAssignment);
    }
  }

  // --- Exercise ---
  Future<int> insertExercise(Exercise exercise) async {
    final data = exercise.toMap();
    data.remove('id');
    data['is_active'] = exercise.isActive ? 1 : 0;
    return await insert(tableExercises, data);
  }

  Future<List<Exercise>> getAllExercises() async {
    final rows = await queryAll(tableExercises);
    return rows.map((r) => Exercise.fromMap(r)).toList();
  }

  Future<Exercise?> getExerciseById(int id) async {
    final db = await database;
    final rows = await db.query(
      tableExercises,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  Future<List<Exercise>> getExercisesByType(String type) async {
    final db = await database;
    final rows = await db.query(
      tableExercises,
      where: 'type = ? AND is_active = 1',
      whereArgs: [type],
    );
    return rows.map((r) => Exercise.fromMap(r)).toList();
  }

  Future<List<Exercise>> getExercisesByNiveau(String niveau) async {
    final db = await database;
    final rows = await db.query(
      tableExercises,
      where: 'niveau = ? AND is_active = 1',
      whereArgs: [niveau],
    );
    return rows.map((r) => Exercise.fromMap(r)).toList();
  }

  Future<List<Exercise>> getExercisesByObjectif(String objectif) async {
    final db = await database;
    final rows = await db.query(
      tableExercises,
      where: 'objectif LIKE ? AND is_active = 1',
      whereArgs: ['%$objectif%'],
    );
    return rows.map((r) => Exercise.fromMap(r)).toList();
  }

  Future<List<Exercise>> searchExercises(String query) async {
    final db = await database;
    final rows = await db.query(
      tableExercises,
      where: '(nom LIKE ? OR description LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%'],
    );
    return rows.map((r) => Exercise.fromMap(r)).toList();
  }

  Future<int> updateExercise(Exercise exercise) async {
    final data = exercise.toMap();
    data.remove('id');
    data['is_active'] = exercise.isActive ? 1 : 0;
    return await update(tableExercises, data, exercise.id!);
  }

  Future<int> deleteExercise(int id) async {
    return await delete(tableExercises, id);
  }

  // --- ExercisePlan ---
  Future<int> insertExercisePlan(ExercisePlan plan) async {
    final data = plan.toMap();
    data.remove('id');
    data['is_active'] = plan.isActive ? 1 : 0;
    return await insert(tableExercisePlans, data);
  }

  Future<List<ExercisePlan>> getAllExercisePlans() async {
    final rows = await queryAll(tableExercisePlans);
    return rows.map((r) => ExercisePlan.fromMap(r)).toList();
  }

  Future<ExercisePlan?> getExercisePlanById(int id) async {
    final db = await database;
    final rows = await db.query(
      tableExercisePlans,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return ExercisePlan.fromMap(rows.first);
  }

  Future<List<ExercisePlan>> getExercisePlansByCoach(int coachId) async {
    final db = await database;
    final rows = await db.query(
      tableExercisePlans,
      where: 'coach_id = ? AND is_active = 1',
      whereArgs: [coachId],
    );
    return rows.map((r) => ExercisePlan.fromMap(r)).toList();
  }

  Future<int> updateExercisePlan(ExercisePlan plan) async {
    final data = plan.toMap();
    data.remove('id');
    data['is_active'] = plan.isActive ? 1 : 0;
    return await update(tableExercisePlans, data, plan.id!);
  }

  Future<int> deleteExercisePlan(int id) async {
    return await delete(tableExercisePlans, id);
  }

  // --- PlanExerciseAssignment ---
  Future<int> insertPlanExerciseAssignment(PlanExerciseAssignment assignment) async {
    final data = assignment.toMap();
    data.remove('id');
    data['is_active'] = assignment.isActive ? 1 : 0;
    return await insert(tablePlanExerciseAssignments, data);
  }

  Future<List<PlanExerciseAssignment>> getPlanExerciseAssignmentsByPlan(int planId) async {
    final db = await database;
    final rows = await db.query(
      tablePlanExerciseAssignments,
      where: 'plan_id = ? AND is_active = 1',
      whereArgs: [planId],
      orderBy: 'ordre ASC',
    );
    return rows.map((r) => PlanExerciseAssignment.fromMap(r)).toList();
  }

  Future<int> updatePlanExerciseAssignment(PlanExerciseAssignment assignment) async {
    final data = assignment.toMap();
    data.remove('id');
    data['is_active'] = assignment.isActive ? 1 : 0;
    return await update(tablePlanExerciseAssignments, data, assignment.id!);
  }

  Future<int> deletePlanExerciseAssignment(int id) async {
    return await delete(tablePlanExerciseAssignments, id);
  }

  // --- UserPlanAssignment ---
  Future<int> insertUserPlanAssignment(UserPlanAssignment assignment) async {
    final data = assignment.toMap();
    data.remove('id');
    data['is_active'] = assignment.isActive ? 1 : 0;
    return await insert(tableUserPlanAssignments, data);
  }

  Future<List<UserPlanAssignment>> getUserPlanAssignmentsByUser(int utilisateurId) async {
    final db = await database;
    final rows = await db.query(
      tableUserPlanAssignments,
      where: 'utilisateur_id = ? AND is_active = 1',
      whereArgs: [utilisateurId],
      orderBy: 'date_attribution DESC',
    );
    return rows.map((r) => UserPlanAssignment.fromMap(r)).toList();
  }

  Future<List<UserPlanAssignment>> getUserPlanAssignmentsByPlan(int planId) async {
    final db = await database;
    final rows = await db.query(
      tableUserPlanAssignments,
      where: 'plan_id = ? AND is_active = 1',
      whereArgs: [planId],
    );
    return rows.map((r) => UserPlanAssignment.fromMap(r)).toList();
  }

  Future<int> updateUserPlanAssignment(UserPlanAssignment assignment) async {
    final data = assignment.toMap();
    data.remove('id');
    data['is_active'] = assignment.isActive ? 1 : 0;
    return await update(tableUserPlanAssignments, data, assignment.id!);
  }

  Future<int> deleteUserPlanAssignment(int id) async {
    return await delete(tableUserPlanAssignments, id);
  }

  // --- ExerciseSession ---
  Future<int> insertExerciseSession(ExerciseSession session) async {
    final data = session.toMap();
    data.remove('id');
    data['est_terminee'] = session.estTerminee ? 1 : 0;
    return await insert(tableExerciseSessions, data);
  }

  Future<List<ExerciseSession>> getExerciseSessionsByUser(int utilisateurId) async {
    final db = await database;
    final rows = await db.query(
      tableExerciseSessions,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
      orderBy: 'date_debut DESC',
    );
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  Future<List<ExerciseSession>> getExerciseSessionsByPlan(int planId) async {
    final db = await database;
    final rows = await db.query(
      tableExerciseSessions,
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'date_debut DESC',
    );
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  Future<List<ExerciseSession>> getExerciseSessionsByUserAndPlan(int utilisateurId, int planId) async {
    final db = await database;
    final rows = await db.query(
      tableExerciseSessions,
      where: 'utilisateur_id = ? AND plan_id = ?',
      whereArgs: [utilisateurId, planId],
      orderBy: 'date_debut DESC',
    );
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  Future<int> updateExerciseSession(ExerciseSession session) async {
    final data = session.toMap();
    data.remove('id');
    data['est_terminee'] = session.estTerminee ? 1 : 0;
    return await update(tableExerciseSessions, data, session.id!);
  }

  Future<int> deleteExerciseSession(int id) async {
    return await delete(tableExerciseSessions, id);
  }

  /// Efface toutes les données (utilitaire de développement)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableExerciseSessions);
    await db.delete(tableUserPlanAssignments);
    await db.delete(tablePlanExerciseAssignments);
    await db.delete(tableExercisePlans);
    await db.delete(tableExercises);
    await db.delete(tableUserObjectives);
    await db.delete(tableRappels);
    await db.delete(tableObjectifs);
    await db.delete(tableUtilisateurs);
  }

  /// Force la recréation de la base de données (utilitaire de développement)
  Future<void> recreateDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
    
    // Supprimer le fichier de base de données
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, _dbName);
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    
    // Recréer la base de données
    await database;
  }

  // User Objectives CRUD operations
  Future<int> insertUserObjective(UserObjective objective) async {
    final db = await database;
    return await db.insert(tableUserObjectives, objective.toMap());
  }

  Future<List<UserObjective>> getUserObjectives(int utilisateurId) async {
    final db = await database;
    final rows = await db.query(
      tableUserObjectives,
      where: 'utilisateurId = ?',
      whereArgs: [utilisateurId],
      orderBy: 'dateCreation DESC',
    );
    return rows.map((r) => UserObjective.fromMap(r)).toList();
  }

  Future<UserObjective?> getUserObjective(int id) async {
    final db = await database;
    final rows = await db.query(
      tableUserObjectives,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return UserObjective.fromMap(rows.first);
  }

  Future<int> updateUserObjective(UserObjective objective) async {
    final db = await database;
    return await db.update(
      tableUserObjectives,
      objective.toMap(),
      where: 'id = ?',
      whereArgs: [objective.id],
    );
  }

  Future<int> deleteUserObjective(int id) async {
    final db = await database;
    return await db.delete(
      tableUserObjectives,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UserObjective>> getUserObjectivesByCoach(int coachId) async {
    final db = await database;
    final rows = await db.query(
      tableUserObjectives,
      where: 'coachId = ?',
      whereArgs: [coachId],
      orderBy: 'dateCreation DESC',
    );
    return rows.map((r) => UserObjective.fromMap(r)).toList();
  }


  // Méthodes pour les assignations de plans
  Future<List<UserPlanAssignment>> getUserPlanAssignmentsByCoach(int coachId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT upa.* FROM $tableUserPlanAssignments upa
      INNER JOIN $tableExercisePlans ep ON upa.plan_id = ep.id
      WHERE ep.coach_id = ?
      ORDER BY upa.date_attribution DESC
    ''', [coachId]);
    return rows.map((r) => UserPlanAssignment.fromMap(r)).toList();
  }

  // Méthodes pour le suivi de progression
  Future<int> insertProgressTracking(Map<String, dynamic> data) async {
    return await insert(tableProgressTracking, data);
  }

  Future<List<Map<String, dynamic>>> getProgressTrackingByUser(int utilisateurId) async {
    final db = await database;
    return await db.query(
      tableProgressTracking,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
      orderBy: 'date DESC',
    );
  }
}
