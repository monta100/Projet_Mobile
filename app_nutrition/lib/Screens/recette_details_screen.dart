import 'package:flutter/material.dart';
import '../Entites/recette.dart';
import '../Entites/ingredient.dart';
import '../Services/ingredient_service.dart';
import '../Theme/app_colors.dart';

class RecetteDetailsScreen extends StatefulWidget {
  final Recette recette;

  const RecetteDetailsScreen({super.key, required this.recette});

  @override
  State<RecetteDetailsScreen> createState() => _RecetteDetailsScreenState();
}

class _RecetteDetailsScreenState extends State<RecetteDetailsScreen> {
  final IngredientService _ingredientService = IngredientService();
  late Future<List<Ingredient>> _ingredientsFuture;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  void _loadIngredients() {
    if (widget.recette.id != null) {
      _ingredientsFuture = _ingredientService.getIngredientsByRecette(
        widget.recette.id!,
      );
    } else {
      // Si la recette n'a pas d'ID, il n'y a pas d'ingrédients à charger
      _ingredientsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recette.nom),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'recette-image-${widget.recette.id}',
              child: Image.network(
                widget.recette.imageUrl ??
                    _UnsplashHelper.urlFor(widget.recette.nom),
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recette.nom,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.recette.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.recette.description != null &&
                      widget.recette.description!.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.recette.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Ingrédients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildIngredientsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsList() {
    return FutureBuilder<List<Ingredient>>(
      future: _ingredientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text("Erreur de chargement des ingrédients."),
          );
        }
        final ingredients = snapshot.data ?? [];
        if (ingredients.isEmpty) {
          return const Center(
            child: Text("Aucun ingrédient trouvé pour cette recette."),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = ingredients[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.eco_outlined,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  ingredient.nom,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '${ingredient.quantite} ${ingredient.unite}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Helper Unsplash fallback
class _UnsplashHelper {
  static String urlFor(String name) {
    final base = name.trim().isEmpty
        ? 'healthy,food'
        : '${name.toLowerCase()},food,meal,healthy';
    final sig = name.hashCode & 0xFFFF;
    return 'https://source.unsplash.com/512x512/?${Uri.encodeComponent(base)}&sig=$sig';
  }
}
