import 'package:sqflite/sqflite.dart';
import '../Services/database_helper.dart';
import '../Entites/repas.dart';

class RepasService {
  final dbHelper = DatabaseHelper();

  // ID utilisateur par défaut
  static const int _defaultUserId = 1;

  // Résout un userId valide
  Future<int> _resolveUserId(Database db, int? providedId) async {
    if (providedId != null) {
      final exists = await db.query(
        'utilisateurs',
        where: 'id = ?',
        whereArgs: [providedId],
        limit: 1,
      );
      if (exists.isNotEmpty) return providedId;
    }

    final staticUser = await db.query(
      'utilisateurs',
      where: 'id = ?',
      whereArgs: [_defaultUserId],
      limit: 1,
    );
    if (staticUser.isNotEmpty) return _defaultUserId;

    final anyUser = await db.query('utilisateurs', limit: 1);
    if (anyUser.isNotEmpty) return anyUser.first['id'] as int;

    final newId = await db.insert('utilisateurs', {
      'nom': 'User',
      'prenom': 'Demo',
      'email': 'demo_${DateTime.now().millisecondsSinceEpoch}@app.com',
      'mot_de_passe': '1234',
      'role': 'utilisateur',
    });
    return newId;
  }

  // 🟢 Ajouter un repas
  Future<int> insertRepas(Repas repas) async {
    final db = await dbHelper.database;
    final data = repas.toMap();

    int? providedId = data['utilisateur_id'] as int?;
    final resolvedId = await _resolveUserId(db, providedId);
    data['utilisateur_id'] = resolvedId;

    return await db.insert(
      Repas.tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🟡 Récupérer tous les repas
  Future<List<Repas>> getAllRepas() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(Repas.tableName);

    return List.generate(maps.length, (i) => Repas.fromMap(maps[i]));
  }

  // 🟠 Récupérer les repas d’un utilisateur spécifique
  Future<List<Repas>> getRepasByUtilisateur(int utilisateurId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      Repas.tableName,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );

    return List.generate(maps.length, (i) => Repas.fromMap(maps[i]));
  }

  // 🟢 Récupérer les repas d’un utilisateur pour une date donnée
  Future<List<Repas>> getRepasByDate(
    DateTime date, {
    int? utilisateurId,
  }) async {
    final db = await dbHelper.database;
    final userId = utilisateurId ?? _defaultUserId;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final List<Map<String, dynamic>> maps = await db.query(
      Repas.tableName,
      where: 'utilisateur_id = ? AND date >= ? AND date < ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
    );
    return List.generate(maps.length, (i) => Repas.fromMap(maps[i]));
  }

  // 🔵 Mettre à jour un repas
  Future<int> updateRepas(Repas repas) async {
    final db = await dbHelper.database;
    return await db.update(
      Repas.tableName,
      repas.toMap(),
      where: 'id = ?',
      whereArgs: [repas.id],
    );
  }

  // 🔴 Supprimer un repas
  Future<int> deleteRepas(int id) async {
    final db = await dbHelper.database;
    return await db.delete(Repas.tableName, where: 'id = ?', whereArgs: [id]);
  }

  // ⚪ Supprimer tous les repas d’un utilisateur (optionnel)
  Future<int> deleteRepasByUtilisateur(int utilisateurId) async {
    final db = await dbHelper.database;
    return await db.delete(
      Repas.tableName,
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );
  }

  // 🟣 Rechercher un repas par ID
  Future<Repas?> getRepasById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      Repas.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Repas.fromMap(maps.first);
    } else {
      return null;
    }
  }
}
