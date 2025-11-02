import 'package:flutter/material.dart';
import 'dart:math';
import '../Entites/utilisateur.dart';

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
  bool _isLoading = false;
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
    
    _animationController.forward();
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


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: FadeTransition(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem('Aujourd\'hui', 0, Icons.today),
          _buildTabItem('Macros', 1, Icons.analytics),
          _buildTabItem('Conseils', 2, Icons.lightbulb),
        ],
      ),
    );
  }
  
  Widget _buildTabItem(String title, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? Colors.grey[300] : Colors.grey.shade600),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? Colors.grey[300] : Colors.grey.shade600),
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
        return _buildTipsTab();
      default:
        return _buildTodayTab();
    }
  }

  Widget _buildTodayTab() {
    final totalCalories = _dailyNutrition['calories']!;
    final caloriesGoal = _dailyGoals['calories']!;
    final caloriesRemaining = (caloriesGoal - totalCalories).clamp(0.0, caloriesGoal);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Carte récapitulative du jour
          _buildDailySummaryCard(totalCalories, caloriesGoal, caloriesRemaining),
          const SizedBox(height: 20),
          // Sections de repas interactives
          _buildMealSection('Petit-déjeuner', '07:00', '🌅', [
            {'name': 'Avoine', 'calories': 150, 'icon': '🥣', 'proteins': 5, 'carbs': 27, 'fats': 3},
            {'name': 'Banane', 'calories': 90, 'icon': '🍌', 'proteins': 1, 'carbs': 23, 'fats': 0},
            {'name': 'Lait', 'calories': 120, 'icon': '🥛', 'proteins': 8, 'carbs': 12, 'fats': 5},
          ]),
          _buildMealSection('Déjeuner', '12:30', '☀️', [
            {'name': 'Salade César', 'calories': 350, 'icon': '🥗', 'proteins': 15, 'carbs': 20, 'fats': 25},
            {'name': 'Poulet grillé', 'calories': 200, 'icon': '🍗', 'proteins': 30, 'carbs': 0, 'fats': 9},
            {'name': 'Pain complet', 'calories': 80, 'icon': '🍞', 'proteins': 4, 'carbs': 15, 'fats': 1},
          ]),
          _buildMealSection('Collation', '16:00', '🍎', [
            {'name': 'Pomme', 'calories': 80, 'icon': '🍎', 'proteins': 0, 'carbs': 21, 'fats': 0},
            {'name': 'Amandes', 'calories': 160, 'icon': '🥜', 'proteins': 6, 'carbs': 6, 'fats': 14},
          ]),
          _buildMealSection('Dîner', '19:30', '🌙', [
            {'name': 'Saumon', 'calories': 250, 'icon': '🐟', 'proteins': 34, 'carbs': 0, 'fats': 12},
            {'name': 'Riz complet', 'calories': 150, 'icon': '🍚', 'proteins': 3, 'carbs': 33, 'fats': 1},
            {'name': 'Brocolis', 'calories': 50, 'icon': '🥦', 'proteins': 4, 'carbs': 10, 'fats': 0},
          ]),
          const SizedBox(height: 20),
          _buildAddMealButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildDailySummaryCard(double total, double goal, double remaining) {
    final progress = (total / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.teal.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total du jour',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${total.toInt()}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/ ${goal.toInt()} kcal',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    remaining > 0 ? '${remaining.toInt()} restantes' : 'Objectif atteint ! 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMealSection(String mealName, String time, String emoji, List<Map<String, dynamic>> foods) {
    final totalCalories = foods.fold<int>(0, (sum, food) => sum + (food['calories'] as int));
    final totalProteins = foods.fold<double>(0, (sum, food) => sum + (food['proteins'] as num).toDouble());
    final totalCarbs = foods.fold<double>(0, (sum, food) => sum + (food['carbs'] as num).toDouble());
    final totalFats = foods.fold<double>(0, (sum, food) => sum + (food['fats'] as num).toDouble());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.15
            ),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du repas avec emoji et heure
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        const Color(0xFF2D2D2D),
                        const Color(0xFF252525),
                      ]
                    : [
                        Colors.green.shade50,
                        Colors.teal.shade50,
                      ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      Text(
                        mealName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : null,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey.shade600,
                        ),
                      ),
            ],
          ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: () => _showAddFoodDialog(mealName),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
          ...foods.map((food) => _buildFoodItem(food)).toList(),
                const Divider(height: 24),
                // Résumé macro du repas
          Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                    _buildMacroSummaryItem('Cal', totalCalories.toString(), Colors.orange),
                    _buildMacroSummaryItem('P', '${totalProteins.toInt()}g', Colors.red),
                    _buildMacroSummaryItem('C', '${totalCarbs.toInt()}g', Colors.blue),
                    _buildMacroSummaryItem('F', '${totalFats.toInt()}g', Colors.orange.shade700),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
              Text(
                        'Total: $totalCalories kcal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFoodItem(Map<String, dynamic> food) {
    return InkWell(
      onTap: () => _showFoodDetails(food),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
      child: Row(
        children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2D2D2D)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
            food['icon'],
                style: const TextStyle(fontSize: 24),
              ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildSmallMacroChip('P', '${food['proteins']}g', Colors.red.shade300),
                      const SizedBox(width: 6),
                      _buildSmallMacroChip('C', '${food['carbs']}g', Colors.blue.shade300),
                      const SizedBox(width: 6),
                      _buildSmallMacroChip('F', '${food['fats']}g', Colors.orange.shade300),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
          Text(
                  '${food['calories']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right, 
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey.shade400, 
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSmallMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildAddMealButton() {
    return GestureDetector(
      onTap: () => _showMealSelectionDialog(),
      child: Container(
      width: double.infinity,
        padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.teal.shade400,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
          const Text(
            'Ajouter un repas',
            style: TextStyle(
                fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      ),
    );
  }
  
  void _showFoodDetails(Map<String, dynamic> food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                Text(
                  food['icon'],
                  style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        food['name'],
                      style: TextStyle(
                          fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                    Text(
                        '${food['calories']} calories',
                      style: TextStyle(
                          fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Macronutriments',
                style: TextStyle(
                fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailMacroCard('Protéines', '${food['proteins']}g', Colors.red),
                _buildDetailMacroCard('Glucides', '${food['carbs']}g', Colors.blue),
                _buildDetailMacroCard('Lipides', '${food['fats']}g', Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Logique pour modifier/supprimer
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailMacroCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showMealSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
            const Text(
              'Ajouter un repas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMealOptionButton('Petit-déjeuner', '🌅', Colors.orange),
            _buildMealOptionButton('Déjeuner', '☀️', Colors.blue),
            _buildMealOptionButton('Collation', '🍎', Colors.purple),
            _buildMealOptionButton('Dîner', '🌙', Colors.indigo),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMealOptionButton(String meal, String emoji, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _showAddFoodDialog(meal);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
          Text(
              meal,
              style: const TextStyle(
                fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _showAddFoodDialog(String mealName) {
    // Cette fonction pourrait ouvrir un dialogue pour rechercher/ajouter un aliment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ajouter un aliment à $mealName'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildMacrosTab() {
    final totalCalories = _dailyNutrition['calories']!;
    final proteinsCal = _dailyNutrition['proteins']! * 4;
    final carbsCal = _dailyNutrition['carbs']! * 4;
    final fatsCal = _dailyNutrition['fats']! * 9;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Graphique circulaire des macros
          _buildCircularMacroChart(proteinsCal, carbsCal, fatsCal, totalCalories),
          const SizedBox(height: 20),
          // Cartes détaillées de chaque macro
          _buildMacroCard('Protéines', _dailyNutrition['proteins']!, _dailyGoals['proteins']!, Colors.red, Icons.fitness_center, proteinsCal),
          _buildMacroCard('Glucides', _dailyNutrition['carbs']!, _dailyGoals['carbs']!, Colors.blue, Icons.grain, carbsCal),
          _buildMacroCard('Lipides', _dailyNutrition['fats']!, _dailyGoals['fats']!, Colors.orange, Icons.opacity, fatsCal),
          _buildMacroCard('Fibres', _dailyNutrition['fiber']!, _dailyGoals['fiber']!, Colors.green, Icons.eco, 0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildCircularMacroChart(double proteinsCal, double carbsCal, double fatsCal, double totalCal) {
    final proteinsPercent = (proteinsCal / totalCal * 100).clamp(0.0, 100.0);
    final carbsPercent = (carbsCal / totalCal * 100).clamp(0.0, 100.0);
    final fatsPercent = (fatsCal / totalCal * 100).clamp(0.0, 100.0);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.15
            ),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
      children: [
        Text(
            'Répartition Calorique',
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : null,
            fontWeight: FontWeight.bold,
          ),
        ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
          children: [
            Expanded(
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: _MacroPieChartPainter(
                      proteinsPercent / 100,
                      carbsPercent / 100,
                      fatsPercent / 100,
                    ),
                  ),
                ),
                Expanded(
        child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      _buildLegendItem('Protéines', Colors.red, proteinsPercent),
            const SizedBox(height: 12),
                      _buildLegendItem('Glucides', Colors.blue, carbsPercent),
                      const SizedBox(height: 12),
                      _buildLegendItem('Lipides', Colors.orange, fatsPercent),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double percentage) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
      decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : null,
            ),
          ),
        ),
          Text(
          '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            ),
          ),
        ],
    );
  }
  
  Widget _buildMacroCard(String name, double current, double goal, Color color, IconData icon, double calories) {
    final progress = (current / goal).clamp(0.0, 1.0);
    final remaining = (goal - current).clamp(0.0, goal);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${current.toInt()}g',
                          style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                            color: color,
                      ),
                    ),
                    Text(
                          ' / ${goal.toInt()}g',
                      style: TextStyle(
                            fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey.shade600,
                      ),
                    ),
                      ],
                    ),
                    if (calories > 0)
                    Text(
                        '${calories.toInt()} kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                    style: TextStyle(
                    fontSize: 18,
                      fontWeight: FontWeight.bold,
                    color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 14,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]!
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                remaining > 0 ? '${remaining.toInt()}g restants' : 'Objectif atteint ! 🎉',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (progress > 1.0)
                Text(
                  '+${((progress - 1.0) * goal).toInt()}g',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String name, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
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
        Text(
          'Conseils Nutrition',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : null,
          ),
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => _buildTipCard(tip)).toList(),
      ],
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return InkWell(
      onTap: () => _showTipDetails(tip),
      borderRadius: BorderRadius.circular(20),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (tip['color'] as Color).withOpacity(0.1),
              (tip['color'] as Color).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (tip['color'] as Color).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: (tip['color'] as Color).withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
          ),
        ],
      ),
        child: Padding(
          padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (tip['color'] as Color),
                      (tip['color'] as Color).withOpacity(0.7),
                    ],
                  ),
              borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (tip['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
            ),
            child: Text(
              tip['icon'],
                  style: const TextStyle(fontSize: 32),
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
                        fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: (tip['color'] as Color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['tip'],
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
          children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: (tip['color'] as Color),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En savoir plus',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (tip['color'] as Color),
                          ),
                        ),
                      ],
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

  void _showTipDetails(Map<String, dynamic> tip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF1E1E1E),
                    const Color(0xFF252525),
                  ]
                : [
                    Colors.white,
                    (tip['color'] as Color).withOpacity(0.05),
                  ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (tip['color'] as Color),
                        (tip['color'] as Color).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                child: Text(
                    tip['icon'],
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
                const SizedBox(width: 16),
              Expanded(
                  child: Text(
                    tip['title'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : (tip['color'] as Color),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
            const SizedBox(height: 20),
                Text(
              tip['tip'],
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle),
                label: const Text('J\'ai compris'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tip['color'] as Color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
            ),
          ),
        ],
        ),
      ),
    );
  }
  
}

// Custom Painter pour le graphique circulaire des macros
class _MacroPieChartPainter extends CustomPainter {
  final double proteinsPercent;
  final double carbsPercent;
  final double fatsPercent;

  _MacroPieChartPainter(
    this.proteinsPercent,
    this.carbsPercent,
    this.fatsPercent,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    double startAngle = -90 * (3.14159 / 180); // Commence en haut
    
    // Protéines (rouge)
    if (proteinsPercent > 0) {
      final sweepAngle = proteinsPercent * 360 * (3.14159 / 180);
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
    
    // Glucides (bleu)
    if (carbsPercent > 0) {
      final sweepAngle = carbsPercent * 360 * (3.14159 / 180);
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
    
    // Lipides (orange)
    if (fatsPercent > 0) {
      final sweepAngle = fatsPercent * 360 * (3.14159 / 180);
      final paint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
