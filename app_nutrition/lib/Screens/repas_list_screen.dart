// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, no_leading_underscores_for_local_identifiers, prefer_final_fields

import 'package:flutter/material.dart';
import '../Services/repas_service.dart';
import '../Entites/repas.dart';
import 'recette_with_ingredients_screen.dart';
import '../Services/nutrition_ai_service.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF43A047);
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color accentColor = Color(0xFFFFA726);
  static const Color backgroundColor = Color(0xFFF4F6F8);
  static const Color textColor = Color(0xFF263238);
}

// === AJOUT ===
enum FilterPeriod { day, week, month, all }

class RepasListScreen extends StatefulWidget {
  const RepasListScreen({Key? key}) : super(key: key);
  @override
  _RepasListScreenState createState() => _RepasListScreenState();
}

class _RepasListScreenState extends State<RepasListScreen>
    with TickerProviderStateMixin {
  DateTime? _selectedDate;
  final NutritionAIService _nutritionService = NutritionAIService();
  bool _isCalculatingCalories = false; // (réservé futur)
  double? _estimatedCalories; // (réservé futur)
  final RepasService _repasService = RepasService();
  late Future<List<Repas>> _repasList;
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  String _selectedFilter = 'Tous';

  // === AJOUT VARIABLES FILTRE DATE & TRI ===
  FilterPeriod _dateScope = FilterPeriod.all;
  DateTime _anchorDate = DateTime.now();
  bool _sortDesc = true;

  // === AJOUT : Objectif journalier ===
  static const double _dailyGoal = 2000; // Objectif journalier

  @override
  void initState() {
    super.initState();
    _loadRepas();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _loadRepas() {
    setState(() {
      _repasList = _repasService.getAllRepas();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _anchorDate = picked;
        _dateScope = FilterPeriod.day; // focus sur la journée choisie
      });
    }
  }

  // === AJOUT: Résumé période actuelle ===
  String _currentPeriodLabel() {
    if (_dateScope == FilterPeriod.all) return 'Toutes les dates';
    final d = _anchorDate;
    switch (_dateScope) {
      case FilterPeriod.day:
        return _fmtDate(d);
      case FilterPeriod.week:
        final start = d.subtract(Duration(days: d.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return 'Semaine du ${_fmtDate(start)} au ${_fmtDate(end)}';
      case FilterPeriod.month:
        return 'Mois de ${_monthName(d.month)} ${d.year}';
      case FilterPeriod.all:
        return 'Toutes les dates';
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  String _monthName(int m) {
    const noms = [
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
    ];
    return noms[m - 1];
  }

  // === AJOUT: Filtrage logique ===
  List<Repas> _applyFilters(List<Repas> input) {
    final typeFilter = _selectedFilter;
    DateTime start;
    DateTime end;
    if (_dateScope == FilterPeriod.day) {
      start = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
      end = start.add(const Duration(days: 1));
    } else if (_dateScope == FilterPeriod.week) {
      start = _anchorDate.subtract(Duration(days: _anchorDate.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = start.add(const Duration(days: 7));
    } else if (_dateScope == FilterPeriod.month) {
      start = DateTime(_anchorDate.year, _anchorDate.month, 1);
      end = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
    } else {
      start = DateTime.fromMillisecondsSinceEpoch(0);
      end = DateTime(2500);
    }

    final filtered = input.where((repas) {
      // Type
      if (typeFilter != 'Tous' && repas.type != typeFilter) return false;

      // Date string -> DateTime si nécessaire
      final DateTime d = repas.date;
      if (_dateScope != FilterPeriod.all) {
        if (d.isBefore(start) || !d.isBefore(end)) return false;
      }
      return true;
    }).toList();

    // Tri par date
    filtered.sort(
      (a, b) => _sortDesc ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );

    return filtered;
  }

  void _showAddRepasDialog() {
    _fabAnimationController.forward();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddRepasModal(),
    ).then((_) {
      _fabAnimationController.reverse();
      _loadRepas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildCustomAppBar(),
          _buildTodayCaloriesSliver(), // <== AJOUT
          _buildFilterChips(),
          _buildRepasList(),
        ],
      ),
      floatingActionButton: _buildCustomFAB(),
    );
  }

  // === AJOUT : Sliver bannière total calories du jour ===
  Widget _buildTodayCaloriesSliver() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Repas>>(
        future: _repasList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final list = snapshot.data ?? [];
          final today = DateTime.now();
          final totalToday = list
              .where(
                (r) =>
                    r.date.year == today.year &&
                    r.date.month == today.month &&
                    r.date.day == today.day,
              )
              .fold<double>(0, (s, r) => s + r.caloriesTotales);

          final progress = (totalToday / _dailyGoal).clamp(0, 1);

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: _TodayCaloriesBanner(
              total: totalToday,
              goal: _dailyGoal,
              progress: progress.toDouble(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return SliverAppBar(
      actions: [
        IconButton(
          icon: const Icon(Icons.swap_vert, color: Colors.white),
          tooltip: 'Trier (date)',
          onPressed: () => setState(() => _sortDesc = !_sortDesc),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month, color: Colors.white),
          onPressed: () => _selectDate(context),
          tooltip: 'Filtrer par date',
        ),
        IconButton(
          icon: const Icon(Icons.clear_all, color: Colors.white),
          tooltip: 'Réinitialiser filtres date',
          onPressed: () => setState(() {
            _dateScope = FilterPeriod.all;
            _selectedDate = null;
          }),
        ),
      ],
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryColor, AppColors.secondaryColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _headerAnimationController,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Mes Repas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gérez votre nutrition quotidienne',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
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

  Widget _buildFilterChips() {
    final filters = [
      'Tous',
      'Petit-déjeuner',
      'Déjeuner',
      'Dîner',
      'Collation',
    ];
    // ...existing code...

    // === AJOUT: seconde rangée pour plage temporelle + label période ===
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rangée types
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = _selectedFilter == filter;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryColor.withOpacity(0.1),
                    checkmarkColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.textColor.withOpacity(0.7),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                );
              },
            ),
          ),
          // Rangée période
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildPeriodChip(FilterPeriod.day, 'Jour'),
                _buildPeriodChip(FilterPeriod.week, 'Semaine'),
                _buildPeriodChip(FilterPeriod.month, 'Mois'),
                _buildPeriodChip(FilterPeriod.all, 'Tout'),
                const SizedBox(width: 12),
                _buildPeriodSummaryBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === AJOUT Widgets utilitaires période ===
  Widget _buildPeriodChip(FilterPeriod period, String label) {
    final isSelected = _dateScope == period;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _dateScope = period),
        backgroundColor: Colors.white,
        selectedColor: AppColors.accentColor.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.accentColor : AppColors.textColor,
          fontWeight: FontWeight.w600,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? AppColors.accentColor : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSummaryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(
            _currentPeriodLabel(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepasList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: FutureBuilder<List<Repas>>(
        future: _repasList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(
              child: Center(child: _LoadingAnimation()),
            );
          } else if (snapshot.hasError) {
            return SliverFillRemaining(
              child: _buildErrorState(snapshot.error.toString()),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SliverFillRemaining(child: _EmptyState());
          }
          final repasList = _applyFilters(snapshot.data!); // <= AJOUT filtre
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final repas = repasList[index];
              return Dismissible(
                key: ValueKey(repas.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                confirmDismiss: (_) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Supprimer ce repas ?'),
                      content: const Text(
                        'Voulez-vous vraiment supprimer ce repas ? Cette action est irréversible.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  return confirm ?? false;
                },
                onDismissed: (_) async {
                  await _repasService.deleteRepas(repas.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Repas "${repas.nom}" supprimé avec succès.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  _loadRepas();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildRepasCard(repas, index),
                ),
              );
            }, childCount: repasList.length),
          );
        },
      ),
    );
  }

  Widget _buildRepasCard(Repas repas, int index) {
    final colors = [
      [AppColors.primaryColor, AppColors.secondaryColor],
      [AppColors.secondaryColor, AppColors.accentColor],
      [AppColors.accentColor, AppColors.primaryColor],
    ];
    final cardColors = colors[index % colors.length];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showRepasOptions(repas),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _getRepasIcon(repas.type),
                        color: Colors.white,
                        size: 30,
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
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            repas.type,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${repas.caloriesTotales.toInt()} kcal',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Options',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
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

  Widget _buildCustomFAB() {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.8).animate(
        CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.easeInOut,
        ),
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentColor, AppColors.primaryColor],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _showAddRepasDialog,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      );
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
    return Center(
      child: Text('Erreur : $error', style: const TextStyle(color: Colors.red)),
    );
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
        return Icons.restaurant;
    }
  }
}

