// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, no_leading_underscores_for_local_identifiers, prefer_final_fields

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../Services/repas_service.dart';
import '../Entites/repas.dart';
import 'recette_with_ingredients_screen.dart';
import '../Services/nutrition_ai_service.dart';

// --- Palette de couleurs et Thème ---
class AppColors {
  static const Color primaryColor = Color(0xFF43A047);
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color accentColor = Color(0xFFFFA726);
  static const Color backgroundColor = Color(0xFFF4F6F8);
  static const Color textColor = Color(0xFF263238);
}

enum FilterPeriod { day, week, month, all }

// --- Écran principal ---
class RepasListScreen extends StatefulWidget {
  const RepasListScreen({Key? key}) : super(key: key);
  @override
  _RepasListScreenState createState() => _RepasListScreenState();
}

class _RepasListScreenState extends State<RepasListScreen>
    with TickerProviderStateMixin {
  final RepasService _repasService = RepasService();
  final NutritionAIService _nutritionService = NutritionAIService();
  late Future<List<Repas>> _repasList;

  // États des filtres et du tri
  String _selectedFilterType = 'Tous';
  FilterPeriod _dateScope = FilterPeriod.all;
  DateTime _anchorDate = DateTime.now();
  bool _sortDesc = true;

  // Contrôleurs d'animation
  late AnimationController _fabController;
  late AnimationController _listAnimationController;

  static const double _dailyGoal = 2000;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadRepas();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  void _loadRepas() {
    setState(() {
      _repasList = _repasService.getAllRepas();
      _listAnimationController.forward(from: 0.0);
    });
  }

  // --- Logique de filtrage et de tri ---
  List<Repas> _applyFilters(List<Repas> input) {
    DateTime start, end;
    switch (_dateScope) {
      case FilterPeriod.day:
        start = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
        end = start.add(const Duration(days: 1));
        break;
      case FilterPeriod.week:
        start = _anchorDate.subtract(Duration(days: _anchorDate.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 7));
        break;
      case FilterPeriod.month:
        start = DateTime(_anchorDate.year, _anchorDate.month, 1);
        end = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
        break;
      case FilterPeriod.all:
        start = DateTime.fromMillisecondsSinceEpoch(0);
        end = DateTime(3000);
    }

    final filtered = input.where((repas) {
      final isTypeMatch =
          _selectedFilterType == 'Tous' || repas.type == _selectedFilterType;
      final isDateMatch =
          _dateScope == FilterPeriod.all ||
          (!repas.date.isBefore(start) && repas.date.isBefore(end));
      return isTypeMatch && isDateMatch;
    }).toList();

    filtered.sort(
      (a, b) => _sortDesc ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );
    return filtered;
  }

  // --- Construction de l'UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => _loadRepas(),
        color: AppColors.primaryColor,
        child: CustomScrollView(
          slivers: [
            _buildHeaderSliver(),
            _buildDateFilterSliver(),
            _buildTypeFilterSliver(),
            _buildRepasList(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeaderSliver() {
    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor, AppColors.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: -80,
                right: -80,
                child: Icon(
                  Icons.restaurant,
                  size: 200,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mes Repas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Suivez votre nutrition au quotidien',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      _buildTodayCaloriesSliver(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCaloriesSliver() {
    return FutureBuilder<List<Repas>>(
      future: _repasList,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final today = DateTime.now();
        final totalToday = (snapshot.data ?? [])
            .where(
              (r) =>
                  r.date.year == today.year &&
                  r.date.month == today.month &&
                  r.date.day == today.day,
            )
            .fold<double>(0, (s, r) => s + r.caloriesTotales);
        final progress = (totalToday / _dailyGoal).clamp(0.0, 1.0);

        return _TodayCaloriesBanner(
          total: totalToday,
          goal: _dailyGoal,
          progress: progress,
        );
      },
    );
  }

  Widget _buildDateFilterSliver() {
    String label;
    if (_dateScope == FilterPeriod.all) {
      label = 'Toutes les dates';
    } else {
      final d = _anchorDate;
      if (_dateScope == FilterPeriod.day)
        label = _fmtDate(d);
      else if (_dateScope == FilterPeriod.week) {
        final start = d.subtract(Duration(days: d.weekday - 1));
        final end = start.add(const Duration(days: 6));
        label = 'Sem. ${_fmtDate(start)} - ${_fmtDate(end)}';
      } else {
        label = '${_monthName(d.month)} ${d.year}';
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.calendar_today,
                color: AppColors.textColor.withOpacity(0.7),
              ),
              onPressed: _selectDate,
            ),
            IconButton(
              icon: Icon(
                Icons.swap_vert,
                color: AppColors.textColor.withOpacity(0.7),
              ),
              onPressed: () => setState(() => _sortDesc = !_sortDesc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterSliver() {
    final types = ['Tous', 'Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'];
    final periods = {
      FilterPeriod.day: 'Jour',
      FilterPeriod.week: 'Semaine',
      FilterPeriod.month: 'Mois',
      FilterPeriod.all: 'Tout',
    };

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverFilterDelegate(
        child: Container(
          color: AppColors.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              ...types.map(
                (type) => _buildFilterChip(
                  type,
                  isSelected: _selectedFilterType == type,
                  onSelected: () => setState(() => _selectedFilterType = type),
                ),
              ),
              const VerticalDivider(width: 24, indent: 8, endIndent: 8),
              ...periods.entries.map(
                (entry) => _buildFilterChip(
                  entry.value,
                  isSelected: _dateScope == entry.key,
                  isAccent: true,
                  onSelected: () => setState(() => _dateScope = entry.key),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepasList() {
    return FutureBuilder<List<Repas>>(
      future: _repasList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: _LoadingAnimation()),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: _buildErrorState(snapshot.error.toString()),
          );
        }
        final repasList = _applyFilters(snapshot.data ?? []);
        if (repasList.isEmpty) {
          return const SliverFillRemaining(child: _EmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return AnimatedBuilder(
                animation: _listAnimationController,
                builder: (context, child) {
                  final delay = (index * 100).clamp(0, 500);
                  final animation = CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      (delay / 1000),
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: Transform.translate(
                      offset: Offset(0, 50 * (1 - animation.value)),
                      child: child,
                    ),
                  );
                },
                child: _buildRepasCard(repasList[index]),
              );
            }, childCount: repasList.length),
          ),
        );
      },
    );
  }

  Widget _buildRepasCard(Repas repas) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRepasOptions(repas),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getRepasIcon(repas.type),
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repas.nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${repas.type} • ${_fmtDate(repas.date)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${repas.caloriesTotales.toInt()} kcal',
                    style: const TextStyle(
                      color: AppColors.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Méthodes utilitaires et modales ---
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        _anchorDate = picked;
        _dateScope = FilterPeriod.day;
      });
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  String _monthName(int m) => [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ][m - 1];

  Widget _buildFilterChip(
    String label, {
    required bool isSelected,
    required VoidCallback onSelected,
    bool isAccent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white,
        selectedColor: isAccent
            ? AppColors.accentColor.withOpacity(0.15)
            : AppColors.primaryColor.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected
              ? (isAccent ? AppColors.accentColor : AppColors.primaryColor)
              : AppColors.textColor.withOpacity(0.7),
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected
              ? (isAccent ? AppColors.accentColor : AppColors.primaryColor)
              : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddRepasDialog,
      backgroundColor: AppColors.primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
      elevation: 4,
      shape: const CircleBorder(),
    );
  }

  void _showAddRepasDialog() {
    _fabController.forward();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddRepasModal(),
    ).then((_) {
      _fabController.reverse();
      _loadRepas();
    });
  }

  Widget _buildAddRepasModal() {
    final nomController = TextEditingController();
    String selectedType = 'Déjeuner';
    bool isCalculating = false;
    double? estimatedCalories;

    return StatefulBuilder(
      builder: (context, setStateModal) {
        Future<void> _calculateCalories() async {
          final dish = nomController.text.trim();
          if (dish.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Veuillez entrer un nom de repas.")),
            );
            return;
          }
          setStateModal(() {
            isCalculating = true;
            estimatedCalories = null;
          });
          final kcal = await _nutritionService.estimateCalories(dish);
          setStateModal(() {
            isCalculating = false;
            estimatedCalories = kcal > 0 ? kcal : null;
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  'Ajouter un nouveau repas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 30),
                _buildCustomTextField(
                  nomController,
                  'Nom du repas',
                  Icons.restaurant,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Type de repas",
                      prefixIcon: Icon(
                        Icons.category,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Petit-déjeuner',
                        child: Text('🥐 Petit-déjeuner'),
                      ),
                      DropdownMenuItem(
                        value: 'Déjeuner',
                        child: Text('🍽️ Déjeuner'),
                      ),
                      DropdownMenuItem(value: 'Dîner', child: Text('🌙 Dîner')),
                      DropdownMenuItem(
                        value: 'Collation',
                        child: Text('🍎 Collation'),
                      ),
                    ],
                    onChanged: (value) =>
                        setStateModal(() => selectedType = value!),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isCalculating ? null : _calculateCalories,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                  ),
                  label: Text(
                    isCalculating
                        ? 'Calcul en cours...'
                        : 'Calculer les calories',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                if (estimatedCalories != null)
                  AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'Calories estimées : ${estimatedCalories!.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                const Spacer(),
                _buildCustomButton('Ajouter le repas', () async {
                  final nom = nomController.text.trim();
                  if (nom.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Veuillez remplir tous les champs obligatoires.',
                        ),
                      ),
                    );
                    return;
                  }
                  final calories = estimatedCalories ?? 0;
                  final newRepas = Repas(
                    nom: nom,
                    type: selectedType,
                    date: DateTime.now(),
                    caloriesTotales: calories,
                    utilisateurId: 1,
                  );
                  await _repasService.insertRepas(newRepas);
                  _loadRepas();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      content: Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Repas ajouté avec succès ! 🎉',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildCustomButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, AppColors.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRepasOptions(Repas repas) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                repas.nom,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildOptionButton(
                'Recettes & Ingrédients',
                Icons.restaurant_menu,
                AppColors.accentColor,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RecetteWithIngredientsScreen(repasId: repas.id!),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                'Modifier le repas',
                Icons.edit,
                AppColors.secondaryColor,
                () {
                  Navigator.pop(context);
                  _showEditRepasModal(repas);
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                'Supprimer le repas',
                Icons.delete_outline,
                Colors.redAccent,
                () {
                  Navigator.pop(context);
                  _confirmDeleteRepas(repas.id!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditRepasModal(Repas repas) {
    final nomController = TextEditingController(text: repas.nom);
    final typeController = TextEditingController(text: repas.type);
    final caloriesController = TextEditingController(
      text: repas.caloriesTotales.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              Text(
                'Modifier le repas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 30),
              _buildCustomTextField(
                nomController,
                'Nom du repas',
                Icons.restaurant,
              ),
              const SizedBox(height: 20),
              _buildCustomTextField(
                typeController,
                'Type de repas',
                Icons.category,
              ),
              const SizedBox(height: 20),
              _buildCustomTextField(
                caloriesController,
                'Calories',
                Icons.local_fire_department,
                isNumber: true,
              ),
              const Spacer(),
              _buildCustomButton('Enregistrer les modifications', () async {
                final updatedRepas = repas.copyWith(
                  nom: nomController.text.trim(),
                  type: typeController.text.trim(),
                  caloriesTotales:
                      double.tryParse(caloriesController.text) ??
                      repas.caloriesTotales,
                );
                await _repasService.updateRepas(updatedRepas);
                _loadRepas();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Repas modifié avec succès !')),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRepas(int repasId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le repas'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce repas ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _repasService.deleteRepas(repasId);
              Navigator.pop(context);
              _loadRepas();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Repas supprimé avec succès !')),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Text('Erreur: $error'));
  }

  IconData _getRepasIcon(String type) {
    switch (type.toLowerCase()) {
      case 'petit-déjeuner':
        return Icons.free_breakfast;
      case 'déjeuner':
        return Icons.lunch_dining;
      case 'dîner':
        return Icons.dinner_dining;
      default:
        return Icons.fastfood;
    }
  }
}

// --- Widgets de support ---
class _SliverFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverFilterDelegate({required this.child});
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: shrinkOffset > 0 ? 4 : 0,
      shadowColor: Colors.black.withOpacity(0.1),
      child: child,
    );
  }

  @override
  double get maxExtent => 56.0;
  @override
  double get minExtent => 56.0;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class _TodayCaloriesBanner extends StatelessWidget {
  final double total, goal, progress;
  const _TodayCaloriesBanner({
    required this.total,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) => CustomPaint(
                painter: _CaloriesRingPainter(value),
                child: Center(
                  child: Text(
                    '${(value * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Total aujourd'hui",
                  style: TextStyle(color: AppColors.textColor),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: total),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) => Text(
                    '${value.toInt()} kcal',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Objectif: ${goal.toInt()} kcal',
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesRingPainter extends CustomPainter {
  final double progress;
  _CaloriesRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 6.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      rect.center,
      rect.width / 2 - stroke / 2,
      paint..color = AppColors.primaryColor.withOpacity(0.1),
    );

    final angle = 2 * math.pi * progress;
    final colors = [AppColors.accentColor, AppColors.primaryColor];
    final gradient = SweepGradient(
      colors: colors,
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + angle,
      transform: GradientRotation(math.pi * 1.5),
    );

    canvas.drawArc(
      Rect.fromCircle(center: rect.center, radius: rect.width / 2 - stroke / 2),
      -math.pi / 2,
      angle,
      false,
      paint..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LoadingAnimation extends StatelessWidget {
  const _LoadingAnimation();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.primaryColor),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucun repas trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un repas pour commencer',
            style: TextStyle(color: AppColors.textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
