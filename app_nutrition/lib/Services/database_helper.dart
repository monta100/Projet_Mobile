// Database helper using sqflite for persistent storage
import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../Entites/utilisateur.dart';
import '../Entites/objectif.dart';
import '../Entites/rappel.dart';
import '../Entites/message.dart';

class DatabaseHelper {
  // --- Singleton ---
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // bumped to 5 to add messages table
  static const int _dbVersion = 5;
  static const String _dbName = 'app_nutrition.db';

  // Table names
  static const String tableUtilisateurs = 'utilisateurs';
  static const String tableObjectifs = 'objectifs';
  static const String tableRappels = 'rappels';
  static const String tableMessages = 'messages';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
  /// Initialise quelques données de test si la base est vide
  Future<void> initTestData() async {
    final users = await getAllUtilisateurs();
    if (users.isEmpty) {
      final testUser = Utilisateur(
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean.dupont@test.com',
        motDePasse: 'Test123!',
        role: 'Utilisateur',
        isVerified: true,
      );
      final userId = await insertUtilisateur(testUser);

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
    }
  }

  /// Efface toutes les données (utilitaire de développement)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableRappels);
    await db.delete(tableObjectifs);
    await db.delete(tableUtilisateurs);
  }
}
