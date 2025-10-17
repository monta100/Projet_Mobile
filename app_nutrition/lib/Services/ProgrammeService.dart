import '../Entities/programme.dart';
import 'database_helper.dart';

class ProgrammeService {
  final dbHelper = DatabaseHelper();

  /// ➕ Ajoute un nouveau programme dans la base
  Future<int> insertProgramme(Programme programme) async {
    return await dbHelper.insert(
      Programme.tableName,
      programme.toMap(),
    );
  }

  /// 🔍 Récupère tous les programmes
  Future<List<Programme>> getAllProgrammes() async {
    final data = await dbHelper.queryAll(Programme.tableName);
    return data.map((map) => Programme.fromMap(map)).toList();
  }

  /// 🔍 Récupère un programme par son ID
  Future<Programme?> getProgrammeById(int id) async {
    final db = await dbHelper.database;
    final data = await db.query(
      Programme.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isNotEmpty) {
      return Programme.fromMap(data.first);
    }
    return null;
  }

  /// ✏️ Met à jour un programme
  Future<int> updateProgramme(Programme programme) async {
    if (programme.id == null) {
      throw Exception('Impossible de mettre à jour un programme sans ID');
    }
    return await dbHelper.update(
      Programme.tableName,
      programme.toMap(),
      programme.id!,
    );
  }

  /// ❌ Supprime un programme
  Future<int> deleteProgramme(int id) async {
    return await dbHelper.delete(Programme.tableName, id);
  }
}
