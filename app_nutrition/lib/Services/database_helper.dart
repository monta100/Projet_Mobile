// Database helper using sqflite for persistent storage
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../Entites/utilisateur.dart';
import '../Entites/objectif.dart';
import '../Entites/message.dart';
import '../Entites/user_objective.dart';

class DatabaseHelper {
  // --- Singleton ---
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Configuration ---
  static const String _dbName = 'app_nutrition11.db';
  static const int _dbVersion = 11;
  // v7: finalise table recettes avec colonne utilisateur_id (rebuild propre)

  // Table names
  static const String tableUtilisateurs = 'utilisateurs';
  static const String tableObjectifs = 'objectifs';
  static const String tableMessages = 'messages';
  static const String tableUserObjectives = 'user_objectives';

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
      onOpen: (db) async {
        // Ensure schema consistency even when version didn't change (legacy installs)
        await _ensureSchema(db);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table utilisateurs (schéma aligné avec l'entité Utilisateur)
    await db.execute('''
      CREATE TABLE $tableUtilisateurs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        motDePasse TEXT NOT NULL,
        role TEXT NOT NULL,
        isVerified INTEGER NOT NULL DEFAULT 0,
        verificationCode TEXT,
        verificationExpiry TEXT,
        avatarPath TEXT,
        avatarColor TEXT,
        avatarInitials TEXT
      )
    ''');

    // Utilisateur de démonstration
    await db.insert(tableUtilisateurs, {
      'nom': 'User',
      'prenom': 'Demo',
      'email': 'demo@app.com',
      'motDePasse': '1234',
      'role': 'utilisateur',
      'isVerified': 1,
      'avatarInitials': 'UD',
    });

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

    // Table messages (chat)
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

    // Table user_objectives (objectifs détaillés)
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
        dateCreation TEXT NOT NULL,
        dateDebut TEXT NOT NULL,
        dateFin TEXT NOT NULL,
        progression REAL NOT NULL DEFAULT 0.0,
        estAtteint INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (utilisateurId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
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
        FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
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
        FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE SET NULL
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
    // Backwards-compat: if older DB used 'mot_de_passe' column, copy it to new 'motDePasse'
    try {
      final userCols = await db.rawQuery(
        "PRAGMA table_info($tableUtilisateurs)",
      );
      final hasNew = userCols.any(
        (c) => (c['name'] as String?) == 'motDePasse',
      );
      final hasOld = userCols.any(
        (c) => (c['name'] as String?) == 'mot_de_passe',
      );
      if (!hasNew && hasOld) {
        try {
          await db.execute(
            'ALTER TABLE $tableUtilisateurs ADD COLUMN motDePasse TEXT',
          );
        } catch (_) {}
        try {
          await db.execute(
            'UPDATE $tableUtilisateurs SET motDePasse = mot_de_passe',
          );
        } catch (_) {}
      }
    } catch (_) {}

    // v2: Ajout des colonnes avatarPath et avatarColor
    if (oldVersion < 2) {
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
    }

    // v3: Ajout de la colonne avatarInitials
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarInitials TEXT',
        );
      } catch (_) {}
    }

