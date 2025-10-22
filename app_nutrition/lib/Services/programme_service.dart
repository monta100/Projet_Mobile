import 'package:sqflite/sqflite.dart';
import '../Entites/programme.dart';
import 'database_helper.dart';

/// 🌿 Service de gestion des programmes d'entraînement.
/// Gère toutes les opérations CRUD et les statistiques sur les programmes.
class ProgrammeService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// ➕ Ajoute un nouveau programme dans la base.
  /// Retourne l'ID auto-généré.
  Future<int> insertProgramme(Programme programme) async {
    final db = await _dbHelper.database;
    return await db.insert(
      Programme.tableName,
      programme.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🔍 Récupère tous les programmes enregistrés.
  Future<List<Programme>> getAllProgrammes() async {
    final db = await _dbHelper.database;
    final data = await db.query(
      Programme.tableName,
      orderBy: 'date_debut DESC',
    );
    return data.map((e) => Programme.fromMap(e)).toList();
  }

  /// 🔍 Récupère un programme par son ID.
  Future<Programme?> getProgrammeById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      Programme.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? Programme.fromMap(result.first) : null;
  }

  /// ✏️ Met à jour un programme existant.
  Future<int> updateProgramme(Programme programme) async {
    if (programme.id == null) {
      throw Exception('❌ Impossible de mettre à jour un programme sans ID.');
    }
    final db = await _dbHelper.database;
    return await db.update(
      Programme.tableName,
      programme.toMap(),
      where: 'id = ?',
      whereArgs: [programme.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ❌ Supprime un programme.
  Future<int> deleteProgramme(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      Programme.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 📊 Compte le nombre total de programmes.
  Future<int> getProgrammeCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM programmes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 🔎 Recherche des programmes par objectif.
  Future<List<Programme>> searchByObjectif(String keyword) async {
    final db = await _dbHelper.database;
    final data = await db.query(
      Programme.tableName,
      where: 'objectif LIKE ?',
      whereArgs: ['%$keyword%'],
    );
    return data.map((e) => Programme.fromMap(e)).toList();
  }

  /// 📅 Récupère les programmes actifs à une date donnée.
  Future<List<Programme>> getActiveProgrammes(String currentDate) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT * FROM programmes 
      WHERE date_debut <= ? AND date_fin >= ?
      ORDER BY date_debut ASC
    ''', [currentDate, currentDate]);
    return result.map((e) => Programme.fromMap(e)).toList();
  }
}
