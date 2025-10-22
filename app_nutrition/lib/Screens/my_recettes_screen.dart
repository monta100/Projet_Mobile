// ignore_for_file: deprecated_member_use, use_build_context_synchronously, prefer_interpolation_to_compose_strings, unused_field, prefer_final_fields, unused_element

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Services/image_ai_service.dart';
import '../Services/recette_service.dart';
import '../Services/ingredient_service.dart';
import '../Services/nutrition_ai_service.dart';
import '../Entites/recette.dart';
import '../Entites/ingredient.dart';
import 'recette_details_screen.dart';
import '../Theme/app_colors.dart';

class MyRecettesScreen extends StatefulWidget {
  const MyRecettesScreen({super.key});

  @override
  State<MyRecettesScreen> createState() => _MyRecettesScreenState();
}

class _MyRecettesScreenState extends State<MyRecettesScreen> {
  final RecetteService _service = RecetteService();
  final TextEditingController _searchController = TextEditingController();
  static const int _currentUserId = 1;
  late Future<List<Recette>> _future;
  bool _showOnlyDrafts = false;
  bool _isRefreshing = false; // Indicateur pour l'animation de rafraîchissement
  String _searchQuery = '';

  String _sortOption = 'Nom (A-Z)';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _future = _service.getUserRecettes(_currentUserId);
    });
  }

  Future<void> _togglePublish(Recette r) async {
    final updated = r.copyWith(publie: r.publie == 1 ? 0 : 1);
    await _service.updateRecette(updated);
    _load();
  }

  void _showCreateRecette() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddRecetteModal(utilisateurId: _currentUserId, onSaved: _load),
    );
  }

  void _showEditRecette(Recette recette) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditRecetteModal(recette: recette, onSaved: _load),
    );
  }

  Future<void> _deleteRecette(Recette recette) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la recette ?'),
        content: Text('"${recette.nom}" sera supprimé définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && recette.id != null) {
      await _service.deleteRecette(recette.id!);
      _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recette supprimée')));
    }
  }

  void _sortRecettes(List<Recette> recettes) {
    switch (_sortOption) {
      case 'Nom (A-Z)':
        recettes.sort((a, b) => a.nom.compareTo(b.nom));
        break;
      case 'Nom (Z-A)':
        recettes.sort((a, b) => b.nom.compareTo(a.nom));
        break;
      case 'Calories (croissant)':
        recettes.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case 'Calories (décroissant)':
        recettes.sort((a, b) => b.calories.compareTo(a.calories));
        break;
    }
  }

  Widget _buildSortDropdown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: _sortOption,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _sortOption = value;
            });
          }
        },
        items: const [
          DropdownMenuItem(value: 'Nom (A-Z)', child: Text('Nom (A-Z)')),
          DropdownMenuItem(value: 'Nom (Z-A)', child: Text('Nom (Z-A)')),
          DropdownMenuItem(
            value: 'Calories (croissant)',
            child: Text('Calories (croissant)'),
          ),
          DropdownMenuItem(
            value: 'Calories (décroissant)',
            child: Text('Calories (décroissant)'),
          ),
        ],
      ),
    );
  }

  double _aspectFor(int crossAxisCount) {
    if (crossAxisCount <= 2) return 0.8;
    if (crossAxisCount == 3) return 0.85;
    return 0.9;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Mes Recettes', style: TextStyle(color: Colors.white)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _load, // Reload recipes
            icon: const Icon(Icons.refresh),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor, AppColors.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRecette,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSummarySection(),
          Expanded(
            child: FutureBuilder<List<Recette>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const _Empty();
                }

                final recettes = snapshot.data!;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: _aspectFor(2),
                  ),
                  itemCount: recettes.length,
                  itemBuilder: (context, index) {
                    final recette = recettes[index];
                    return _RecetteCard(
                      recette: recette,
                      onTogglePublish: () => _togglePublish(recette),
                      onEdit: () => _showEditRecette(recette),
                      onDelete: () => _deleteRecette(recette),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<List<Recette>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Erreur de chargement des statistiques'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Aucune recette disponible pour les statistiques'),
          );
        }

        final allRecettes = snapshot.data ?? [];
        final publishedCount = allRecettes.where((r) => r.publie == 1).length;
        final draftCount = allRecettes.length - publishedCount;
        final averageCalories = allRecettes.isNotEmpty
            ? allRecettes.map((r) => r.calories).reduce((a, b) => a + b) /
                  allRecettes.length
            : 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Publiées',
                publishedCount.toString(),
                Icons.check_circle,
                color: AppColors.successColor,
              ),
              _buildStatCard(
                'Brouillons',
                draftCount.toString(),
                Icons.edit,
                color: AppColors.warningColor,
              ),
              _buildStatCard(
                'Calories Moy.',
                averageCalories.toStringAsFixed(1),
                Icons.local_fire_department,
                color: AppColors.accentColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    Color color = Colors.blue,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}

