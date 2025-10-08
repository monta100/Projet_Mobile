import 'package:flutter/material.dart';
import '../Services/recette_service.dart';
import '../Services/ingredient_service.dart';
import '../Services/nutrition_ai_service.dart';
import '../Entites/recette.dart';
import '../Entites/ingredient.dart';
import '../Theme/app_colors.dart';

class MyRecettesScreen extends StatefulWidget {
  const MyRecettesScreen({super.key});

  @override
  State<MyRecettesScreen> createState() => _MyRecettesScreenState();
}

class _MyRecettesScreenState extends State<MyRecettesScreen> {
  final RecetteService _service = RecetteService();
  static const int _currentUserId = 1; // TODO: inject real user later
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
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) => _RecetteCard(
                  recette: list[i],
                  onTogglePublish: () => _togglePublish(list[i]),
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
  const _RecetteCard({required this.recette, required this.onTogglePublish});

  @override
  Widget build(BuildContext context) {
    final isPublished = recette.publie == 1;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {}, // TODO: open edit/details
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recette.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: isPublished ? 'Dépublier' : 'Publier',
                    icon: Icon(
                      isPublished ? Icons.public : Icons.public_off,
                      color: isPublished ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    onPressed: onTogglePublish,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${recette.calories.toStringAsFixed(0)} kcal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPublished
                        ? Colors.green.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPublished ? 'Publiée' : 'Brouillon',
                    style: TextStyle(
                      fontSize: 11,
                      color: isPublished ? Colors.green[800] : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  final RecetteService _recetteService = RecetteService();
  final IngredientService _ingredientService = IngredientService();
  final NutritionAIService _aiService = NutritionAIService();

  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final List<IngredientInputRow> _rows = [IngredientInputRow()];
  static const List<String> _units = ['g', 'kg', 'ml', 'L', 'pièce'];

  // --- Tables locales (fallback seulement) ---
  static const Map<String, double> _kcalPer100g = {
    'riz': 360,
    'poulet': 165,
    'poulet blanc': 165,
    'huile': 884,
    'huile olive': 884,
    'tomate': 18,
    'pomme': 52,
    'banane': 89,
    'sucre': 400,
    'farine': 364,
    'beurre': 717,
    'fromage': 402,
    'carotte': 41,
    'oignon': 40,
    'poivron': 31,
  };
  static const Map<String, double> _pieceToGrams = {
    'tomate': 120,
    'pomme': 150,
    'banane': 120,
    'oeuf': 60,
  };

  double get _totalCalories =>
      _rows.fold(0, (sum, r) => sum + (r.calories ?? 0));

  bool _validRow(IngredientInputRow r) =>
      r.nom.text.trim().isNotEmpty &&
      r.quantite.text.trim().isNotEmpty &&
      r.unite != null;

  void _addRow() => setState(() => _rows.add(IngredientInputRow()));
  void _removeRow(int i) {
    if (_rows.length == 1) return;
    setState(() => _rows.removeAt(i));
  }

  Future<void> _estimateRowCalories(int index) async {
    final row = _rows[index];
    if (!_validRow(row) || row.isEstimating) return;
    setState(() => row.isEstimating = true);
    final name = row.nom.text.trim().toLowerCase();
    // 1. API d'abord
    double apiValue = await _aiService.estimateCalories(name);
    double? kcal;
    if (apiValue > 0) {
      // On prend la valeur brute API (priorité utilisateur)
      kcal = apiValue;
    } else {
      // 2. Fallback local avec quantités
      final qty = double.tryParse(row.quantite.text.trim()) ?? 0;
      kcal = _estimateLocal(name, qty, row.unite!);
      // 3. Si encore null/zero -> 0 explicite
      if (kcal == null || kcal == 0) kcal = 0;
    }
    setState(() {
      row.calories = kcal;
      row.isEstimating = false;
    });
  }

  Future<void> _estimateAll() async {
    for (int i = 0; i < _rows.length; i++) {
      if (_rows[i].calories == null) {
        await _estimateRowCalories(i);
      }
    }
  }

  double? _estimateLocal(String name, double qty, String unit) {
    if (qty <= 0) return 0;
    final base = _kcalPer100g[name];
    final grams = _toGrams(qty, unit, name);
    if (base == null) return 0;
    return (base / 100.0) * grams;
  }

  double _toGrams(double qty, String unit, String name) {
    switch (unit) {
      case 'g':
        return qty;
      case 'kg':
        return qty * 1000;
      case 'ml':
        return qty; // densité ~1
      case 'L':
        return qty * 1000;
      case 'pièce':
        final w = _pieceToGrams[name] ?? 100;
        return qty * w;
      default:
        return qty;
    }
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty || !_rows.any(_validRow)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom + au moins un ingrédient.')),
      );
      return;
    }
    final recette = Recette(
      nom: _nomCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      calories: _totalCalories,
      repasId: null, // recette indépendante
      utilisateurId: widget.utilisateurId,
      publie: 0,
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
              'Nouvelle Recette',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildField(_nomCtrl, 'Nom de la recette', Icons.restaurant_menu),
            const SizedBox(height: 12),
            _buildField(_descCtrl, 'Description', Icons.description),
            const SizedBox(height: 20),
            _buildCaloriesSummary(),
            const Divider(height: 40),
            _buildIngredientsHeader(),
            const SizedBox(height: 12),
            ..._buildIngredientRows(),
            const SizedBox(height: 12),
            _buildAddIngredientButton(),
            const SizedBox(height: 28),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

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
                'Calories totales (auto)',
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          final caloric = Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.15),
              ),
            ),
            child: row.isEstimating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    row.calories?.toStringAsFixed(0) ?? '-',
                    style: TextStyle(
                      color: AppColors.textColor.withOpacity(0.6),
                    ),
                  ),
          );
          final estimateBtn = SizedBox(
            height: 56,
            width: 40,
            child: IconButton(
              tooltip: 'Estimer',
              icon: Icon(
                row.isEstimating ? Icons.hourglass_bottom : Icons.flash_on,
                size: 20,
                color: AppColors.accentColor,
              ),
              onPressed: () => _estimateRowCalories(index),
            ),
          );
          final removeBtn = SizedBox(
            height: 56,
            width: 40,
            child: IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.close, size: 20, color: Colors.redAccent),
              onPressed: () => _removeRow(index),
            ),
          );
          if (isNarrow) {
            final fieldWidth = (constraints.maxWidth / 2) - 14;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: _smallField(row.nom, 'Nom', Icons.eco),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _smallField(
                    row.quantite,
                    'Quantité',
                    Icons.scale,
                    isNum: true,
                  ),
                ),
                SizedBox(width: fieldWidth, child: _unitDropdown(row)),
                SizedBox(width: fieldWidth, child: caloric),
                estimateBtn,
                removeBtn,
              ],
            );
          }
          return Row(
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
              const SizedBox(width: 4),
              Expanded(flex: 2, child: caloric),
              estimateBtn,
              removeBtn,
            ],
          );
        },
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
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget _buildAddIngredientButton() => Align(
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: _addRow,
          icon: const Icon(
            Icons.add_circle_outline,
            color: AppColors.primaryColor,
          ),
          label: const Text(
            'Ajouter un ingrédient',
            style: TextStyle(color: AppColors.primaryColor),
          ),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: _estimateAll,
          icon: const Icon(Icons.flash_auto, color: AppColors.accentColor),
          label: const Text(
            'Tout estimer',
            style: TextStyle(color: AppColors.accentColor),
          ),
        ),
      ],
    ),
  );

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
}

class IngredientInputRow {
  final TextEditingController nom = TextEditingController();
  final TextEditingController quantite = TextEditingController();
  String? unite;
  double? calories;
  bool isEstimating = false;
}
