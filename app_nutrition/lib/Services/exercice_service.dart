import '../Entities/exercice.dart';
import 'database_helper.dart';

class ExerciceService {
  final dbHelper = DatabaseHelper();

  /// ➕ Ajoute un nouvel exercice dans la base
  Future<int> insertExercice(Exercice exercice) async {
    return await dbHelper.insert(
      Exercice.tableName,
      exercice.toMap(),
    );
  }

  /// 🔍 Récupère tous les exercices
  Future<List<Exercice>> getAllExercices() async {
    final data = await dbHelper.queryAll(Exercice.tableName);
    return data.map((map) => Exercice.fromMap(map)).toList();
  }

  /// 🔍 Récupère tous les exercices appartenant à un programme donné
  Future<List<Exercice>> getExercicesByProgramme(int programmeId) async {
    final db = await dbHelper.database;
    final data = await db.query(
      Exercice.tableName,
      where: 'programme_id = ?',
      whereArgs: [programmeId],
    );
    return data.map((map) => Exercice.fromMap(map)).toList();
  }

  /// ✏️ Met à jour un exercice
  Future<int> updateExercice(Exercice exercice) async {
    if (exercice.id == null) {
      throw Exception('Impossible de mettre à jour un exercice sans ID');
    }
    return await dbHelper.update(
      Exercice.tableName,
      exercice.toMap(),
      exercice.id!,
    );
  }

  /// ❌ Supprime un exercice
  Future<int> deleteExercice(int id) async {
    return await dbHelper.delete(Exercice.tableName, id);
  }
}
