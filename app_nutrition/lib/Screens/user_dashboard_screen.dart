import 'package:flutter/material.dart';
import 'dart:io';
import '../Entites/utilisateur.dart';
import '../Entites/user_objective.dart';
import '../Services/database_helper.dart';
import '../Services/theme_service.dart';
import '../main.dart';
import 'profil_screen.dart';
import 'create_user_objective_screen.dart';
import '../l10n/app_localizations.dart';
import 'repas_module_main_screen.dart';
import '../Services/repas_service.dart';
import '../Services/session_service.dart';
import 'user_physical_activities_screen.dart';
import 'training_expenses_module_screen.dart';
import 'expenses_tracker_module_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserDashboardScreen({Key? key, required this.utilisateur})
    : super(key: key);

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  List<UserObjective> _userObjectives = [];
  double _calorieGoal = 2000; // objectif calorique dynamique

  // La carte affiche uniquement les calories ; supprimer les champs non utilisés pour éviter les lints
  Map<String, double> _dailyGoals = {'calories': 0};

  double _caloriesToday = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadDashboardData();
    _fetchCaloriesToday();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Charger les objectifs de l'utilisateur
      final objectives = await _db.getUserObjectives(widget.utilisateur.id!);

      setState(() {
        _userObjectives = objectives;
        _isLoading = false;
      });

      _recomputeCalorieGoal();

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorLoading ?? 'Erreur lors du chargement'}: $e',
            ),
          ),
        );
      }
    }
  }

  void _recomputeCalorieGoal() {
    if (_userObjectives.isEmpty) {
      setState(() => _calorieGoal = 2000);
      return;
    }
    // Choix objectif actif (non atteint le plus récent) sinon premier
    UserObjective obj = _userObjectives.first;
    final nonAtteints = _userObjectives.where((o) => !o.estAtteint).toList();
    if (nonAtteints.isNotEmpty) {
      nonAtteints.sort((a, b) => b.dateDebut.compareTo(a.dateDebut));
      obj = nonAtteints.first;
    }
    final poids = obj.poidsActuel;
    final tailleCm = obj.taille * 100.0; // taille en mètres -> cm
    final age = obj.age;
    double bmr = 10 * poids + 6.25 * tailleCm - 5 * age + 5; // Mifflin simple
    if (bmr < 800 || bmr.isNaN || bmr.isInfinite) bmr = 1500;
    // Facteur activité basique
    final niveau = obj.niveauActivite.toLowerCase();
    double facteur = 1.2;
    if (niveau.contains('leger') || niveau.contains('faible'))
      facteur = 1.375;
    else if (niveau.contains('mod'))
      facteur = 1.55;
    else if (niveau.contains('intense') || niveau.contains('fort'))
      facteur = 1.725;
    else if (niveau.contains('tres') || niveau.contains('super'))
      facteur = 1.9;
    double tdee = bmr * facteur;
    final type = obj.typeObjectif.toLowerCase();
    if (type.contains('perte') || type.contains('maigr'))
      tdee *= 0.85; // déficit
    else if (type.contains('prise') ||
        type.contains('muscle') ||
        type.contains('masse'))
      tdee *= 1.10; // surplus
    if (tdee < 1000) tdee = 1000;
    if (tdee > 4000) tdee = 4000;
    final finalGoal = tdee.roundToDouble();

    // Détermination simple des macros dynamiques à partir du poids et des calories
    // Protéines : 1.6 g/kg, Lipides : 0.9 g/kg, Glucides : reste
    // Calories provenant protéines & lipides
    // caloriesProt & caloriesFat non utilisés pour affichage actuel
    // Calcul des glucides ignoré (non utilisé actuellement)

    setState(() {
      _calorieGoal = finalGoal;
      _dailyGoals['calories'] = _calorieGoal;
      // Macros calculées non affichées pour le moment
    });
  }

  Future<void> _fetchCaloriesToday() async {
    final session = SessionService();
    final user = await session.getLoggedInUser();
    if (user != null && user.id != null) {
      // Correction : filtrer par utilisateur
      final repasList = await RepasService().getRepasByDate(DateTime.now());
      setState(() {
        _caloriesToday = repasList.fold(
          0.0,
          (sum, r) => sum + r.caloriesTotales,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          _buildDailyNutritionCard(context),
                          const SizedBox(height: 24),
                          _buildHealthJournalCard(context),
                          const SizedBox(height: 24),
                          _buildMyMealsCard(context),
                          const SizedBox(height: 24),
                          _buildPhysicalActivitiesCard(context),
                          const SizedBox(height: 24),
                          _buildExpensesManagementCard(context),
                          const SizedBox(height: 24),
                          _buildMyObjectivesSection(context),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfilScreen(utilisateur: widget.utilisateur),
              ),
            );
            // Rafraîchir l'écran si des modifications ont été apportées
            if (result == true) {
              setState(() {
                // L'état sera mis à jour automatiquement
              });
            }
          },
          child: _buildAvatar(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (AppLocalizations.of(
                      context,
                    )?.greetingUser(widget.utilisateur.prenom)) ??
                    'Bonjour, ${widget.utilisateur.prenom} ! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)?.dashboardTagline ??
                    'Suivez vos objectifs au quotidien',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        _buildThemeToggleButton(),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            await _loadDashboardData();
            await _fetchCaloriesToday();
          },
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildThemeToggleButton() {
    return FutureBuilder<ThemeMode>(
      future: ThemeService.getThemeMode(),
      builder: (context, snapshot) {
        final currentTheme = snapshot.data ?? ThemeMode.light;
        final isDark = currentTheme == ThemeMode.dark;

        return IconButton(
          onPressed: () async {
            final newTheme = isDark ? ThemeMode.light : ThemeMode.dark;
            await ThemeService.setThemeMode(newTheme);
            AppThemeNotifier.changeTheme(newTheme);
            setState(() {});
          },
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
          tooltip: isDark
              ? (AppLocalizations.of(context)?.themeLightTooltip ??
                    'Activer le thème clair')
              : (AppLocalizations.of(context)?.themeDarkTooltip ??
                    'Activer le thème sombre'),
        );
      },
    );
  }

  Widget _buildDailyNutritionCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition du jour',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total aujourd'hui",
                        style: TextStyle(color: Colors.black87),
                      ),
                      Text(
                        '${_caloriesToday.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Objectif: ${_calorieGoal.toStringAsFixed(0)} kcal',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      _buildCaloriesProgressRow(_caloriesToday, _calorieGoal),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.orange),
                  tooltip:
                      'Calcul basé sur objectif (BMR + activité + ajustement)',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Objectif calorique'),
                        content: const Text(
                          'Votre objectif est estimé à partir de votre poids, taille, âge et niveau d\'activité. Il est ajusté selon le type d\'objectif (perte ou prise). Les macros sont distribuées automatiquement.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Section simplifiée: affichage seulement des calories (proteines/eau retirés)
          ],
        ),
      ),
    );
  }

  Widget _buildHealthJournalCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.pushNamed(context, '/journal'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.health_and_safety,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Journal de santé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consignez vos mesures et indicateurs vitaux',
                      style: TextStyle(fontSize: 14, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesProgressRow(double total, double goal) {
    if (goal <= 0) return const SizedBox.shrink();
    final pct = ((total / goal) * 100).clamp(0, 9999);
    Color pctColor;
    if (pct < 50) {
      pctColor = Colors.orangeAccent;
    } else if (pct < 90) {
      pctColor = Colors.orange; // proche de l'accent
    } else if (pct <= 110) {
      pctColor = Colors.green;
    } else {
      pctColor = Colors.redAccent;
    }
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (total / goal).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(pctColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: pctColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: pctColor.withOpacity(0.5)),
          ),
          child: Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              color: _accessibleOnColor(pctColor),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _accessibleOnColor(Color base) {
    final brightness =
        (base.red * 0.299 + base.green * 0.587 + base.blue * 0.114) / 255;
    return brightness > 0.75 ? Colors.black87 : base;
  }

  Widget _buildMyObjectivesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.myObjectivesTitle ?? 'Mes Objectifs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _userObjectives.isEmpty
            ? _buildEmptyObjectivesCard()
            : _buildObjectivesList(),
      ],
    );
  }

  Widget _buildEmptyObjectivesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.track_changes,
            size: 48,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)?.noObjectiveTitle ?? 'Aucun objectif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.noObjectiveSubtitle ??
                'Créez votre premier objectif pour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.add, size: 32, color: Colors.green),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateUserObjectiveScreen(
                        utilisateur: widget.utilisateur,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadDashboardData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Objectif ajouté avec succès'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                tooltip: 'Ajouter un objectif',
                splashRadius: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectivesList() {
    return Column(
      children: _userObjectives.map((o) {
        // Progression basée sur les calories consommées aujourd'hui par rapport à l'objectif du jour
        final double ratio = (_calorieGoal <= 0)
            ? 0.0
            : (_caloriesToday / _calorieGoal);
        final double ratioClamped = ratio.clamp(0.0, 1.0);
        final String percentLabel = (ratio * 100)
            .clamp(0, 200)
            .toStringAsFixed(1);
        final Color barColor = ratio <= 1.0
            ? Colors.orangeAccent
            : Colors.redAccent;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      o.typeObjectif,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _editObjective(o);
                      } else if (val == 'delete') {
                        _deleteObjective(o);
                      }
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
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                o.description,
                style: TextStyle(color: Colors.white.withOpacity(0.85)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratioClamped,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$percentLabel%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Aujourd\'hui: ${_caloriesToday.toStringAsFixed(0)} / ${_calorieGoal.toStringAsFixed(0)} kcal  •  Poids actuel: ${o.poidsActuel} kg  •  Cible: ${o.poidsCible} kg  •  Jours restants: ${o.joursRestants}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMyMealsCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RepasModuleMainScreen(),
            ),
          );
          // Au retour, recharger les calories du jour et l'objectif dynamique
          await _fetchCaloriesToday();
          _recomputeCalorieGoal();
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gérer Mes repas',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Suivez et gérez vos repas et recettes',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Si l'utilisateur a une photo de profil, l'afficher
    if (widget.utilisateur.avatarPath != null &&
        widget.utilisateur.avatarPath!.isNotEmpty) {
      final file = File(widget.utilisateur.avatarPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: FileImage(file),
        );
      }
    }

    // Sinon, afficher les initiales avec couleur personnalisée
    final initials = widget.utilisateur.prenom.isNotEmpty
        ? widget.utilisateur.prenom[0].toUpperCase()
        : 'U';

    Color avatarColor = Colors.white.withOpacity(0.2);

    // Si l'utilisateur a une couleur personnalisée, l'utiliser
    if (widget.utilisateur.avatarColor != null &&
        widget.utilisateur.avatarColor!.isNotEmpty) {
      try {
        avatarColor = Color(
          int.parse(
            '0xff' + widget.utilisateur.avatarColor!.replaceFirst('#', ''),
          ),
        );
      } catch (e) {
        // En cas d'erreur, utiliser la couleur par défaut
        avatarColor = Colors.white.withOpacity(0.2);
      }
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: avatarColor,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _editObjective(UserObjective objective) async {
    // Navigation vers l'écran de création/modification d'objectif
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateUserObjectiveScreen(
          utilisateur: widget.utilisateur,
          existingObjective:
              objective, // Passer l'objectif existant pour modification
        ),
      ),
    );

    if (result == true) {
      _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.editObjectiveSuccess ??
                  'Objectif modifié avec succès',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildPhysicalActivitiesCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserPhysicalActivitiesScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes activités physiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Exercices, programme et progression',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteObjective(UserObjective objective) async {
    // Afficher une boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.deleteObjectiveTitle ??
              'Supprimer l\'objectif',
        ),
        content: Text(
          AppLocalizations.of(
                context,
              )?.deleteObjectiveConfirm(objective.typeObjectif) ??
              'Êtes-vous sûr de vouloir supprimer l\'objectif "${objective.typeObjectif}" ?\n\nCette action est irréversible.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Annuler',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context)?.delete ?? 'Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteUserObjective(objective.id!);
        _loadDashboardData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.deleteObjectiveSuccess ??
                    'Objectif supprimé avec succès',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.errorDeleting ?? 'Erreur lors de la suppression'}: $e',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Widget _buildExpensesManagementCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestion Financière',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingExpensesModuleScreen(),
                      ),
                    );
                  },
                  child: _buildFinanceModuleButton(
                    icon: Icons.calendar_month,
                    title: 'Plans &\nBudgets',
                    color: Colors.blue,
                    context: context,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpensesTrackerModuleScreen(),
                      ),
                    );
                  },
                  child: _buildFinanceModuleButton(
                    icon: Icons.wallet,
                    title: 'Suivi\nDépenses',
                    color: Colors.orange,
                    context: context,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceModuleButton({
    required IconData icon,
    required String title,
    required Color color,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