class _LoadingAnimation extends StatefulWidget {
  const _LoadingAnimation();
  @override
  __LoadingAnimationState createState() => __LoadingAnimationState();
}

class __LoadingAnimationState extends State<_LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Colors.transparent, AppColors.primaryColor],
              stops: const [0.0, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.backgroundColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: 60,
              color: AppColors.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun repas trouvé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par ajouter votre premier repas',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// === AJOUT : Widget bannière calories ===
class _TodayCaloriesBanner extends StatelessWidget {
  final double total;
  final double goal;
  final double progress;
  const _TodayCaloriesBanner({
    required this.total,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Container(
      height: 150, // ↑ hauteur légèrement augmentée
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFFFFA726)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            offset: const Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Décor bulles
          Positioned(
            top: -18,
            right: -18,
            child: _softCircle(110, Colors.white.withOpacity(.08)),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: _softCircle(80, Colors.white.withOpacity(.07)),
          ),
          // CHANGEMENT: remplacement de Positioned(... bottom:22 ...) par simple Padding
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CustomPaint(
                        painter: _CaloriesRingPainter(value),
                        child: Center(
                          child: Text(
                            '$pct%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total aujourd\'hui',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: total),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          '${value.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress > 1 ? 1 : progress,
                          minHeight: 6, // ↓ réduit
                          backgroundColor: Colors.white.withOpacity(.25),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1 ? Colors.orangeAccent : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Objectif: ${goal.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 14,
            child: Row(
              children: const [
                Icon(Icons.local_fire_department, color: Colors.white, size: 22),
                SizedBox(width: 4),
                Text('🔥', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCircle(double size, Color c) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c,
      boxShadow: [BoxShadow(color: c, blurRadius: 40, spreadRadius: 10)],
    ),
  );
}

/// === AJOUT : Painter pour anneau progressif ===
class _CaloriesRingPainter extends CustomPainter {
  final double progress;
  _CaloriesRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide / 2) - stroke / 2;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withOpacity(.25)
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        startAngle: -3.14 / 2,
        endAngle: 3.14 * 1.5,
        colors: const [
          Color(0xFFFFF59D),
          Color(0xFFFFCC80),
          Color(0xFFFFA726),
          Color(0xFFFFF59D),
        ],
        stops: const [0.0, .35, .7, 1.0],
        transform: const GradientRotation(-3.14 / 2),
      ).createShader(rect)
      ..strokeCap = StrokeCap.round;

    // Fond
    canvas.drawCircle(center, radius, bg);

    // Arc progressif
    final sweep = progress.clamp(0, 1) * 3.14159 * 2;
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        sweep,
      );
    canvas.drawPath(path, fg);
  }

  @override
  bool shouldRepaint(covariant _CaloriesRingPainter old) =>
      old.progress != progress;
}
