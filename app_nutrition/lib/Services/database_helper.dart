// Database helper using sqflite for persistent storage
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
  static const String _dbName = 'app_nutrition10.db';
  static const int _dbVersion = 9;
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
    );
    );
    
    // Vérifier et créer la table user_objectives si elle n'existe pas
    await _ensureUserObjectivesTable(db);
    
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table utilisateurs
    await db.execute('''
      CREATE TABLE utilisateurs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        mot_de_passe TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // ✅ Création d'un utilisateur par défaut
    await db.insert('utilisateurs', {
      'nom': 'User',
      'prenom': 'Demo',
      'email': 'demo@app.com',
      'mot_de_passe': '1234',
      'role': 'utilisateur',
    });

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
      oldVersion = 7;
    }
    if (oldVersion < 8) {
      // Remove coachId column from user_objectives table
      // SQLite doesn't support DROP COLUMN, so we need to recreate the table
      try {
        // Vérifier si la table existe
        final tableInfo = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableUserObjectives],
        );
        
        if (tableInfo.isNotEmpty) {
          // Vérifier si coachId existe dans la table
          final columns = await db.rawQuery("PRAGMA table_info($tableUserObjectives)");
          final hasCoachId = columns.any((col) => col['name'] == 'coachId');
          
          if (hasCoachId) {
            // Sauvegarder les données existantes
            final oldData = await db.query(tableUserObjectives);
            
            // Renommer l'ancienne table
            await db.execute('ALTER TABLE $tableUserObjectives RENAME TO ${tableUserObjectives}_old');
            
            // Créer la nouvelle table sans coachId
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
            
            // Copier les données de l'ancienne table vers la nouvelle (sans coachId)
            for (final row in oldData) {
              final newRow = Map<String, dynamic>.from(row);
              newRow.remove('coachId'); // Supprimer coachId si présent
              newRow.remove('id'); // Supprimer id pour permettre l'auto-increment
              
              await db.insert(tableUserObjectives, newRow);
            }
            
            // Supprimer l'ancienne table
            await db.execute('DROP TABLE IF EXISTS ${tableUserObjectives}_old');
          }
        }
      } catch (e) {
        // Si la table n'existe pas encore ou si une erreur survient, ce n'est pas grave
        // La table sera créée correctement par _onCreate ou _ensureUserObjectivesTable
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

  /// Initialise quelques données de test (toujours disponibles)
  Future<void> initTestData() async {
    // Vérifier si les utilisateurs de test existent déjà
    final existingTestUser = await getUtilisateurByEmail('jean.dupont@test.com');
    
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


}
