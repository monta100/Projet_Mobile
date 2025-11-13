import '../Entities/exercice.dart';
import 'database_helper.dart';
import 'session_service.dart';

class ExerciceService {
  final dbHelper = DatabaseHelper();
  final SessionService _sessionService = SessionService();

  /// ➕ Ajoute un nouvel exercice dans la base
  Future<int> insertExercice(Exercice exercice) async {
    final data = exercice.toMap();
    // Associer l'utilisateur connecté si disponible
    try {
      final user = await _sessionService.getLoggedInUser();
      if (user?.id != null) {
        data['user_id'] = user!.id;
      }
    } catch (_) {}
    // Ensure programme_id is valid
    if (data['programme_id'] == 0) {
      data['programme_id'] = 1; // Use default programme
    }
    final nom = (data['nom'] as String?)?.trim() ?? '';
    final reps = data['repetitions'];
    if (nom.isEmpty) {
      throw Exception('Nom requis');
    }
    if (reps is int) {
      if (reps <= 0 || reps > 500) {
        throw Exception('Répétitions invalides (1-500)');
      }
    }
    return await dbHelper.insert(Exercice.tableName, data);
  }

  /// 🔍 Récupère tous les exercices
  Future<List<Exercice>> getAllExercices() async {
    final db = await dbHelper.database;
    final user = await _sessionService.getLoggedInUser();
    List<Map<String, dynamic>> rows;
    if (user?.id != null) {
      rows = await db.query(
        Exercice.tableName,
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [user!.id],
        orderBy: 'id DESC',
      );
    } else {
      rows = await db.query(Exercice.tableName, orderBy: 'id DESC');
    }
    return rows.map((map) => Exercice.fromMap(map)).toList();
  }

  /// 🔍 Récupère tous les exercices appartenant à un programme donné
  Future<List<Exercice>> getExercicesByProgramme(int programmeId) async {
    final db = await dbHelper.database;
    final user = await _sessionService.getLoggedInUser();
    final data = await db.query(
      Exercice.tableName,
      where: user?.id != null
          ? 'programme_id = ? AND (user_id = ? OR user_id IS NULL)'
          : 'programme_id = ?',
      whereArgs: user?.id != null ? [programmeId, user!.id] : [programmeId],
    );
    return data.map((map) => Exercice.fromMap(map)).toList();
  }

  /// ✏️ Met à jour un exercice
  Future<int> updateExercice(Exercice exercice) async {
    if (exercice.id == null) {
      throw Exception('Impossible de mettre à jour un exercice sans ID');
    }
    final data = exercice.toMap();
    final nom = (data['nom'] as String?)?.trim() ?? '';
    final reps = data['repetitions'];
    if (nom.isEmpty) {
      throw Exception('Nom requis');
    }
    if (reps is int) {
      if (reps <= 0 || reps > 500) {
        throw Exception('Répétitions invalides (1-500)');
      }
    }
    return await dbHelper.update(Exercice.tableName, data, exercice.id!);
  }

  /// ❌ Supprime un exercice
  Future<int> deleteExercice(int id) async {
    return await dbHelper.delete(Exercice.tableName, id);
  }
}
