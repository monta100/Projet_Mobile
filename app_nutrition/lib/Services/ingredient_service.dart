import 'package:sqflite/sqflite.dart';
import '../Services/database_helper.dart';
import '../Entites/ingredient.dart';

class IngredientService {
  final dbHelper = DatabaseHelper();

  // Ajouter un ingrédient
  Future<int> insertIngredient(Ingredient ingredient) async {
    final db = await dbHelper.database;
    return await db.insert(
      'ingredients',
      ingredient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer tous les ingrédients
  Future<List<Ingredient>> getAllIngredients() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('ingredients');
    return List.generate(maps.length, (i) => Ingredient.fromMap(maps[i]));
  }

  // Récupérer les ingrédients d'une recette spécifique
  Future<List<Ingredient>> getIngredientsByRecette(int recetteId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: 'recette_id = ?',
      whereArgs: [recetteId],
    );
    return List.generate(maps.length, (i) => Ingredient.fromMap(maps[i]));
  }

  // Mettre à jour un ingrédient
  Future<int> updateIngredient(Ingredient ingredient) async {
    final db = await dbHelper.database;
    return await db.update(
      'ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  // Supprimer un ingrédient
  Future<int> deleteIngredient(int id) async {
    final db = await dbHelper.database;
    return await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
  }

  // Supprimer tous les ingrédients d'une recette
  Future<int> deleteIngredientsByRecette(int recetteId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'ingredients',
      where: 'recette_id = ?',
      whereArgs: [recetteId],
    );
  }

  // Mettre à jour une liste d'ingrédients pour une recette
  Future<void> updateIngredientsForRecette(
    int recetteId,
    List<Ingredient> ingredients,
  ) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // D'abord, supprimer les anciens ingrédients
      await txn.delete(
        'ingredients',
        where: 'recette_id = ?',
        whereArgs: [recetteId],
      );
      // Ensuite, insérer les nouveaux
      for (final ingredient in ingredients) {
        await txn.insert('ingredients', ingredient.toMap());
      }
    });
  }
}
