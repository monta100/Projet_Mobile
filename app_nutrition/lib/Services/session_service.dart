import 'package:sqflite/sqflite.dart';
import '../Entities/session.dart';
import 'database_helper.dart';

/// 🌿 Service de gestion des séances d’entraînement.
/// Permet d’ajouter, lire, modifier et supprimer des séances dans la base SQLite.
class SessionService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// ➕ Ajoute une nouvelle séance dans la base de données.
  /// Retourne l’ID auto-généré de la séance.
  Future<int> insertSession(Session session) async {
    final db = await _dbHelper.database;
    return await db.insert(
      Session.tableName,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🔍 Récupère toutes les séances enregistrées dans la base.
  /// Retourne une liste d’objets [Session].
  Future<List<Session>> getAllSessions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> data = await db.query(
      Session.tableName,
      orderBy: 'id DESC', // 🔽 Affiche les plus récentes d’abord
    );
    return data.map((map) => Session.fromMap(map)).toList();
  }

  /// 🔍 Récupère une séance spécifique par son [id].
  /// Retourne un objet [Session] ou `null` si non trouvé.
  Future<Session?> getSessionById(int id) async {
    final db = await _dbHelper.database;
    final data = await db.query(
      Session.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return data.isNotEmpty ? Session.fromMap(data.first) : null;
  }

  /// ✏️ Met à jour une séance existante.
  /// Lève une exception si l’ID est manquant.
  Future<int> updateSession(Session session) async {
    if (session.id == null) {
      throw Exception('❌ Impossible de mettre à jour une session sans ID.');
    }

    final db = await _dbHelper.database;
    return await db.update(
      Session.tableName,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ❌ Supprime une séance de la base.
  /// Retourne le nombre de lignes supprimées (1 si succès).
  Future<int> deleteSession(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      Session.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 📊 Calcule la somme totale de calories brûlées sur toutes les séances.
  Future<int> getTotalCalories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(calories) as total FROM ${Session.tableName}',
    );
    return result.first['total'] == null ? 0 : result.first['total'] as int;
  }

  /// ⏱️ Calcule la durée totale d’entraînement sur toutes les séances.
  Future<int> getTotalDuree() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(duree) as total FROM ${Session.tableName}',
    );
    return result.first['total'] == null ? 0 : result.first['total'] as int;
  }

  /// 📆 Récupère les séances d’un type spécifique (ex: “cardio”, “musculation”)
  Future<List<Session>> getSessionsByType(String type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> data = await db.query(
      Session.tableName,
      where: 'type_activite LIKE ?',
      whereArgs: ['%$type%'],
    );
    return data.map((map) => Session.fromMap(map)).toList();
  }
}
