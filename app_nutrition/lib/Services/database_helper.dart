import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // --- Singleton ---
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Configuration ---
  static const String _dbName = 'app_nutrition.db';
  static const int _dbVersion = 2; // 🔼 version augmentée (migration auto)

  // --- Accès à la base ---
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- Initialisation ---
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // --- Création des tables ---
  Future<void> _onCreate(Database db, int version) async {
    // 🟢 Table des programmes
    await db.execute('''
      CREATE TABLE programmes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        objectif TEXT NOT NULL,
        date_debut TEXT NOT NULL,
        date_fin TEXT NOT NULL
      )
    ''');

    // 🔵 Table des sessions
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_activite TEXT NOT NULL,
        duree INTEGER NOT NULL,
        intensite TEXT NOT NULL,
        calories INTEGER NOT NULL,
        date TEXT NOT NULL,
        programme_id INTEGER DEFAULT 0,
        FOREIGN KEY (programme_id) REFERENCES programmes (id) ON DELETE SET DEFAULT
      )
    ''');

    // 🟣 Table des exercices
    await db.execute('''
      CREATE TABLE exercices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT NOT NULL,
        repetitions INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        video_path TEXT NOT NULL,
        programme_id INTEGER NOT NULL,
        FOREIGN KEY (programme_id) REFERENCES programmes (id) ON DELETE CASCADE
      )
    ''');

    // 🟠 Table des progressions
    await db.execute('''
      CREATE TABLE progressions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        calories_brulees INTEGER NOT NULL,
        duree_totale INTEGER NOT NULL,
        commentaire TEXT NOT NULL,
        session_id INTEGER,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE SET NULL
      )
    ''');
  }

  // --- Mise à jour de la base (migration si version change) ---
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // ✅ Ajout des colonnes manquantes pour la table sessions
      await db.execute('ALTER TABLE sessions ADD COLUMN date TEXT DEFAULT ""');
      await db.execute('ALTER TABLE sessions ADD COLUMN programme_id INTEGER DEFAULT 0');
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

  /// ✏️ Met à jour une ligne dans une table par ID.
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ❌ Supprime une ligne par ID.
  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
