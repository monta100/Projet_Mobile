import 'package:sqflite/sqflite.dart';
import '../Services/database_helper.dart';
import '../Entites/repas.dart';
class RepasService {
  final dbHelper = DatabaseHelper();

  // 🟢 Ajouter un repas
  Future<int> insertRepas(Repas repas) async {
    final db = await dbHelper.database;
    return await db.insert(
      Repas.tableName,
      repas.toMap(),
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
    return await db.delete(
      Repas.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
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