class _RecetteCard extends StatelessWidget {
  final Recette recette;
  final VoidCallback onTogglePublish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecetteCard({
    required this.recette,
    required this.onTogglePublish,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPublished = recette.publie == 1;
    final effectiveUrl =
        (recette.imageUrl != null && recette.imageUrl!.isNotEmpty)
        ? recette.imageUrl!
        : _UnsplashHelper.urlFor(recette.nom);

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecetteDetailsScreen(recette: recette),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recette-image-${recette.id}',
                    child: Image.network(
                      effectiveUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Modifier'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        recette.nom,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(blurRadius: 2, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: AppColors.accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recette.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onTogglePublish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPublished
                            ? AppColors.successColor.withOpacity(0.15)
                            : AppColors.warningColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPublished ? 'Publiée' : 'Brouillon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPublished
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucune recette'),
        ],
      ),
    );
  }
}

// ========================= MODAL CREATION RECETTE =========================

class _AddRecetteModal extends StatefulWidget {
  final int utilisateurId;
  final VoidCallback onSaved;
  const _AddRecetteModal({required this.utilisateurId, required this.onSaved});

  @override
  State<_AddRecetteModal> createState() => _AddRecetteModalState();
}

class _AddRecetteModalState extends State<_AddRecetteModal> {
  // Exemple d'utilisation de TextFormField avec message d'erreur dynamique en rouge :
  //
  // TextFormField(
  //   controller: _nomCtrl,
  //   decoration: InputDecoration(
  //     labelText: 'Nom de la recette',
  //     prefixIcon: Icon(Icons.fastfood),
  //   ),
  //   validator: (value) {
  //     if (value == null || value.trim().isEmpty) {
  //       return 'Le nom est obligatoire';
  //     }
  //     if (value.length < 3) {
  //       return 'Le nom doit contenir au moins 3 caractères';
  //     }
  //     return null;
  //   },
  // )
  //
  // TextFormField(
  //   controller: _descCtrl,
  //   decoration: InputDecoration(
  //     labelText: 'Description',
  //     prefixIcon: Icon(Icons.description),
  //   ),
  //   validator: (value) {
  //     if (value == null || value.trim().isEmpty) {
  //       return 'La description est obligatoire';
  //     }
  //     if (value.length < 10) {
  //       return 'La description doit contenir au moins 10 caractères';
  //     }
  //     return null;
  //   },
  // )
  //
  // Pour la quantité d'un ingrédient :
  // TextFormField(
  //   controller: row.quantite,
  //   keyboardType: TextInputType.number,
  //   decoration: InputDecoration(
  //     labelText: 'Quantité',
  //   ),
  //   validator: (value) {
  //     if (value == null || value.trim().isEmpty) {
  //       return 'Quantité requise';
  //     }
  //     final n = num.tryParse(value);
  //     if (n == null || n <= 0) {
  //       return 'Entrez un nombre positif';
  //     }
  //     return null;
  //   },
  // )
  final _formKey = GlobalKey<FormState>();
  final RecetteService _recetteService = RecetteService();
  final IngredientService _ingredientService = IngredientService();
  final NutritionAIService _aiService = NutritionAIService();
  final ImageAIService _imageService = ImageAIService();

  bool _loadingPreview = false;

  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final List<IngredientInputRow> _rows = [IngredientInputRow()];
  static const List<String> _defaultUnits = ['g', 'kg', 'ml', 'L', 'pièce'];
  List<String> get _units {
    final allUnits = _rows.map((r) => r.unite).whereType<String>().toSet();
    final units = {..._defaultUnits, ...allUnits};
    return units.toList();
  }

