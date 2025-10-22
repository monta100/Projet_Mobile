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
    // Table des utilisateurs
    await db.execute('''
      CREATE TABLE users(
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
      CREATE TABLE training_plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        duration_weeks INTEGER NOT NULL,
        training_frequency INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    // Table des coûts
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER,
        gym_subscription REAL NOT NULL,
        food_costs REAL NOT NULL,
        supplements_costs REAL,
        equipment_costs REAL,
        other_costs REAL,
        total_cost REAL NOT NULL,
        FOREIGN KEY(plan_id) REFERENCES training_plans(id)
      )
    ''');
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

  // --- Méthodes spécifiques pour la gestion des utilisateurs ---
  
  /// Crée un nouveau profil utilisateur
  Future<int> createUser(Map<String, dynamic> userData) async {
    return await insert('users', userData);
  }

  /// Récupère un utilisateur par son ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  // --- Méthodes pour la gestion des plans d'entraînement ---

  /// Crée un nouveau plan d'entraînement
  Future<int> createTrainingPlan(Map<String, dynamic> planData) async {
    return await insert('training_plans', planData);
  }

  /// Récupère les plans d'entraînement d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserTrainingPlans(int userId) async {
    final db = await database;
    return await db.query(
      'training_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // --- Méthodes pour la gestion des coûts ---

  /// Calcule et enregistre les coûts pour un plan d'entraînement
  Future<int> calculateAndSaveExpenses(int planId, double gymCost, double foodCostPerDay) async {
    final plan = (await database).query(
      'training_plans',
      where: 'id = ?',
      whereArgs: [planId],
    ).then((value) => value.first);

    // Calcul des coûts sur la durée du plan
    final durationWeeks = (await plan)['duration_weeks'] as int;
    final totalDays = durationWeeks * 7;
    
    final expenses = {
      'plan_id': planId,
      'gym_subscription': gymCost * (durationWeeks / 4), // Coût mensuel converti en durée du plan
      'food_costs': foodCostPerDay * totalDays,
      'supplements_costs': 0.0, // À personnaliser selon les besoins
      'equipment_costs': 0.0, // À personnaliser selon les besoins
      'other_costs': 0.0, // À personnaliser selon les besoins
    };
    
    // Calcul du coût total
    expenses['total_cost'] = expenses.values
        .where((value) => value is num)
        .reduce((sum, value) => sum + value);

    return await insert('expenses', expenses);
  }

  /// Récupère les dépenses pour un plan d'entraînement
  Future<Map<String, dynamic>?> getPlanExpenses(int planId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }
}
