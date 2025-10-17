import '../Entities/progression.dart';
import 'database_helper.dart';

class ProgressionService {
  final dbHelper = DatabaseHelper();

  /// ➕ Ajoute une nouvelle progression dans la base
  Future<int> insertProgression(Progression progression) async {
    return await dbHelper.insert(
      Progression.tableName,
      progression.toMap(),
    );
  }

  /// 🔍 Récupère toutes les progressions
  Future<List<Progression>> getAllProgressions() async {
    final data = await dbHelper.queryAll(Progression.tableName);
    return data.map((map) => Progression.fromMap(map)).toList();
  }

  /// 🔍 Récupère les progressions associées à une session donnée
  Future<List<Progression>> getProgressionsBySession(int sessionId) async {
    final db = await dbHelper.database;
    final data = await db.query(
      Progression.tableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return data.map((map) => Progression.fromMap(map)).toList();
  }

  /// ✏️ Met à jour une progression
  Future<int> updateProgression(Progression progression) async {
    if (progression.id == null) {
      throw Exception('Impossible de mettre à jour une progression sans ID');
    }
    return await dbHelper.update(
      Progression.tableName,
      progression.toMap(),
      progression.id!,
    );
  }

  /// ❌ Supprime une progression
  Future<int> deleteProgression(int id) async {
    return await dbHelper.delete(Progression.tableName, id);
  }
}
