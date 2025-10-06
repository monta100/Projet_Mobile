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
  static const int _dbVersion = 1;

  // --- Accès à la base ---
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- Initialisation ---
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  // --- Création des tables ---
  Future<void> _onCreate(Database db, int version) async {
    // 🟡 Chaque membre ajoutera ici sa table :
    // Exemple plus tard :
    // await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT)');
  }

  
  // --- Méthodes génériques ---

  /// Insère une nouvelle ligne dans la table spécifiée.
  /// Retourne l'ID de la nouvelle ligne.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  /// Récupère toutes les lignes d'une table.
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  /// Met à jour une ligne dans une table en fonction de son ID.
  /// Retourne le nombre de lignes affectées.
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Supprime une ligne d'une table en fonction de son ID.
  /// Retourne le nombre de lignes supprimées.
  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
}
