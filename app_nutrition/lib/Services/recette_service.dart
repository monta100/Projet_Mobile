import 'package:sqflite/sqflite.dart';
import '../Services/database_helper.dart';
import '../Entites/recette.dart';

class RecetteService {
  final dbHelper = DatabaseHelper();

  // Ajouter une recette
  Future<int> insertRecette(Recette recette) async {
    final db = await dbHelper.database;
    final data = recette.toMap();
    // Default utilisateur_id = 1 si absent (placeholder utilisateur courant)
    data['utilisateur_id'] ??= 1;
    // Validation de la clé étrangère : si repasId fourni mais inexistant -> on passe à null
    if (recette.repasId != null) {
      final exist = await db.query(
        'repas',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [recette.repasId],
      );
      if (exist.isEmpty) {
        data['repas_id'] = null; // décrochage automatique
      }
    }
    try {
      return await db.insert(
        'recettes',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      // Si encore une contrainte, on retente en forçant null (séparation logique activée)
      if (recette.repasId != null && e.isNoSuchTableError() == false) {
        data['repas_id'] = null;
        return await db.insert(
          'recettes',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      rethrow;
    }
  }

  // Récupérer toutes les recettes
  Future<List<Recette>> getAllRecettes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('recettes');
    return List.generate(maps.length, (i) => Recette.fromMap(maps[i]));
  }

  Future<List<Recette>> getPublishedRecettes() async {
    final db = await dbHelper.database;
    final maps = await db.query('recettes', where: 'publie = 1');
    return List.generate(maps.length, (i) => Recette.fromMap(maps[i]));
  }

  Future<List<Recette>> getUserRecettes(int utilisateurId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'recettes',
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );
    return List.generate(maps.length, (i) => Recette.fromMap(maps[i]));
  }

  Future<List<Recette>> getStandaloneRecettes() async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      'SELECT * FROM recettes WHERE repas_id IS NULL',
    );
    return List.generate(maps.length, (i) => Recette.fromMap(maps[i]));
  }

  // Récupérer les recettes d'un repas spécifique
  Future<List<Recette>> getRecettesByRepas(int repasId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recettes',
      where: 'repas_id = ?',
      whereArgs: [repasId],
    );
    return List.generate(maps.length, (i) => Recette.fromMap(maps[i]));
  }

  // Mettre à jour une recette
  Future<int> updateRecette(Recette recette) async {
    final db = await dbHelper.database;
    return await db.update(
      'recettes',
      recette.toMap(),
      where: 'id = ?',
      whereArgs: [recette.id],
    );
  }

  // Supprimer une recette
  // Supprimer une recette
  Future<int> deleteRecette(int id) async {
    final db = await dbHelper.database;
    // On supprime d'abord les ingrédients associés pour éviter les orphelins
    await db.delete('ingredients', where: 'recette_id = ?', whereArgs: [id]);
    // Ensuite on supprime la recette
    return await db.delete('recettes', where: 'id = ?', whereArgs: [id]);
  }
}
