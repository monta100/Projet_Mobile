// Database helper using sqflite for persistent storage
import 'dart:async';
import 'package:path/path.dart';
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
import '../Entites/expense.dart';

class DatabaseHelper {
  // --- Singleton ---
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Configuration ---
  static const String _dbName = 'nutrition_app_2025.db';
  static const int _dbVersion = 8; // 🔼 Augmenté pour migration (ajout colonne imageUrl dans recettes)

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
  // 🆕 Tables module activité physique
  static const String tableProgrammes = 'programmes';
  static const String tableSessions = 'sessions';
  static const String tableExercices = 'exercices';
  static const String tableProgressions = 'progressions';
  // 🆕 Tables module dépenses
  static const String tableUsers = 'users';
  static const String tableTrainingPlans = 'training_plans';
  static const String tableExpenses = 'expenses';

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
    // Table utilisateurs
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
        verificationExpiry TEXT,
        avatarPath TEXT,
        avatarColor TEXT,
        avatarInitials TEXT
      )
    ''');

    // Table objectifs
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

    // Table rappels
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

    // Table recettes
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

    // Table exercises
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

    // Table exercise_plans
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

    // Table plan_exercise_assignments
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

    // Table user_plan_assignments
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

    // Table user_objectives
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

    // Table progress_tracking
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

    // Table exercise_sessions
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

    // Index pour accélérer les recherches
    await db.execute('CREATE INDEX idx_repas_utilisateur ON repas(utilisateur_id)');
    await db.execute('CREATE INDEX idx_recettes_repas ON recettes(repas_id)');
    await db.execute('CREATE INDEX idx_recettes_user ON recettes(utilisateur_id)');
    await db.execute('CREATE INDEX idx_ingredients_recette ON ingredients(recette_id)');

    // 🆕 Tables module activité physique
    
    // 🟢 Table des programmes
    await db.execute('''
      CREATE TABLE $tableProgrammes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        objectif TEXT NOT NULL,
        date_debut TEXT NOT NULL,
        date_fin TEXT NOT NULL
      )
    ''');

    // 🔵 Table des sessions
    await db.execute('''
      CREATE TABLE $tableSessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_activite TEXT NOT NULL,
        duree INTEGER NOT NULL,
        intensite TEXT NOT NULL,
        calories INTEGER NOT NULL,
        date TEXT NOT NULL,
        programme_id INTEGER DEFAULT NULL,
        FOREIGN KEY (programme_id) REFERENCES $tableProgrammes (id) ON DELETE SET NULL
      )
    ''');

    // 🟣 Table des exercices
    await db.execute('''
      CREATE TABLE $tableExercices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT NOT NULL,
        repetitions INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        video_path TEXT NOT NULL,
        programme_id INTEGER NOT NULL,
        FOREIGN KEY (programme_id) REFERENCES $tableProgrammes (id) ON DELETE CASCADE
      )
    ''');

    // 🟠 Table des progressions
    await db.execute('''
      CREATE TABLE $tableProgressions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        calories_brulees INTEGER NOT NULL,
        duree_totale INTEGER NOT NULL,
        commentaire TEXT NOT NULL DEFAULT '',
        session_id INTEGER DEFAULT NULL,
        FOREIGN KEY (session_id) REFERENCES $tableSessions (id) ON DELETE SET NULL
      )
    ''');

    // Index pour le module activité physique
    await db.execute('CREATE INDEX idx_sessions_programme ON $tableSessions(programme_id)');
    await db.execute('CREATE INDEX idx_exercices_programme ON $tableExercices(programme_id)');
    await db.execute('CREATE INDEX idx_progressions_session ON $tableProgressions(session_id)');

    // 🆕 Tables module dépenses
    // Table des utilisateurs (pour le module dépenses)
    await db.execute('''
      CREATE TABLE $tableUsers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        current_weight REAL NOT NULL,
        target_weight REAL NOT NULL,
        height REAL,
        age INTEGER,
        gender TEXT,
        activity_level TEXT
      )
    ''');

    // Table des plans d'entraînement
    await db.execute('''
      CREATE TABLE $tableTrainingPlans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        duration_weeks INTEGER NOT NULL,
        training_frequency INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES $tableUsers(id)
      )
    ''');

    // Table des dépenses
    await db.execute('''
      CREATE TABLE $tableExpenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER,
        gym_subscription REAL NOT NULL,
        food_costs REAL NOT NULL,
        supplements_costs REAL,
        equipment_costs REAL,
        other_costs REAL,
        total_cost REAL NOT NULL,
        FOREIGN KEY(plan_id) REFERENCES $tableTrainingPlans(id)
      )
    ''');

    // Index pour le module dépenses
    await db.execute('CREATE INDEX idx_expenses_plan ON $tableExpenses(plan_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration pour les anciennes versions
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE recettes ADD COLUMN publie INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    }
    
    if (oldVersion < 7) {
      // Rebuild table recettes avec utilisateur_id ET imageUrl
      await db.execute('''
        CREATE TABLE recettes_new(
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
      
      try {
        await db.execute('''
          INSERT INTO recettes_new(id, nom, description, calories, repas_id, publie, imageUrl, utilisateur_id)
          SELECT id, nom, description, calories, repas_id, COALESCE(publie,0), imageUrl, utilisateur_id FROM recettes
        ''');
      } catch (_) {
        await db.execute('''
          INSERT INTO recettes_new(id, nom, description, calories, repas_id, publie, imageUrl, utilisateur_id)
          SELECT id, nom, description, calories, repas_id, COALESCE(publie,0), NULL, NULL FROM recettes
        ''');
      }
      
      await db.execute('DROP TABLE recettes');
      await db.execute('ALTER TABLE recettes_new RENAME TO recettes');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_recettes_repas ON recettes(repas_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_recettes_user ON recettes(utilisateur_id)');
    }

    // 🆕 Migration vers version 2 : ajout des tables module activité physique
    if (oldVersion < 2) {
      // 🟢 Table des programmes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableProgrammes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          objectif TEXT NOT NULL,
          date_debut TEXT NOT NULL,
          date_fin TEXT NOT NULL
        )
      ''');

      // 🔵 Table des sessions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableSessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type_activite TEXT NOT NULL,
          duree INTEGER NOT NULL,
          intensite TEXT NOT NULL,
          calories INTEGER NOT NULL,
          date TEXT NOT NULL,
          programme_id INTEGER DEFAULT NULL,
          FOREIGN KEY (programme_id) REFERENCES $tableProgrammes (id) ON DELETE SET NULL
        )
      ''');

      // 🟣 Table des exercices
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableExercices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          description TEXT NOT NULL,
          repetitions INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          video_path TEXT NOT NULL,
          programme_id INTEGER NOT NULL,
          FOREIGN KEY (programme_id) REFERENCES $tableProgrammes (id) ON DELETE CASCADE
        )
      ''');

      // 🟠 Table des progressions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableProgressions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          calories_brulees INTEGER NOT NULL,
          duree_totale INTEGER NOT NULL,
          commentaire TEXT NOT NULL DEFAULT '',
          session_id INTEGER DEFAULT NULL,
          FOREIGN KEY (session_id) REFERENCES $tableSessions (id) ON DELETE SET NULL
        )
      ''');

      // Index pour le module activité physique
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_programme ON $tableSessions(programme_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exercices_programme ON $tableExercices(programme_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_progressions_session ON $tableProgressions(session_id)');
    }

    // 🆕 Migration vers version 3 : fix contraintes FK pour accepter NULL
    if (oldVersion < 3) {
      // Recréer la table sessions avec programme_id nullable
      await db.execute('DROP TABLE IF EXISTS ${tableSessions}_old');
      await db.execute('ALTER TABLE $tableSessions RENAME TO ${tableSessions}_old');
      
      await db.execute('''
        CREATE TABLE $tableSessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type_activite TEXT NOT NULL,
          duree INTEGER NOT NULL,
          intensite TEXT NOT NULL,
          calories INTEGER NOT NULL,
          date TEXT NOT NULL,
          programme_id INTEGER DEFAULT NULL,
          FOREIGN KEY (programme_id) REFERENCES $tableProgrammes (id) ON DELETE SET NULL
        )
      ''');
      
      await db.execute('''
        INSERT INTO $tableSessions (id, type_activite, duree, intensite, calories, date, programme_id)
        SELECT id, type_activite, duree, intensite, calories, date, 
               CASE WHEN programme_id = 0 THEN NULL ELSE programme_id END
        FROM ${tableSessions}_old
      ''');
      
      await db.execute('DROP TABLE ${tableSessions}_old');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_programme ON $tableSessions(programme_id)');
    }

    // 🆕 Migration vers version 4 : ajout colonne imageUrl à recettes
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE recettes ADD COLUMN imageUrl TEXT');
        print('✅ Colonne imageUrl ajoutée à la table recettes');
      } catch (e) {
        print('⚠️ La colonne imageUrl existe déjà : $e');
      }
    }

    // 🆕 Migration vers version 5 : ajout tables module dépenses
    if (oldVersion < 5) {
      // Table des utilisateurs (pour le module dépenses)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          current_weight REAL NOT NULL,
          target_weight REAL NOT NULL,
          height REAL,
          age INTEGER,
          gender TEXT,
          activity_level TEXT
        )
      ''');

      // Table des plans d'entraînement
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableTrainingPlans(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          duration_weeks INTEGER NOT NULL,
          training_frequency INTEGER NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          FOREIGN KEY(user_id) REFERENCES $tableUsers(id)
        )
      ''');

      // Table des dépenses
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableExpenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plan_id INTEGER,
          gym_subscription REAL NOT NULL,
          food_costs REAL NOT NULL,
          supplements_costs REAL,
          equipment_costs REAL,
          other_costs REAL,
          total_cost REAL NOT NULL,
          FOREIGN KEY(plan_id) REFERENCES $tableTrainingPlans(id)
        )
      ''');

      // Index pour le module dépenses
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_plan ON $tableExpenses(plan_id)');
    }

    // 🆕 Migration vers version 8 : Ajout colonne imageUrl dans recettes si manquante
    if (oldVersion < 8) {
      try {
        // Vérifier si la colonne imageUrl existe déjà
        final result = await db.rawQuery('PRAGMA table_info(recettes)');
        final hasImageUrl = result.any((column) => column['name'] == 'imageUrl');
        
        if (!hasImageUrl) {
          // Ajouter la colonne imageUrl si elle n'existe pas
          await db.execute('ALTER TABLE recettes ADD COLUMN imageUrl TEXT');
          print('✅ Colonne imageUrl ajoutée à la table recettes');
        } else {
          print('ℹ️ Colonne imageUrl existe déjà dans la table recettes');
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'ajout de la colonne imageUrl: $e');
      }
    }
  }

  // --- Méthodes génériques ---

  /// ➕ Insère une nouvelle ligne dans la table spécifiée.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🔍 Récupère toutes les lignes d'une table.
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

  // ===== Utilisateurs =====
  Future<int> insertUtilisateur(Utilisateur user) async {
    final db = await database;
    return await db.insert(tableUtilisateurs, user.toMap());
  }

  Future<Utilisateur?> getUtilisateurByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUtilisateurs,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) return Utilisateur.fromMap(maps.first);
    return null;
  }

  Future<Utilisateur?> getUtilisateurById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUtilisateurs,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Utilisateur.fromMap(maps.first);
    return null;
  }

  Future<List<Utilisateur>> getAllUtilisateurs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableUtilisateurs);
    return List.generate(maps.length, (i) => Utilisateur.fromMap(maps[i]));
  }

  Future<List<Utilisateur>> getClientsByCoach(int coachId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUtilisateurs,
      where: 'coach_id = ?',
      whereArgs: [coachId],
    );
    return List.generate(maps.length, (i) => Utilisateur.fromMap(maps[i]));
  }

  Future<int> updateUtilisateur(Utilisateur user) async {
    final db = await database;
    return await db.update(
      tableUtilisateurs,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUtilisateur(int id) async {
    final db = await database;
    return await db.delete(tableUtilisateurs, where: 'id = ?', whereArgs: [id]);
  }

  // ===== Objectifs =====
  Future<int> insertObjectif(Objectif objectif) async {
    final db = await database;
    return await db.insert(tableObjectifs, objectif.toMap());
  }

  Future<Objectif?> getObjectifById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableObjectifs,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Objectif.fromMap(maps.first);
    return null;
  }

  Future<List<Objectif>> getAllObjectifs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableObjectifs);
    return List.generate(maps.length, (i) => Objectif.fromMap(maps[i]));
  }

  Future<List<Objectif>> getObjectifsByUtilisateur(int utilisateurId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableObjectifs,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );
    return List.generate(maps.length, (i) => Objectif.fromMap(maps[i]));
  }

  Future<List<Objectif>> getObjectifsByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableObjectifs,
      where: 'type = ?',
      whereArgs: [type],
    );
    return List.generate(maps.length, (i) => Objectif.fromMap(maps[i]));
  }

  Future<int> updateObjectif(Objectif objectif) async {
    final db = await database;
    return await db.update(
      tableObjectifs,
      objectif.toMap(),
      where: 'id = ?',
      whereArgs: [objectif.id],
    );
  }

  Future<int> deleteObjectif(int id) async {
    final db = await database;
    return await db.delete(tableObjectifs, where: 'id = ?', whereArgs: [id]);
  }

  // ===== Rappels =====
  Future<int> insertRappel(Rappel rappel) async {
    final db = await database;
    return await db.insert(tableRappels, rappel.toMap());
  }

  Future<Rappel?> getRappelById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableRappels,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Rappel.fromMap(maps.first);
    return null;
  }

  Future<List<Rappel>> getAllRappels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableRappels);
    return List.generate(maps.length, (i) => Rappel.fromMap(maps[i]));
  }

  Future<List<Rappel>> getRappelsByUtilisateur(int utilisateurId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableRappels,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );
    return List.generate(maps.length, (i) => Rappel.fromMap(maps[i]));
  }

  Future<List<Rappel>> getRappelsNonLus() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableRappels,
      where: 'statut = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Rappel.fromMap(maps[i]));
  }

  Future<List<Rappel>> getRappelsDus() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      tableRappels,
      where: 'date <= ? AND statut = 0',
      whereArgs: [now],
    );
    return List.generate(maps.length, (i) => Rappel.fromMap(maps[i]));
  }

  Future<int> updateRappel(Rappel rappel) async {
    final db = await database;
    return await db.update(
      tableRappels,
      rappel.toMap(),
      where: 'id = ?',
      whereArgs: [rappel.id],
    );
  }

  Future<int> deleteRappel(int id) async {
    final db = await database;
    return await db.delete(tableRappels, where: 'id = ?', whereArgs: [id]);
  }

  // ===== Messages =====
  Future<int> insertMessage(Message message) async {
    final db = await database;
    return await db.insert(tableMessages, message.toMap());
  }

  Future<List<Message>> getMessagesBetween(int user1Id, int user2Id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableMessages,
      where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [user1Id, user2Id, user2Id, user1Id],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  Future<List<Message>> getMessagesForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableMessages,
      where: 'receiver_id = ? OR sender_id = ?',
      whereArgs: [userId, userId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
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

  // ===== Exercises =====
  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    return await db.insert(tableExercises, exercise.toMap());
  }

  Future<Exercise?> getExerciseById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExercises,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Exercise.fromMap(maps.first);
    return null;
  }

  Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExercises,
      where: 'is_active = 1',
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<List<Exercise>> getExercisesByNiveau(String niveau) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExercises,
      where: 'niveau = ? AND is_active = 1',
      whereArgs: [niveau],
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  // ===== Exercise Plans =====
  Future<int> insertExercisePlan(ExercisePlan plan) async {
    final db = await database;
    return await db.insert(tableExercisePlans, plan.toMap());
  }

  Future<ExercisePlan?> getExercisePlanById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExercisePlans,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return ExercisePlan.fromMap(maps.first);
    return null;
  }

  Future<List<ExercisePlan>> getExercisePlansByCoach(int coachId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExercisePlans,
      where: 'coach_id = ?',
      whereArgs: [coachId],
    );
    return List.generate(maps.length, (i) => ExercisePlan.fromMap(maps[i]));
  }

  Future<int> updateExercisePlan(ExercisePlan plan) async {
    final db = await database;
    return await db.update(
      tableExercisePlans,
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deleteExercisePlan(int id) async {
    final db = await database;
    return await db.delete(tableExercisePlans, where: 'id = ?', whereArgs: [id]);
  }

  // ===== Plan Exercise Assignments =====
  Future<int> insertPlanExerciseAssignment(PlanExerciseAssignment assignment) async {
    final db = await database;
    return await db.insert(tablePlanExerciseAssignments, assignment.toMap());
  }

  Future<List<PlanExerciseAssignment>> getPlanExerciseAssignmentsByPlan(int planId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePlanExerciseAssignments,
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'ordre ASC',
    );
    return List.generate(maps.length, (i) => PlanExerciseAssignment.fromMap(maps[i]));
  }

  // ===== User Plan Assignments =====
  Future<int> insertUserPlanAssignment(UserPlanAssignment assignment) async {
    final db = await database;
    return await db.insert(tableUserPlanAssignments, assignment.toMap());
  }

  Future<List<UserPlanAssignment>> getUserPlanAssignmentsByUser(int utilisateurId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUserPlanAssignments,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );
    return List.generate(maps.length, (i) => UserPlanAssignment.fromMap(maps[i]));
  }

  Future<List<UserPlanAssignment>> getUserPlanAssignmentsByPlan(int planId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUserPlanAssignments,
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    return List.generate(maps.length, (i) => UserPlanAssignment.fromMap(maps[i]));
  }

  Future<List<UserPlanAssignment>> getUserPlanAssignmentsByCoach(int coachId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT upa.*
      FROM $tableUserPlanAssignments upa
      JOIN $tableExercisePlans ep ON upa.plan_id = ep.id
      WHERE ep.coach_id = ?
    ''', [coachId]);
    return List.generate(maps.length, (i) => UserPlanAssignment.fromMap(maps[i]));
  }

  Future<int> updateUserPlanAssignment(UserPlanAssignment assignment) async {
    final db = await database;
    return await db.update(
      tableUserPlanAssignments,
      assignment.toMap(),
      where: 'id = ?',
      whereArgs: [assignment.id],
    );
  }

  // ===== Exercise Sessions =====
  Future<int> insertExerciseSession(ExerciseSession session) async {
    final db = await database;
    return await db.insert(tableExerciseSessions, session.toMap());
  }

  Future<List<ExerciseSession>> getExerciseSessionsByUser(int utilisateurId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExerciseSessions,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
      orderBy: 'date_debut DESC',
    );
    return List.generate(maps.length, (i) => ExerciseSession.fromMap(maps[i]));
  }

  Future<List<ExerciseSession>> getExerciseSessionsByPlan(int planId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExerciseSessions,
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    return List.generate(maps.length, (i) => ExerciseSession.fromMap(maps[i]));
  }

  Future<List<ExerciseSession>> getExerciseSessionsByUserAndPlan(int utilisateurId, int planId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExerciseSessions,
      where: 'utilisateur_id = ? AND plan_id = ?',
      whereArgs: [utilisateurId, planId],
    );
    return List.generate(maps.length, (i) => ExerciseSession.fromMap(maps[i]));
  }

  Future<int> updateExerciseSession(ExerciseSession session) async {
    final db = await database;
    return await db.update(
      tableExerciseSessions,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // ===== User Objectives =====
  Future<int> insertUserObjective(UserObjective objective) async {
    final db = await database;
    return await db.insert(tableUserObjectives, objective.toMap());
  }

  Future<List<UserObjective>> getUserObjectives(int utilisateurId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUserObjectives,
      where: 'utilisateurId = ?',
      whereArgs: [utilisateurId],
    );
    return List.generate(maps.length, (i) => UserObjective.fromMap(maps[i]));
  }

  Future<List<UserObjective>> getUserObjectivesByCoach(int coachId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUserObjectives,
      where: 'coachId = ?',
      whereArgs: [coachId],
    );
    return List.generate(maps.length, (i) => UserObjective.fromMap(maps[i]));
  }

  // ===== Test Data Initialization =====
  Future<void> initTestData() async {
    final allUsers = await getAllUtilisateurs();
    if (allUsers.isNotEmpty) return; // Already initialized

    // Create test coach
    final coach = Utilisateur(
      nom: 'Dupont',
      prenom: 'Coach',
      email: 'coach@test.com',
      motDePasse: 'test123',
      role: 'coach',
      isVerified: true,
      verificationCode: '',
      verificationExpiry: DateTime.now(),
    );
    await insertUtilisateur(coach);

    // Create test user
    final user = Utilisateur(
      nom: 'Martin',
      prenom: 'User',
      email: 'user@test.com',
      motDePasse: 'test123',
      role: 'utilisateur',
      isVerified: true,
      verificationCode: '',
      verificationExpiry: DateTime.now(),
    );
    await insertUtilisateur(user);
  }

  // ===== Module Dépenses - Users =====
  Future<int> createUser(Map<String, dynamic> userData) async {
    final db = await database;
    return await db.insert(tableUsers, userData);
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query(tableUsers);
  }

  Future<int> updateUser(int id, Map<String, dynamic> userData) async {
    final db = await database;
    return await db.update(
      tableUsers,
      userData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(tableUsers, where: 'id = ?', whereArgs: [id]);
  }

  // ===== Module Dépenses - Training Plans =====
  Future<int> createTrainingPlan(Map<String, dynamic> planData) async {
    final db = await database;
    return await db.insert(tableTrainingPlans, planData);
  }

  Future<Map<String, dynamic>?> getTrainingPlanById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTrainingPlans,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getTrainingPlansByUser(int userId) async {
    final db = await database;
    return await db.query(
      tableTrainingPlans,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTrainingPlans() async {
    final db = await database;
    return await db.query(tableTrainingPlans);
  }

  Future<int> updateTrainingPlan(int id, Map<String, dynamic> planData) async {
    final db = await database;
    return await db.update(
      tableTrainingPlans,
      planData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTrainingPlan(int id) async {
    final db = await database;
    return await db.delete(tableTrainingPlans, where: 'id = ?', whereArgs: [id]);
  }

  // ===== Module Dépenses - Expenses =====
  
  /// Calcule et enregistre les dépenses pour un plan d'entraînement
  Future<int> calculateAndSaveExpenses(int planId, double gymCost, double dailyFoodBudget) async {
    final db = await database;
    
    // Récupérer le plan pour calculer les coûts totaux
    final plan = await getTrainingPlanById(planId);
    if (plan == null) {
      throw Exception('Training plan not found');
    }
    
    final durationWeeks = plan['duration_weeks'] as int;
    final totalDays = durationWeeks * 7;
    
    // Calculer les coûts
    final totalGymCost = (durationWeeks / 4) * gymCost;
    final totalFoodCost = totalDays * dailyFoodBudget;
    final totalCost = totalGymCost + totalFoodCost;
    
    // Créer l'objet Expense
    final expense = Expense(
      planId: planId,
      gymSubscription: totalGymCost,
      foodCosts: totalFoodCost,
      supplementsCosts: 0,
      equipmentCosts: 0,
      otherCosts: 0,
      totalCost: totalCost,
    );
    
    return await db.insert(tableExpenses, expense.toMap());
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(tableExpenses, expense.toMap());
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Expense.fromMap(maps.first);
    return null;
  }

  Future<List<Expense>> getExpensesByPlan(int planId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExpenses,
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableExpenses);
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      tableExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(tableExpenses, where: 'id = ?', whereArgs: [id]);
  }

  /// Calcule le total des dépenses pour un utilisateur
  Future<double> getTotalExpensesByUser(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(e.total_cost) as total
      FROM $tableExpenses e
      JOIN $tableTrainingPlans p ON e.plan_id = p.id
      WHERE p.user_id = ?
    ''', [userId]);
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Récupère toutes les dépenses avec les détails du plan associé
  Future<List<Map<String, dynamic>>> getExpensesWithPlanDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        e.*,
        p.duration_weeks,
        p.training_frequency,
        p.start_date,
        p.end_date,
        u.current_weight,
        u.target_weight
      FROM $tableExpenses e
      JOIN $tableTrainingPlans p ON e.plan_id = p.id
      JOIN $tableUsers u ON p.user_id = u.id
      ORDER BY p.start_date DESC
    ''');
  }

  // ===== Module Activité Physique - Sessions de test =====
  
  /// Créer des sessions d'exercice de test pour l'utilisateur 3
  Future<void> createTestSessionsForUser3() async {
    try {
      final db = await database;
      
      // Vérifier si des sessions existent déjà pour l'utilisateur 3
      final existing = await db.query(
        tableExerciseSessions,
        where: 'utilisateur_id = ?',
        whereArgs: [3],
      );
      
      if (existing.isEmpty) {
        print('📝 Création de sessions d\'exercice de test pour utilisateur 3...');
        
        // Créer 3 sessions d'exercice de test
        await db.insert(tableExerciseSessions, {
          'utilisateur_id': 3,
          'plan_id': null,
          'exercise_id': null,
          'date_debut': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'date_fin': DateTime.now().subtract(const Duration(days: 2, hours: -1)).toIso8601String(),
          'duree_reelle': 60,
          'calories_brulees': 350,
          'nombre_series_completees': 3,
          'repetitions_totales': 45,
          'notes_utilisateur': 'Session de test 1',
          'est_terminee': 1,
        });
        
        await db.insert(tableExerciseSessions, {
          'utilisateur_id': 3,
          'plan_id': null,
          'exercise_id': null,
          'date_debut': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'date_fin': DateTime.now().subtract(const Duration(days: 1, hours: -1)).toIso8601String(),
          'duree_reelle': 45,
          'calories_brulees': 280,
          'nombre_series_completees': 3,
          'repetitions_totales': 36,
          'notes_utilisateur': 'Session de test 2',
          'est_terminee': 1,
        });
        
        await db.insert(tableExerciseSessions, {
          'utilisateur_id': 3,
          'plan_id': null,
          'exercise_id': null,
          'date_debut': DateTime.now().toIso8601String(),
          'date_fin': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'duree_reelle': 55,
          'calories_brulees': 320,
          'nombre_series_completees': 4,
          'repetitions_totales': 48,
          'notes_utilisateur': 'Session de test 3',
          'est_terminee': 1,
        });
        
        print('✅ 3 sessions d\'exercice de test créées (Total: 3 sessions, 950 calories brûlées)');
      } else {
        print('ℹ️ L\'utilisateur 3 a déjà ${existing.length} sessions d\'exercice');
      }
    } catch (e) {
      print('❌ Erreur création sessions test: $e');
    }
  }
  
  // ===== Module Nutrition - Calories =====
  
  /// Créer des repas de test pour l'utilisateur 3
  Future<void> createTestMealsForUser3() async {
    try {
      final db = await database;
      
      // Vérifier si des repas existent déjà pour l'utilisateur 3
      final existing = await db.query(
        'repas',
        where: 'utilisateur_id = ?',
        whereArgs: [3],
      );
      
      if (existing.isEmpty) {
        print('📝 Création de repas de test pour utilisateur 3...');
        
        // Ajouter quelques repas de test
        await db.insert('repas', {
          'type': 'Petit-déjeuner',
          'date': DateTime.now().toIso8601String(),
          'nom': 'Omelette et toast',
          'calories_totales': 450.0,
          'utilisateur_id': 3,
        });
        
        await db.insert('repas', {
          'type': 'Déjeuner',
          'date': DateTime.now().toIso8601String(),
          'nom': 'Poulet grillé et légumes',
          'calories_totales': 650.0,
          'utilisateur_id': 3,
        });
        
        await db.insert('repas', {
          'type': 'Dîner',
          'date': DateTime.now().toIso8601String(),
          'nom': 'Salade de quinoa',
          'calories_totales': 550.0,
          'utilisateur_id': 3,
        });
        
        print('✅ 3 repas de test créés (Total: 1650 calories)');
      } else {
        print('ℹ️ L\'utilisateur 3 a déjà ${existing.length} repas');
      }
    } catch (e) {
      print('❌ Erreur création repas test: $e');
    }
  }
  
  /// Récupère le total des calories consommées pour un utilisateur
  Future<int> getTotalNutritionCalories(int utilisateurId) async {
    try {
      final db = await database;
      
      // D'abord, compter le nombre de repas
      final countResult = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM repas
        WHERE utilisateur_id = ?
      ''', [utilisateurId]);
      
      print('🍽️ Nombre de repas pour utilisateur $utilisateurId: ${countResult.first['count']}');
      
      // Ensuite, récupérer le total des calories
      final result = await db.rawQuery('''
        SELECT SUM(calories_totales) as total
        FROM repas
        WHERE utilisateur_id = ?
      ''', [utilisateurId]);
      
      print('🔥 Requête calories result: $result');
      
      if (result.isNotEmpty && result.first['total'] != null) {
        final total = (result.first['total'] as num).toInt();
        print('✅ Total calories nutrition: $total');
        return total;
      }
      
      print('⚠️ Aucune calorie trouvée, retour 0');
      return 0;
    } catch (e) {
      print('❌ Erreur getTotalNutritionCalories: $e');
      return 0;
    }
  }

}
