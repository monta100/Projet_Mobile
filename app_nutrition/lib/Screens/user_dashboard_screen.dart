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

  // Données nutritionnelles simulées pour la page d'accueil
  Map<String, double> _dailyNutrition = {
    'calories': 1850,
    'proteins': 120,
    'carbs': 200,
    'fats': 65,
    'water': 1.8,
  };

  Map<String, double> _dailyGoals = {
    'calories': 2000,
    'proteins': 150,
    'carbs': 250,
    'fats': 70,
    'water': 2.5,
  };

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
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildNutritionOverview(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildObjectivesSection(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          onPressed: _loadDashboardData,
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

  Widget _buildNutritionOverview() {
    final caloriesProgress =
        _dailyNutrition['calories']! / _dailyGoals['calories']!;
    final proteinsProgress =
        _dailyNutrition['proteins']! / _dailyGoals['proteins']!;
    final waterProgress = _dailyNutrition['water']! / _dailyGoals['water']!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.dailyNutritionTitle ??
                    'Nutrition du jour',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildNutritionProgressItem(
            AppLocalizations.of(context)?.caloriesLabel ?? 'Calories',
            '${_dailyNutrition['calories']!.toInt()}',
            '${_dailyGoals['calories']!.toInt()} kcal',
            caloriesProgress,
            Colors.orange,
            Icons.local_fire_department,
          ),
          const SizedBox(height: 16),
          _buildNutritionProgressItem(
            AppLocalizations.of(context)?.proteinsLabel ?? 'Protéines',
            '${_dailyNutrition['proteins']!.toInt()}',
            '${_dailyGoals['proteins']!.toInt()}g',
            proteinsProgress,
            Colors.red,
            Icons.fitness_center,
          ),
          const SizedBox(height: 16),
          _buildNutritionProgressItem(
            AppLocalizations.of(context)?.waterLabel ?? 'Eau',
            '${(_dailyNutrition['water']! * 10).toInt() / 10}',
            '${_dailyGoals['water']!.toInt()}L',
            waterProgress,
            Colors.blue,
            Icons.water_drop,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionProgressItem(
    String label,
    String current,
    String goal,
    double progress,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : null,
                  ),
                ),
              ],
            ),
            Text(
              '$current / $goal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildObjectivesSection() {
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
            : Column(
                children: _userObjectives
                    .map((objective) => _buildObjectiveCard(objective))
                    .toList(),
              ),
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
        ],
      ),
    );
  }

  Widget _buildObjectiveCard(UserObjective objective) {
    final progress = objective.progressionPourcentage / 100;
    final isCompleted = objective.estAtteint;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.track_changes,
                  color: isCompleted ? Colors.green : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      objective.typeObjectif,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                    Text(
                      '${objective.poidsActuel}kg → ${objective.poidsCible}kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Icônes d'action (modifier et supprimer)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône modifier
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _editObjective(objective),
                  ),
                  const SizedBox(width: 8),
                  // Icône supprimer
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteObjective(objective),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression: ${objective.progressionPourcentage.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey.shade600,
                ),
              ),
              Text(
                '${objective.joursRestants} jours restants',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.newObjectiveTitle ?? 'Nouvel objectif',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          AppLocalizations.of(context)?.createObjectiveTitle ??
              'Créer un objectif',
          AppLocalizations.of(context)?.createObjectiveSubtitle ??
              'Définissez vos objectifs personnalisés',
          Icons.add_circle_outline,
          Colors.green,
          () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CreateUserObjectiveScreen(utilisateur: widget.utilisateur),
              ),
            );
            if (result == true) {
              _loadDashboardData();
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey.shade600,
              size: 20,
            ),
          ],
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
}
