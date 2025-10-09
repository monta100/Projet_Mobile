import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipeData;

  const RecipeCard({Key? key, required this.recipeData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String nom = recipeData['nom'] ?? 'Recette inconnue';
    final String description =
        recipeData['description'] ?? 'Aucune description';
    final double calories = (recipeData['calories'] ?? 0).toDouble();
    final List<dynamic> ingredients = recipeData['ingredients'] ?? [];

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nom,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Chip(
              label: Text('${calories.toStringAsFixed(0)} kcal'),
              backgroundColor: Colors.orange.shade100,
            ),
            const SizedBox(height: 12.0),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16.0),
            Text(
              'Ingrédients:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ...ingredients.map((ing) {
              final String ingNom = ing['nom'] ?? '?';
              final String quantite = ing['quantite']?.toString() ?? '?';
              final String unite = ing['unite'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_box_outline_blank,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$ingNom ($quantite $unite)')),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
