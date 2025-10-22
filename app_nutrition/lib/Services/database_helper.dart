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

  // --- Configuration ---
  static const String _dbName = 'app_nutrition10.db';
  static const int _dbVersion = 10;
  // v7: finalise table recettes avec colonne utilisateur_id (rebuild propre)


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
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {



    // Table repas
    await db.execute('''
      CREATE TABLE repas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        nom TEXT,
        calories_totales REAL NOT NULL DEFAULT 0,
        utilisateur_id INTEGER NOT NULL,
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
      )
    ''');

    // Table recettes (schéma final v7)
    await db.execute('''
      CREATE TABLE recettes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT,
        calories REAL NOT NULL DEFAULT 0,
        repas_id INTEGER NULL,
        publie INTEGER NOT NULL DEFAULT 0,
        imageUrl TEXT,          
        utilisateur_id INTEGER NULL,
        FOREIGN KEY (repas_id) REFERENCES repas(id) ON DELETE CASCADE,
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
      )
    ''');

    // Table ingrédients
    await db.execute('''
      CREATE TABLE ingredients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        quantite REAL NOT NULL,
        unite TEXT NOT NULL,
        calories REAL NOT NULL,
        recette_id INTEGER NOT NULL,
        FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE
      )
    ''');

    // Index pour accélérer les recherches
    await db.execute(
      'CREATE INDEX idx_repas_utilisateur ON repas(utilisateur_id)',
    );
    await db.execute('CREATE INDEX idx_recettes_repas ON recettes(repas_id)');
    await db.execute(
      'CREATE INDEX idx_recettes_user ON recettes(utilisateur_id)',
    );
    await db.execute(
      'CREATE INDEX idx_ingredients_recette ON ingredients(recette_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Safely attempt to add column if not exists.
      try {
        await db.execute(
          'ALTER TABLE recettes ADD COLUMN publie INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
    // Anciennes migrations (<5 et <6) remplacées par un rebuild unique en v7
    if (oldVersion < 7) {
      // Construire la table finale
      await db.execute('''
        CREATE TABLE recettes_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          description TEXT,
          calories REAL NOT NULL DEFAULT 0,
          repas_id INTEGER NULL,
          publie INTEGER NOT NULL DEFAULT 0,
          utilisateur_id INTEGER NULL,
          FOREIGN KEY (repas_id) REFERENCES repas(id) ON DELETE CASCADE,
          FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
        )
      ''');
      // Copier les données existantes (colonnes si présentes)
      // On tente de sélectionner utilisateur_id si déjà existante, sinon NULL
      try {
        await db.execute('''
          INSERT INTO recettes_new(id, nom, description, calories, repas_id, publie, utilisateur_id)
          SELECT id, nom, description, calories, repas_id, COALESCE(publie,0), utilisateur_id FROM recettes
        ''');
      } catch (_) {
        await db.execute('''
          INSERT INTO recettes_new(id, nom, description, calories, repas_id, publie, utilisateur_id)
          SELECT id, nom, description, calories, repas_id, COALESCE(publie,0), NULL FROM recettes
        ''');
      }
      await db.execute('DROP TABLE recettes');
      await db.execute('ALTER TABLE recettes_new RENAME TO recettes');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recettes_repas ON recettes(repas_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recettes_user ON recettes(utilisateur_id)',
      );
    }
  }

  // --- Méthodes génériques ---

  /// Insère une nouvelle ligne dans la table spécifiée.
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
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  /// Met à jour une ligne dans une table en fonction de son ID.
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  /// Supprime une ligne d'une table en fonction de son ID.
  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
