import 'package:sqflite/sqflite.dart';
import '../Entities/progression.dart';
import 'database_helper.dart';

class ProgressionService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertProgression(Progression progression) async {
    final db = await _dbHelper.database;
    return await db.insert(
      Progression.tableName,
      progression.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Progression>> getAllProgressions() async {
    final db = await _dbHelper.database;
    final data = await db.query(Progression.tableName, orderBy: 'id DESC');
    return data.map((e) => Progression.fromMap(e)).toList();
  }

  Future<int> deleteProgression(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      Progression.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ✅ Supprime toutes les progressions (ajouté pour ton erreur)
  Future<void> deleteAllProgressions() async {
    final db = await _dbHelper.database;
    await db.delete(Progression.tableName);
  }
}
