import '../Entities/session.dart';
import 'database_helper.dart';

class SessionService {
  final dbHelper = DatabaseHelper();

  /// ➕ Ajoute une nouvelle session dans la base
  Future<int> insertSession(Session session) async {
    return await dbHelper.insert(
      Session.tableName,
      session.toMap(),
    );
  }

  /// 🔍 Récupère toutes les sessions
  Future<List<Session>> getAllSessions() async {
    final data = await dbHelper.queryAll(Session.tableName);
    return data.map((map) => Session.fromMap(map)).toList();
  }

  /// 🔍 Récupère une session par son ID
  Future<Session?> getSessionById(int id) async {
    final db = await dbHelper.database;
    final data = await db.query(
      Session.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isNotEmpty) {
      return Session.fromMap(data.first);
    }
    return null;
  }

  /// ✏️ Met à jour une session
  Future<int> updateSession(Session session) async {
    if (session.id == null) {
      throw Exception('Impossible de mettre à jour une session sans ID');
    }
    return await dbHelper.update(
      Session.tableName,
      session.toMap(),
      session.id!,
    );
  }

  /// ❌ Supprime une session
  Future<int> deleteSession(int id) async {
    return await dbHelper.delete(Session.tableName, id);
  }
}