    // v4: Ajout de la colonne publie dans recettes
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE recettes ADD COLUMN publie INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }

    // v5: Création de la table messages si manquante
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableMessages (
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

    // v6: S'assurer que la table objectifs existe
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableObjectifs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            utilisateur_id INTEGER,
            type TEXT,
            valeurCible REAL,
            dateFixee TEXT,
            progression REAL,
            FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }

    // v7: Rebuild de la table recettes vers le schéma final + création user_objectives
    if (oldVersion < 7) {
      // Rebuild recettes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recettes_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          description TEXT,
          calories REAL NOT NULL DEFAULT 0,
          repas_id INTEGER NULL,
          publie INTEGER NOT NULL DEFAULT 0,
          utilisateur_id INTEGER NULL,
          FOREIGN KEY (repas_id) REFERENCES repas(id) ON DELETE CASCADE,
          FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE SET NULL
        )
      ''');
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
      await db.execute('DROP TABLE IF EXISTS recettes');
      await db.execute('ALTER TABLE recettes_new RENAME TO recettes');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recettes_repas ON recettes(repas_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recettes_user ON recettes(utilisateur_id)',
      );

      // Créer user_objectives si manquante
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableUserObjectives (
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
            dateCreation TEXT NOT NULL,
            dateDebut TEXT NOT NULL,
            dateFin TEXT NOT NULL,
            progression REAL NOT NULL DEFAULT 0.0,
            estAtteint INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            FOREIGN KEY (utilisateurId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }

    // v8: Suppression éventuelle de la colonne coachId de user_objectives
    if (oldVersion < 8) {
      try {
        final tableInfo = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableUserObjectives],
        );
        if (tableInfo.isNotEmpty) {
          final columns = await db.rawQuery(
            "PRAGMA table_info($tableUserObjectives)",
          );
          final hasCoachId = columns.any((col) => col['name'] == 'coachId');
          if (hasCoachId) {
            final oldData = await db.query(tableUserObjectives);
            await db.execute(
              'ALTER TABLE $tableUserObjectives RENAME TO ${tableUserObjectives}_old',
            );
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
                dateCreation TEXT NOT NULL,
                dateDebut TEXT NOT NULL,
                dateFin TEXT NOT NULL,
                progression REAL NOT NULL DEFAULT 0.0,
                estAtteint INTEGER NOT NULL DEFAULT 0,
                notes TEXT,
                FOREIGN KEY (utilisateurId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
              )
            ''');
            for (final row in oldData) {
              final newRow = Map<String, dynamic>.from(row);
              newRow.remove('coachId');
              newRow.remove('id');
              await db.insert(tableUserObjectives, newRow);
            }
            await db.execute('DROP TABLE IF EXISTS ${tableUserObjectives}_old');
          }
        }
      } catch (e) {
        // La migration est best-effort
        print('Migration user_objectives (version 8): $e');
      }
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
          dateCreation TEXT NOT NULL,
          dateDebut TEXT NOT NULL,
          dateFin TEXT NOT NULL,
          progression REAL NOT NULL DEFAULT 0.0,
          estAtteint INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          FOREIGN KEY (utilisateurId) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  /// S'assure que le schéma est cohérent même si la version ne change pas
  Future<void> _ensureSchema(Database db) async {
    try {
      // utilisateurs: assurer colonne motDePasse et copier depuis mot_de_passe si présent
      final userCols = await db.rawQuery(
        "PRAGMA table_info($tableUtilisateurs)",
      );
      final hasNew = userCols.any(
        (c) => (c['name'] as String?) == 'motDePasse',
      );
      final hasOld = userCols.any(
        (c) => (c['name'] as String?) == 'mot_de_passe',
      );
      if (!hasNew) {
        try {
          await db.execute(
            'ALTER TABLE $tableUtilisateurs ADD COLUMN motDePasse TEXT',
          );
        } catch (_) {}
      }
      if (hasOld) {
        try {
          await db.execute(
            'UPDATE $tableUtilisateurs SET motDePasse = COALESCE(motDePasse, mot_de_passe)',
          );
        } catch (_) {}
      }

      // Ensure avatar columns exist for UI (nullable)
      final hasAvatarPath = userCols.any(
        (c) => (c['name'] as String?) == 'avatarPath',
      );
      if (!hasAvatarPath) {
        try {
          await db.execute(
            'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarPath TEXT',
          );
        } catch (_) {}
      }
      final hasAvatarColor = userCols.any(
        (c) => (c['name'] as String?) == 'avatarColor',
      );
      if (!hasAvatarColor) {
        try {
          await db.execute(
            'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarColor TEXT',
          );
        } catch (_) {}
      }
      final hasAvatarInitials = userCols.any(
        (c) => (c['name'] as String?) == 'avatarInitials',
      );
      if (!hasAvatarInitials) {
        try {
          await db.execute(
            'ALTER TABLE $tableUtilisateurs ADD COLUMN avatarInitials TEXT',
          );
        } catch (_) {}
      }

      // Ensure verification columns exist (added in newer schema)
      final hasIsVerified = userCols.any(
        (c) => (c['name'] as String?) == 'isVerified',
      );
      if (!hasIsVerified) {
        try {
          await db.execute(
            'ALTER TABLE $tableUtilisateurs ADD COLUMN isVerified INTEGER NOT NULL DEFAULT 0',
          );
        } catch (_) {}
      }
      final hasVerificationCode = userCols.any(
        (c) => (c['name'] as String?) == 'verificationCode',
      );
      if (!hasVerificationCode) {
        try {
          await db.execute(
            'ALTER TABLE $tableUtilisateurs ADD COLUMN verificationCode TEXT',
          );
        } catch (_) {}
      }
      final hasVerificationExpiry = userCols.any(
        (c) => (c['name'] as String?) == 'verificationExpiry',
      );
      if (!hasVerificationExpiry) {
        try {
          await db.execute(
            'ALTER TABLE $tableUtilisateurs ADD COLUMN verificationExpiry TEXT',
          );
        } catch (_) {}
      }

      // S'assurer des tables optionnelles
      await _ensureUserObjectivesTable(db);
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableMessages (
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
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableObjectifs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          utilisateur_id INTEGER,
          type TEXT,
          valeurCible REAL,
          dateFixee TEXT,
          progression REAL,
          FOREIGN KEY (utilisateur_id) REFERENCES $tableUtilisateurs(id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      // ignore: avoid_print
      print('Schema guard failed: $e');
    }
  }

  /// Initialise quelques données de test (toujours disponibles)
  Future<void> initTestData() async {
    // Vérifier si les utilisateurs de test existent déjà
    final existingTestUser = await getUtilisateurByEmail(
      'jean.dupont@test.com',
    );

    int userId;

    if (existingTestUser == null) {
      // Créer un utilisateur de test
      final testUser = Utilisateur(
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean.dupont@test.com',
        motDePasse: 'Test123!',
        role: 'User',
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
    }
  }

  /// Efface toutes les données (utilitaire de développement)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableUserObjectives);
    await db.delete(tableObjectifs);
    await db.delete(tableUtilisateurs);
  }

  /// Force la recréation de la base de données (utilitaire de développement)
  Future<void> recreateDatabase() async {
    final db = await database;
    await db.close();
    _database = null;

    // Supprimer le fichier de base de données
    final dbPath = join(await getDatabasesPath(), _dbName);
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
}
