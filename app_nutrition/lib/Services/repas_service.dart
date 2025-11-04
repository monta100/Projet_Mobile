import 'package:sqflite/sqflite.dart';
import '../Services/database_helper.dart';
import '../Entites/repas.dart';
import 'session_service.dart';

class RepasService {
  final dbHelper = DatabaseHelper();
  final _sessionService = SessionService();

  // 🟢 Ajouter un repas
  Future<int> insertRepas(Repas repas) async {
    final db = await dbHelper.database;
    final user = await _sessionService.getLoggedInUser();

    if (user == null || user.id == null) {
      throw Exception(
        "Aucun utilisateur connecté. Impossible d'ajouter le repas.",
      );
    }

    final data = repas.copyWith(utilisateurId: user.id).toMap();

    return await db.insert(
      Repas.tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🟡 Récupérer tous les repas pour l'utilisateur connecté
  Future<List<Repas>> getAllRepasForCurrentUser() async {
    final db = await dbHelper.database;
    final user = await _sessionService.getLoggedInUser();

    if (user == null || user.id == null) {
      return []; // Retourne une liste vide si aucun utilisateur n'est connecté
    }

    final List<Map<String, dynamic>> maps = await db.query(
      Repas.tableName,
      where: 'utilisateur_id = ?',
      whereArgs: [user.id],
    );

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
  Future<List<Repas>> getRepasByDate(DateTime date) async {
    final db = await dbHelper.database;
    final user = await _sessionService.getLoggedInUser();

    if (user == null || user.id == null) {
      return [];
    }

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final List<Map<String, dynamic>> maps = await db.query(
      Repas.tableName,
      where: 'utilisateur_id = ? AND date >= ? AND date < ?',
      whereArgs: [user.id, start.toIso8601String(), end.toIso8601String()],
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
