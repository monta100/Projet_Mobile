import 'package:sqflite/sqflite.dart';
import '../Services/database_helper.dart';
import '../Entites/recette.dart';

class RecetteService {
  final dbHelper = DatabaseHelper();

  // Ajouter une recette
  Future<int> insertRecette(Recette recette) async {
    final db = await dbHelper.database;
    return await db.insert(
      'recettes',
      recette.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer toutes les recettes
  Future<List<Recette>> getAllRecettes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('recettes');
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
  Future<int> deleteRecette(int id) async {
    final db = await dbHelper.database;
    return await db.delete('recettes', where: 'id = ?', whereArgs: [id]);
  }
}
