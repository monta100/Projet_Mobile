import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../Entites/utilisateur.dart';
import '../Entities/session.dart';
import 'database_helper.dart';

class SessionService {
  static const _kUserId = 'session_user_id';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Méthodes de gestion de session utilisateur
  Future<void> persistUser(Utilisateur user) async {
    if (user.id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kUserId, user.id!);
  }

  Future<Utilisateur?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kUserId);
    if (id == null) return null;
    try {
      final user = await _dbHelper.getUtilisateurById(id);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
  }

  Future<bool> isLoggedIn() async => (await getLoggedInUser()) != null;

  // Méthodes de gestion des séances d'entraînement
  Future<int> insertSession(Session session) async {
    final db = await _dbHelper.database;
    var data = session.toMap();

    // Associer l'utilisateur connecté si disponible
    try {
      final user = await getLoggedInUser();
      if (user?.id != null) {
        data['user_id'] = user!.id;
      }
    } catch (_) {}

    // Ensure programme_id is valid
    if (data['programme_id'] == 0) {
      data['programme_id'] = 1; // Use default programme
    }

    // Validation minimale côté service (défense en profondeur)
    final type = (data['type_activite'] as String?)?.trim() ?? '';
    final duree = data['duree'];
    final intensite = (data['intensite'] as String?)?.trim() ?? '';
    final dateStr = (data['date'] as String?)?.trim() ?? '';
    if (type.isEmpty || intensite.isEmpty) {
      throw Exception('Type et intensité requis');
    }
    if (duree is int) {
      if (duree <= 0 || duree > 600) {
        throw Exception('Durée invalide (1-600)');
      }
    }
    if (dateStr.isEmpty) {
      throw Exception('Date requise');
    }
    try {
      DateTime.parse(dateStr);
    } catch (_) {
      throw Exception('Format de date invalide (attendu yyyy-MM-dd)');
    }
    // Calories peuvent être calculées, mais on évite valeurs négatives
    final calories = data['calories'];
    if (calories is int && calories < 0) {
      data['calories'] = 0;
    }

    return await db.insert(
      Session.tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Session>> getAllSessions() async {
    final db = await _dbHelper.database;
    final user = await getLoggedInUser();
    List<Map<String, dynamic>> rows;
    if (user?.id != null) {
      rows = await db.query(
        Session.tableName,
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [user!.id],
        orderBy: 'id DESC',
      );
    } else {
      rows = await db.query(Session.tableName, orderBy: 'id DESC');
    }
    return rows.map((map) => Session.fromMap(map)).toList();
  }

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

  Future<int> updateSession(Session session) async {
    if (session.id == null) {
      throw Exception('Impossible de mettre à jour une session sans ID.');
    }

    final db = await _dbHelper.database;
    final data = session.toMap();
    final type = (data['type_activite'] as String?)?.trim() ?? '';
    final duree = data['duree'];
    final intensite = (data['intensite'] as String?)?.trim() ?? '';
    final dateStr = (data['date'] as String?)?.trim() ?? '';
    if (type.isEmpty || intensite.isEmpty) {
      throw Exception('Type et intensité requis');
    }
    if (duree is int) {
      if (duree <= 0 || duree > 600) {
        throw Exception('Durée invalide (1-600)');
      }
    }
    if (dateStr.isEmpty) {
      throw Exception('Date requise');
    }
    try {
      DateTime.parse(dateStr);
    } catch (_) {
      throw Exception('Format de date invalide (attendu yyyy-MM-dd)');
    }
    if (data['calories'] is int && (data['calories'] as int) < 0) {
      data['calories'] = 0;
    }
    return await db.update(
      Session.tableName,
      data,
      where: 'id = ?',
      whereArgs: [session.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(Session.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getTotalCalories() async {
    final db = await _dbHelper.database;
    final user = await getLoggedInUser();
    final result = user?.id != null
        ? await db.rawQuery(
            'SELECT SUM(calories) as total FROM ${Session.tableName} WHERE user_id = ? OR user_id IS NULL',
            [user!.id],
          )
        : await db.rawQuery(
            'SELECT SUM(calories) as total FROM ${Session.tableName}',
          );
    final value = result.first['total'];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<int> getTotalDuree() async {
    final db = await _dbHelper.database;
    final user = await getLoggedInUser();
    final result = user?.id != null
        ? await db.rawQuery(
            'SELECT SUM(duree) as total FROM ${Session.tableName} WHERE user_id = ? OR user_id IS NULL',
            [user!.id],
          )
        : await db.rawQuery(
            'SELECT SUM(duree) as total FROM ${Session.tableName}',
          );
    final value = result.first['total'];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<List<Session>> getSessionsByType(String type) async {
    final db = await _dbHelper.database;
    final user = await getLoggedInUser();
    final List<Map<String, dynamic>> data = await db.query(
      Session.tableName,
      where: user?.id != null
          ? '(type_activite LIKE ?) AND (user_id = ? OR user_id IS NULL)'
          : 'type_activite LIKE ?',
      whereArgs: user?.id != null ? ['%$type%', user!.id] : ['%$type%'],
    );
    return data.map((map) => Session.fromMap(map)).toList();
  }

  Future<void> clearAllSessions() async {
    final db = await _dbHelper.database;
    await db.delete(Session.tableName);
  }
}