  String? _selectedImageUrl;
  File? _pickedImageFile;

  double get _totalCalories =>
      _rows.fold(0, (sum, r) => sum + (r.calories ?? 0));

  bool _validRow(IngredientInputRow r) =>
      r.nom.text.trim().isNotEmpty &&
      r.quantite.text.trim().isNotEmpty &&
      r.unite != null;

  void _addRow() => setState(() => _rows.add(IngredientInputRow()));

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.primaryColor),
              title: const Text('Importer depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  setState(() {
                    _pickedImageFile = File(picked.path);
                    _selectedImageUrl = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.orange),
              title: const Text('Générer avec IA (Unsplash)'),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _loadingPreview = true);
                final url = await _imageService.generateImage(
                  _nomCtrl.text.trim(),
                );
                setState(() {
                  _selectedImageUrl = url;
                  _pickedImageFile = null;
                  _loadingPreview = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty || !_rows.any(_validRow)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom + au moins un ingrédient.')),
      );
      return;
    }

    double aiCalories = 0;
    try {
      aiCalories = await _aiService.estimateCalories(_nomCtrl.text.trim());
    } catch (_) {
      aiCalories = 0;
    }
    final totalCalories = aiCalories > 0 ? aiCalories : _totalCalories;

    // Remplace ton bloc actuel par ceci 👇

    // ===== Image finale =====
    String? imageUrl;

    // Si l'utilisateur a importé une image depuis la galerie
    if (_pickedImageFile != null) {
      // Dans une vraie app tu uploaderais ce fichier vers ton backend ou Firebase Storage,
      // mais ici on utilise l'image IA si on ne fait pas d'upload réel.
      imageUrl = await _imageService.generateImage(_nomCtrl.text.trim());
    } else {
      // Sinon, on garde l’image IA choisie manuellement ou on en régénère une
      imageUrl =
          _selectedImageUrl ??
          await _imageService.generateImage(_nomCtrl.text.trim());
    }

    // ✅ Sécurité : fallback en cas d’échec de l’API
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = _UnsplashHelper.urlFor(_nomCtrl.text.trim());
    }

    final recette = Recette(
      nom: _nomCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      calories: totalCalories,
      repasId: null,
      utilisateurId: widget.utilisateurId,
      publie: 0,
      imageUrl: imageUrl,
    );

    final recetteId = await _recetteService.insertRecette(recette);

    for (final r in _rows.where(_validRow)) {
      await _ingredientService.insertIngredient(
        Ingredient(
          id: null,
          nom: r.nom.text.trim(),
          quantite: double.tryParse(r.quantite.text.trim()) ?? 0,
          unite: r.unite ?? 'g',
          calories: r.calories ?? 0,
          recetteId: recetteId,
        ),
      );
    }

    Navigator.pop(context);
    widget.onSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          aiCalories > 0
              ? '✅ Calories IA: ${aiCalories.toStringAsFixed(0)} kcal'
              : '✅ Recette enregistrée (calories locales)',
        ),
      ),
    );
  }

  // ------------------ UI ------------------

  // Removed unused _buildField method

  Widget _buildCaloriesSummary() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.local_fire_department, color: AppColors.accentColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calories totales (IA ou locale)',
                style: TextStyle(
                  color: AppColors.textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _totalCalories.toStringAsFixed(0) + ' kcal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildIngredientsHeader() => Row(
    children: const [
      Icon(Icons.list_alt, color: AppColors.primaryColor),
      SizedBox(width: 8),
      Text(
        'Ingrédients',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textColor,
        ),
      ),
    ],
  );

  List<Widget> _buildIngredientRows() => List.generate(_rows.length, (index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _smallField(row.nom, 'Nom', Icons.eco)),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: _smallField(
              row.quantite,
              'Quantité',
              Icons.scale,
              isNum: true,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: _unitDropdown(row)),
        ],
      ),
    );
  });

  Widget _unitDropdown(IngredientInputRow row) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: row.unite,
        hint: const Text('Unité'),
        items: _units
            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
            .toList(),
        onChanged: (v) => setState(() => row.unite = v),
      ),
    ),
  );

  Widget _smallField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryColor, size: 18),
        labelText: label,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    ),
  );

  Widget _buildAddIngredientButton() => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: _addRow,
      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryColor),
      label: const Text(
        'Ajouter un ingrédient',
        style: TextStyle(color: AppColors.primaryColor),
      ),
    ),
  );

  Widget _buildSaveButton() => GestureDetector(
    onTap: _formKey.currentState?.validate() == true ? _save : null,
    child: Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _formKey.currentState?.validate() == true
            ? const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.accentColor],
              )
            : const LinearGradient(colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Créer la recette',
          style: TextStyle(
            color: _formKey.currentState?.validate() == true
                ? Colors.white
                : Colors.grey[400],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _nomCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nom de la recette',
                        prefixIcon: const Icon(Icons.fastfood),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        if (value.length < 3) {
                          return 'Le nom doit contenir au moins 3 caractères';
                        }
                        return null;
                      },
                    ),
                    if (_formKey.currentState?.validate() == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Veuillez corriger les erreurs ci-dessus.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La description est obligatoire';
                        }
                        if (value.length < 10) {
                          return 'La description doit contenir au moins 10 caractères';
                        }
                        return null;
                      },
                    ),
                    if (_formKey.currentState?.validate() == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Veuillez corriger les erreurs ci-dessus.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: _showImageOptions,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: _pickedImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _pickedImageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : _selectedImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _selectedImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: AppColors.primaryColor,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Ajouter une image',
                                      style: TextStyle(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildCaloriesSummary(),
                    const SizedBox(height: 18),
                    _buildIngredientsHeader(),
                    const SizedBox(height: 10),
                    ..._buildIngredientRows(),
                    _buildAddIngredientButton(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========================= MODAL MODIFICATION RECETTE =========================

class _EditRecetteModal extends StatefulWidget {
  final Recette recette;
  final VoidCallback onSaved;
  const _EditRecetteModal({required this.recette, required this.onSaved});

  @override
  State<_EditRecetteModal> createState() => _EditRecetteModalState();
}

class _EditRecetteModalState extends State<_EditRecetteModal> {
  final _formKey = GlobalKey<FormState>();
  final RecetteService _recetteService = RecetteService();
  final IngredientService _ingredientService = IngredientService();
  final NutritionAIService _aiService = NutritionAIService();
  final ImageAIService _imageService = ImageAIService();

  late final TextEditingController _nomCtrl;
  late final TextEditingController _descCtrl;

  final List<IngredientInputRow> _rows = [];
  static const List<String> _defaultUnits = ['g', 'kg', 'ml', 'L', 'pièce'];
  List<String> get _units {
    final allUnits = _rows.map((r) => r.unite).whereType<String>().toSet();
    final units = {..._defaultUnits, ...allUnits};
    return units.toList();
  }

  String? _selectedImageUrl;
  File? _pickedImageFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.recette.nom);
    _descCtrl = TextEditingController(text: widget.recette.description);
    _selectedImageUrl = widget.recette.imageUrl;
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    if (widget.recette.id == null) {
      setState(() => _isLoading = false);
      return;
    }
    final ingredients = await _ingredientService.getIngredientsByRecette(
      widget.recette.id!,
    );
    setState(() {
      for (final ing in ingredients) {
        _rows.add(
          IngredientInputRow()
            ..nom.text = ing.nom
            ..quantite.text = ing.quantite.toString()
            ..unite = ing.unite
            ..calories = ing.calories,
        );
      }
      if (_rows.isEmpty) _rows.add(IngredientInputRow());
      _isLoading = false;
    });
  }

  double get _totalCalories =>
      _rows.fold(0, (sum, r) => sum + (r.calories ?? 0));

  bool _validRow(IngredientInputRow r) =>
      r.nom.text.trim().isNotEmpty &&
      r.quantite.text.trim().isNotEmpty &&
      r.unite != null;

  void _addRow() => setState(() => _rows.add(IngredientInputRow()));

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.primaryColor),
              title: const Text('Importer depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  setState(() {
                    _pickedImageFile = File(picked.path);
                    _selectedImageUrl = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.orange),
              title: const Text('Générer avec IA (Unsplash)'),
              onTap: () async {
                Navigator.pop(context);
                final url = await _imageService.generateImage(
                  _nomCtrl.text.trim(),
                );
                setState(() {
                  _selectedImageUrl = url;
                  _pickedImageFile = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        !_rows.any(_validRow)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires.'),
        ),
      );
      return;
    }

    double aiCalories = 0;
    try {
      aiCalories = await _aiService.estimateCalories(_nomCtrl.text.trim());
    } catch (_) {
      aiCalories = 0;
    }
    final totalCalories = aiCalories > 0 ? aiCalories : _totalCalories;

    String? imageUrl = _selectedImageUrl;
    if (_pickedImageFile != null) {
      imageUrl = await _imageService.generateImage(_nomCtrl.text.trim());
    }
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = _UnsplashHelper.urlFor(_nomCtrl.text.trim());
    }

    final updatedRecette = widget.recette.copyWith(
      nom: _nomCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      calories: totalCalories,
      imageUrl: imageUrl,
    );

    await _recetteService.updateRecette(updatedRecette);

    final ingredientsToSave = _rows
        .where(_validRow)
        .map(
          (r) => Ingredient(
            id: null, // L'ID sera géré par la DB
            nom: r.nom.text.trim(),
            quantite: double.tryParse(r.quantite.text.trim()) ?? 0,
            unite: r.unite ?? 'g',
            calories: r.calories ?? 0,
            recetteId: widget.recette.id!,
          ),
        )
        .toList();

    await _ingredientService.updateIngredientsForRecette(
      widget.recette.id!,
      ingredientsToSave,
    );

    Navigator.pop(context);
    widget.onSaved();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Recette mise à jour')));
  }

  // ------------------ UI (similaire à la création) ------------------

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _nomCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nom de la recette',
                              prefixIcon: Icon(Icons.fastfood),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est obligatoire';
                              }
                              return null;
                            },
                          ),
                          if (_formKey.currentState?.validate() == false)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Veuillez corriger les erreurs ci-dessus.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Description (optionnel)',
                              prefixIcon: Icon(Icons.notes),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La description est obligatoire';
                              }
                              return null;
                            },
                          ),
                          if (_formKey.currentState?.validate() == false)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Veuillez corriger les erreurs ci-dessus.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: _showImageOptions,
                            child: Container(
                              width: double.infinity,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.2,
                                  ),
                                ),
                              ),
                              child: _pickedImageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        _pickedImageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _selectedImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        _selectedImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.add_a_photo),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildCaloriesSummary(),
                          const SizedBox(height: 18),
                          _buildIngredientsHeader(),
                          const SizedBox(height: 10),
                          ..._buildIngredientRows(),
                          _buildAddIngredientButton(),
                          const SizedBox(height: 24),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // Removed unused _buildField method

  Widget _buildCaloriesSummary() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.local_fire_department, color: AppColors.accentColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${_totalCalories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildIngredientsHeader() => Row(
    children: const [
      Icon(Icons.list_alt, color: AppColors.primaryColor),
      SizedBox(width: 8),
      Text(
        'Ingrédients',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textColor,
        ),
      ),
    ],
  );

  List<Widget> _buildIngredientRows() => List.generate(_rows.length, (index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _smallField(row.nom, 'Nom', Icons.eco)),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: _smallField(row.quantite, 'Qté', Icons.scale, isNum: true),
          ),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: _unitDropdown(row)),
        ],
      ),
    );
  });

  Widget _unitDropdown(IngredientInputRow row) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: row.unite,
        hint: const Text('Unité'),
        items: _units
            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
            .toList(),
        onChanged: (v) => setState(() => row.unite = v),
      ),
    ),
  );

  Widget _smallField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryColor, size: 18),
        labelText: label,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    ),
  );

  Widget _buildAddIngredientButton() => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: _addRow,
      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryColor),
      label: const Text(
        'Ajouter un ingrédient',
        style: TextStyle(color: AppColors.primaryColor),
      ),
    ),
  );

  Widget _buildSaveButton() => GestureDetector(
    onTap: _formKey.currentState?.validate() == true ? _save : null,
    child: Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _formKey.currentState?.validate() == true
            ? const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.accentColor],
              )
            : const LinearGradient(colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Créer la recette',
          style: TextStyle(
            color: _formKey.currentState?.validate() == true
                ? Colors.white
                : Colors.grey[400],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
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

class IngredientInputRow {
  final TextEditingController nom = TextEditingController();
  final TextEditingController quantite = TextEditingController();
  String? unite;
  double? calories;
  bool isEstimating = false;
}
