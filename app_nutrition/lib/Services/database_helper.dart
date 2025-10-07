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
  static const int _dbVersion = 3; // ✅ changée pour recréer la base

  // --- Accès à la base ---
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- Initialisation ---
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // --- Création des tables ---
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

    // Table recettes
    await db.execute('''
      CREATE TABLE recettes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT,
        calories REAL NOT NULL DEFAULT 0,
        repas_id INTEGER NOT NULL,
        FOREIGN KEY (repas_id) REFERENCES repas(id) ON DELETE CASCADE
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
      'CREATE INDEX idx_ingredients_recette ON ingredients(recette_id)',
    );
  }

  // --- Méthodes génériques ---

  /// Insère une nouvelle ligne dans la table spécifiée.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les lignes d'une table.
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
