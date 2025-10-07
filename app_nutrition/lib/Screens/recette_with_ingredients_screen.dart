// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, prefer_final_fields, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import '../Theme/app_colors.dart';
import '../Entites/recette.dart';
import '../Entites/ingredient.dart';
import '../Services/recette_service.dart';
import '../Services/ingredient_service.dart';

class RecetteWithIngredientsScreen extends StatefulWidget {
  final int repasId; // ✅ le repas sélectionné

  const RecetteWithIngredientsScreen({Key? key, required this.repasId})
      : super(key: key);

  @override
  _RecetteWithIngredientsScreenState createState() =>
      _RecetteWithIngredientsScreenState();
}

class _RecetteWithIngredientsScreenState
    extends State<RecetteWithIngredientsScreen>
    with TickerProviderStateMixin {
  final RecetteService _recetteService = RecetteService();
  final IngredientService _ingredientService = IngredientService();
  late Future<List<Recette>> _recettesFuture;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadRecettes();
  }

  void _loadRecettes() {
    setState(() {
      _recettesFuture =
          _recetteService.getRecettesByRepas(widget.repasId); // ✅ filtré
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(slivers: [_buildAppBar(), _buildRecettesList()]),
      floatingActionButton: _buildFAB(),
    );
  }

  // --- HEADER ---
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.secondaryColor,
                AppColors.accentColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.restaurant_menu, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text(
                      "Recettes & Ingrédients",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Ajoutez et gérez vos plats facilement",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LISTE DES RECETTES ---
  Widget _buildRecettesList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: FutureBuilder<List<Recette>>(
        future: _recettesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SliverFillRemaining(
              child: Center(
                child: Text(
                  "Aucune recette enregistrée",
                  style: TextStyle(color: AppColors.textColor, fontSize: 18),
                ),
              ),
            );
          }

          final recettes = snapshot.data!;
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildRecetteCard(recettes[index], index),
              childCount: recettes.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecetteCard(Recette recette, int index) {
    final color = [
      AppColors.primaryColor,
      AppColors.secondaryColor,
      AppColors.accentColor,
    ][index % 3];

    return FutureBuilder<List<Ingredient>>(
      future: _ingredientService.getIngredientsByRecette(recette.id ?? 0),
      builder: (context, snapshot) {
        final ingredients = snapshot.data ?? [];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.restaurant_menu, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recette.nom,
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "${recette.calories.toInt()} kcal",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (recette.description != null &&
                    recette.description!.isNotEmpty)
                  Text(
                    recette.description!,
                    style: TextStyle(
                      color: AppColors.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: ingredients.isEmpty
                      ? [
                          Text(
                            "Aucun ingrédient",
                            style: TextStyle(
                              color: AppColors.textColor.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ]
                      : ingredients
                          .map(
                            (i) => Chip(
                              backgroundColor: color.withOpacity(0.1),
                              label: Text(
                                "${i.nom} (${i.quantite}${i.unite})",
                                style: TextStyle(color: color),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- BOUTON FLOTANT ---
  Widget _buildFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, AppColors.accentColor],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => _showAddRecetteModal(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // --- MODAL AJOUT RECETTE + INGREDIENTS ---
  void _showAddRecetteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AddRecetteModal(onSaved: _loadRecettes, repasId: widget.repasId),
    );
  }
}

class _AddRecetteModal extends StatefulWidget {
  final VoidCallback onSaved;
  final int repasId;

  const _AddRecetteModal({required this.onSaved, required this.repasId});

  @override
  __AddRecetteModalState createState() => __AddRecetteModalState();
}

class __AddRecetteModalState extends State<_AddRecetteModal> {
  final RecetteService _recetteService = RecetteService();
  final IngredientService _ingredientService = IngredientService();

  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _calCtrl = TextEditingController();

  final _nomIngCtrl = TextEditingController();
  final _qteCtrl = TextEditingController();
  final _uniteCtrl = TextEditingController();
  final _calIngCtrl = TextEditingController();

  List<Ingredient> _ingredients = [];

  Future<void> _save() async {
    if (_nomCtrl.text.isEmpty || _ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez ajouter un nom et au moins un ingrédient."),
        ),
      );
      return;
    }

    // ✅ 1. Créer la recette liée au repas courant
    final recette = Recette(
      nom: _nomCtrl.text,
      description: _descCtrl.text,
      calories: double.tryParse(_calCtrl.text) ?? 0,
      repasId: widget.repasId,
    );

    final recetteId = await _recetteService.insertRecette(recette);

    // ✅ 2. Ajouter les ingrédients avec le bon recetteId
    for (final ing in _ingredients) {
      final newIng = ing.copyWith(recetteId: recetteId);
      await _ingredientService.insertIngredient(newIng);
    }

    Navigator.pop(context);
    widget.onSaved();
  }

  void _addIngredient() {
    if (_nomIngCtrl.text.isEmpty ||
        _qteCtrl.text.isEmpty ||
        _uniteCtrl.text.isEmpty) return;

    setState(() {
      _ingredients.add(
        Ingredient(
          id: null,
          nom: _nomIngCtrl.text,
          quantite: double.tryParse(_qteCtrl.text) ?? 0,
          unite: _uniteCtrl.text,
          calories: double.tryParse(_calIngCtrl.text) ?? 0,
          recetteId: 0, // temporairement
        ),
      );
      _nomIngCtrl.clear();
      _qteCtrl.clear();
      _uniteCtrl.clear();
      _calIngCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Nouvelle Recette",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildField(_nomCtrl, "Nom de la recette", Icons.restaurant_menu),
            const SizedBox(height: 12),
            _buildField(_descCtrl, "Description", Icons.description),
            const SizedBox(height: 12),
            _buildField(
              _calCtrl,
              "Calories totales",
              Icons.local_fire_department,
              isNum: true,
            ),

            const Divider(height: 32),
            const Text(
              "Ajouter des ingrédients",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _buildField(_nomIngCtrl, "Nom", Icons.eco)),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _buildField(_qteCtrl, "Qté", Icons.scale, isNum: true)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildField(_uniteCtrl, "Unité", Icons.straighten)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(
                        _calIngCtrl, "Kcal", Icons.local_fire_department,
                        isNum: true)),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addIngredient,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Ajouter à la liste",
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),

            // Liste d’ingrédients ajoutés
            Column(
              children: _ingredients.map((ing) {
                return ListTile(
                  title: Text("${ing.nom} (${ing.quantite}${ing.unite})"),
                  subtitle: Text("${ing.calories.toInt()} kcal"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _ingredients.remove(ing));
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Créer la recette',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
