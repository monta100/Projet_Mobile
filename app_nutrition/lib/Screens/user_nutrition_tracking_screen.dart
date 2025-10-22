import 'package:flutter/material.dart';
import 'dart:math';
import '../Entites/utilisateur.dart';
import '../Entites/objectif.dart';
import '../Entites/user_objective.dart';
import '../Services/database_helper.dart';
import '../Services/objectif_service.dart';
import 'create_user_objective_screen.dart';

class UserNutritionTrackingScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserNutritionTrackingScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserNutritionTrackingScreen> createState() => _UserNutritionTrackingScreenState();
}

class _UserNutritionTrackingScreenState extends State<UserNutritionTrackingScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final ObjectifService _objectifService = ObjectifService();
  
  List<Objectif> _objectifs = [];
  List<UserObjective> _userObjectives = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  // Données nutritionnelles simulées
  Map<String, double> _dailyNutrition = {
    'calories': 1850,
    'proteins': 120,
    'carbs': 200,
    'fats': 65,
    'fiber': 25,
    'water': 1.8,
  };
  
  Map<String, double> _dailyGoals = {
    'calories': 2000,
    'proteins': 150,
    'carbs': 250,
    'fats': 70,
    'fiber': 30,
    'water': 2.5,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _loadObjectifs();
    _loadUserObjectives();
    _startPulseAnimation();
  }
  
  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadObjectifs() async {
    setState(() => _isLoading = true);
    try {
      final objectifs = await _db.getObjectifsByUtilisateur(widget.utilisateur.id!);
      setState(() {
        _objectifs = objectifs;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _loadUserObjectives() async {
    try {
      final userObjectives = await _db.getUserObjectives(widget.utilisateur.id!);
      setState(() {
        _userObjectives = userObjectives;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des objectifs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: _buildTabContent(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
            Colors.teal.shade600,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${widget.utilisateur.prenom} !',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suivez votre nutrition quotidienne',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildQuickStats(),
        ],
      ),
    );
  }
  
  Widget _buildQuickStats() {
    final caloriesProgress = _dailyNutrition['calories']! / _dailyGoals['calories']!;
    final waterProgress = _dailyNutrition['water']! / _dailyGoals['water']!;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Calories',
            '${_dailyNutrition['calories']!.toInt()}',
            '${_dailyGoals['calories']!.toInt()}',
            caloriesProgress,
            Colors.orange,
            Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Eau',
            '${(_dailyNutrition['water']! * 10).toInt() / 10}L',
            '${_dailyGoals['water']!.toInt()}L',
            waterProgress,
            Colors.blue,
            Icons.water_drop,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String current, String goal, double progress, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'sur $goal',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem('Aujourd\'hui', 0, Icons.today),
          _buildTabItem('Macros', 1, Icons.analytics),
          _buildTabItem('Objectifs', 2, Icons.track_changes),
          _buildTabItem('Conseils', 3, Icons.lightbulb),
        ],
      ),
    );
  }
  
  Widget _buildTabItem(String title, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildTodayTab();
      case 1:
        return _buildMacrosTab();
      case 2:
        return _buildObjectivesTab();
      case 3:
        return _buildTipsTab();
      default:
        return _buildTodayTab();
    }
  }

  Widget _buildTodayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMealSection('Petit-déjeuner', '07:00', [
            {'name': 'Avoine', 'calories': 150, 'icon': '🥣'},
            {'name': 'Banane', 'calories': 90, 'icon': '🍌'},
            {'name': 'Lait', 'calories': 120, 'icon': '🥛'},
          ]),
          _buildMealSection('Déjeuner', '12:30', [
            {'name': 'Salade César', 'calories': 350, 'icon': '🥗'},
            {'name': 'Poulet grillé', 'calories': 200, 'icon': '🍗'},
            {'name': 'Pain complet', 'calories': 80, 'icon': '🍞'},
          ]),
          _buildMealSection('Collation', '16:00', [
            {'name': 'Pomme', 'calories': 80, 'icon': '🍎'},
            {'name': 'Amandes', 'calories': 160, 'icon': '🥜'},
          ]),
          _buildMealSection('Dîner', '19:30', [
            {'name': 'Saumon', 'calories': 250, 'icon': '🐟'},
            {'name': 'Riz complet', 'calories': 150, 'icon': '🍚'},
            {'name': 'Brocolis', 'calories': 50, 'icon': '🥦'},
          ]),
          const SizedBox(height: 20),
          _buildAddMealButton(),
        ],
      ),
    );
  }
  
  Widget _buildMealSection(String mealName, String time, List<Map<String, dynamic>> foods) {
    final totalCalories = foods.fold<int>(0, (sum, food) => sum + (food['calories'] as int));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                mealName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...foods.map((food) => _buildFoodItem(food)).toList(),
          const Divider(),
          Row(
            children: [
              const Text(
                'Total: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalCalories cal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFoodItem(Map<String, dynamic> food) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            food['icon'],
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              food['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${food['calories']} cal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddMealButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Ajouter un repas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMacroCard('Protéines', _dailyNutrition['proteins']!, _dailyGoals['proteins']!, Colors.red, Icons.fitness_center),
          _buildMacroCard('Glucides', _dailyNutrition['carbs']!, _dailyGoals['carbs']!, Colors.blue, Icons.grain),
          _buildMacroCard('Lipides', _dailyNutrition['fats']!, _dailyGoals['fats']!, Colors.orange, Icons.opacity),
          _buildMacroCard('Fibres', _dailyNutrition['fiber']!, _dailyGoals['fiber']!, Colors.green, Icons.eco),
          const SizedBox(height: 20),
          _buildMacroChart(),
        ],
      ),
    );
  }
  
  Widget _buildMacroCard(String name, double current, double goal, Color color, IconData icon) {
    final progress = current / goal;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${current.toInt()}g / ${goal.toInt()}g',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition des Macros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildMacroBar('Protéines', 0.3, Colors.red),
          _buildMacroBar('Glucides', 0.5, Colors.blue),
          _buildMacroBar('Lipides', 0.2, Colors.orange),
        ],
      ),
    );
  }
  
  Widget _buildMacroBar(String name, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectivesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserObjectivesSection(),
          const SizedBox(height: 20),
          _buildQuickActions(),
        ],
      ),
    );
  }
  
  Widget _buildUserObjectivesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes Objectifs Personnalisés',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _userObjectives.isEmpty
            ? _buildEmptyUserObjectives()
            : Column(
                children: _userObjectives.map((objective) => _buildUserObjectiveCard(objective)).toList(),
              ),
      ],
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Créer un Objectif',
                'Objectif personnalisé avec coach',
                Icons.add_circle,
                Colors.blue,
                _createUserObjective,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Conseils Nutrition',
                'Découvrir des astuces',
                Icons.lightbulb,
                Colors.orange,
                _showNutritionTips,
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyUserObjectives() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.track_changes,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun objectif personnalisé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier objectif personnalisé avec un coach',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createUserObjective,
            icon: const Icon(Icons.add),
            label: const Text('Créer un objectif'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserObjectiveCard(UserObjective objective) {
    final isCompleted = objective.estAtteint;
    final isOverdue = objective.estEnRetard;
    final progress = objective.progressionPourcentage / 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.shade200 
              : isOverdue 
                  ? Colors.red.shade200 
                  : Colors.grey.shade200,
          width: isCompleted || isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green 
                      : isOverdue 
                          ? Colors.red 
                          : Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted 
                      ? Icons.check_circle 
                      : isOverdue 
                          ? Icons.warning 
                          : Icons.track_changes,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      objective.typeObjectif,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${objective.poidsActuel}kg → ${objective.poidsCible}kg',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Durée: ${objective.dureeFormatted}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Atteint !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'En retard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted 
                        ? Colors.green 
                        : isOverdue 
                            ? Colors.red 
                            : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${objective.progressionPourcentage.toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IMC: ${objective.imcActuelFormatted} → ${objective.imcCibleFormatted}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (!isCompleted && !isOverdue)
                Text(
                  '${objective.joursRestants} jours restants',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _createUserObjective() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateUserObjectiveScreen(utilisateur: widget.utilisateur),
      ),
    );
    
    if (result == true) {
      _loadUserObjectives();
    }
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNutritionTips(),
        ],
      ),
    );
  }
  
  Widget _buildNutritionTips() {
    final tips = [
      {
        'title': 'Hydratation Optimale',
        'tip': 'Buvez 2-3 litres d\'eau par jour, surtout avant et après l\'exercice. L\'eau aide à réguler la température corporelle et transporte les nutriments.',
        'icon': '💧',
        'color': Colors.blue,
      },
      {
        'title': 'Équilibre Alimentaire',
        'tip': 'Suivez la règle des 5 portions : 3 portions de légumes et 2 portions de fruits par jour pour un apport optimal en vitamines.',
        'icon': '🥗',
        'color': Colors.green,
      },
      {
        'title': 'Protéines Essentielles',
        'tip': 'Consommez 1.2-1.6g de protéines par kg de poids corporel. Sources : viande, poisson, œufs, légumineuses, produits laitiers.',
        'icon': '🥩',
        'color': Colors.orange,
      },
      {
        'title': 'Rythme Alimentaire',
        'tip': 'Mangez toutes les 3-4 heures pour maintenir un métabolisme stable et éviter les fringales.',
        'icon': '⏰',
        'color': Colors.purple,
      },
      {
        'title': 'Glucides Intelligents',
        'tip': 'Privilégiez les glucides complexes (céréales complètes, légumineuses) plutôt que les sucres simples.',
        'icon': '🍞',
        'color': Colors.brown,
      },
      {
        'title': 'Graisses Saines',
        'tip': 'Incluez des graisses insaturées : avocat, noix, huile d\'olive, poissons gras pour la santé cardiovasculaire.',
        'icon': '🥑',
        'color': Colors.teal,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conseils Nutrition',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => _buildTipCard(tip)).toList(),
      ],
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (tip['color'] as Color).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (tip['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              tip['icon'],
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (tip['color'] as Color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['tip'],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddObjectiveDialog() {
    final typeController = TextEditingController();
    final valeurController = TextEditingController();
    final progressionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvel Objectif Nutritionnel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Type d\'objectif',
                hintText: 'Ex: Perte de poids, Gain musculaire...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valeurController,
              decoration: const InputDecoration(
                labelText: 'Valeur cible',
                hintText: 'Ex: 5.0 (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: progressionController,
              decoration: const InputDecoration(
                labelText: 'Progression actuelle',
                hintText: 'Ex: 1.5 (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (typeController.text.isNotEmpty &&
                  valeurController.text.isNotEmpty &&
                  progressionController.text.isNotEmpty) {
                final objectif = Objectif(
                  utilisateurId: widget.utilisateur.id!,
                  type: typeController.text,
                  valeurCible: double.parse(valeurController.text),
                  dateFixee: DateTime.now().add(const Duration(days: 30)),
                  progression: double.parse(progressionController.text),
                );
                
                await _objectifService.creerObjectif(objectif);
                Navigator.pop(context);
                _loadObjectifs();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Objectif créé avec succès !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showNutritionTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Conseils Nutrition',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDetailedTip(
                      'Hydratation Optimale',
                      '💧',
                      'Buvez 2-3 litres d\'eau par jour, surtout avant et après l\'exercice. L\'eau aide à réguler la température corporelle et transporte les nutriments.',
                      Colors.blue,
                    ),
                    _buildDetailedTip(
                      'Équilibre Alimentaire',
                      '🥗',
                      'Suivez la règle des 5 portions : 3 portions de légumes et 2 portions de fruits par jour pour un apport optimal en vitamines.',
                      Colors.green,
                    ),
                    _buildDetailedTip(
                      'Protéines Essentielles',
                      '🥩',
                      'Consommez 1.2-1.6g de protéines par kg de poids corporel. Sources : viande, poisson, œufs, légumineuses, produits laitiers.',
                      Colors.orange,
                    ),
                    _buildDetailedTip(
                      'Rythme Alimentaire',
                      '⏰',
                      'Mangez toutes les 3-4 heures pour maintenir un métabolisme stable et éviter les fringales.',
                      Colors.purple,
                    ),
                    _buildDetailedTip(
                      'Glucides Intelligents',
                      '🍞',
                      'Privilégiez les glucides complexes (céréales complètes, légumineuses) plutôt que les sucres simples.',
                      Colors.brown,
                    ),
                    _buildDetailedTip(
                      'Graisses Saines',
                      '🥑',
                      'Incluez des graisses insaturées : avocat, noix, huile d\'olive, poissons gras pour la santé cardiovasculaire.',
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTip(String title, String emoji, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
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
