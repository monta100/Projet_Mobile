// ignore_for_file: deprecated_member_use, use_build_context_synchronously, prefer_interpolation_to_compose_strings

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
  static const int _currentUserId = 1;
  late Future<List<Recette>> _future;
  bool _showOnlyDrafts = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
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

  double _aspectFor(int crossAxisCount) {
    if (crossAxisCount <= 2) return 0.66;
    if (crossAxisCount == 3) return 0.72;
    return 0.82;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Recettes'),
        actions: [
          IconButton(
            tooltip: _showOnlyDrafts ? 'Voir toutes' : 'Voir brouillons',
            icon: Icon(
              _showOnlyDrafts ? Icons.filter_alt_off : Icons.filter_alt,
            ),
            onPressed: () => setState(() => _showOnlyDrafts = !_showOnlyDrafts),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRecette,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Recette>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = (snapshot.data ?? [])
              .where((r) => !_showOnlyDrafts || r.publie == 0)
              .toList();
          if (list.isEmpty) {
            return const _Empty();
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 500
                  ? 2
                  : constraints.maxWidth < 800
                  ? 3
                  : 4;
              final aspect = _aspectFor(crossAxisCount);
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspect,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) => _RecetteCard(
                  recette: list[i],
                  onTogglePublish: () => _togglePublish(list[i]),
                  onDelete: () => _deleteRecette(list[i]),
                  onEdit: () => _showEditRecette(list[i]),
                ),
              );
            },
          );
        },
      ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageH = constraints.maxHeight * 0.42;
        return Card(
          elevation: 6,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            splashColor: AppColors.primaryColor.withOpacity(0.08),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecetteDetailsScreen(recette: recette),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Hero(
                          tag: 'recette-image-${recette.id}',
                          child: Text(
                            recette.nom,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              color: AppColors.textColor,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Modifier'),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete),
                                  title: Text('Supprimer'),
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: imageH,
                      width: double.infinity,

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
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recette.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPublished
                            ? Colors.green.withOpacity(0.12)
                            : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        isPublished ? 'Publiée' : 'Brouillon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPublished
                              ? Colors.green[800]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  final RecetteService _recetteService = RecetteService();
  final IngredientService _ingredientService = IngredientService();
  final NutritionAIService _aiService = NutritionAIService();
  final ImageAIService _imageService = ImageAIService();

  bool _loadingPreview = false;

  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final List<IngredientInputRow> _rows = [IngredientInputRow()];
  static const List<String> _units = ['g', 'kg', 'ml', 'L', 'pièce'];

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

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
  }) => Container(
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
                  _buildField(_nomCtrl, 'Nom de la recette', Icons.fastfood),
                  const SizedBox(height: 12),
                  _buildField(
                    _descCtrl,
                    'Description (optionnel)',
                    Icons.notes,
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
  final RecetteService _recetteService = RecetteService();
  final IngredientService _ingredientService = IngredientService();
  final NutritionAIService _aiService = NutritionAIService();
  final ImageAIService _imageService = ImageAIService();

  late final TextEditingController _nomCtrl;
  late final TextEditingController _descCtrl;

  final List<IngredientInputRow> _rows = [];
  static const List<String> _units = ['g', 'kg', 'ml', 'L', 'pièce'];

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
                        _buildField(
                          _nomCtrl,
                          'Nom de la recette',
                          Icons.fastfood,
                        ),
                        const SizedBox(height: 12),
                        _buildField(_descCtrl, 'Description', Icons.notes),
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
                                : const Center(child: Icon(Icons.add_a_photo)),
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
        );
      },
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryColor),
            labelText: label,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      );

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
          'Mettre à jour la recette',
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
