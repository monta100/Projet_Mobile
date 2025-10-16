import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/database_helper.dart';
import '../Entites/user_objective.dart';
import '../Entites/exercise_plan.dart';
import '../Entites/user_plan_assignment.dart';

class CoachAnalyticsScreen extends StatefulWidget {
  final Utilisateur coach;

  const CoachAnalyticsScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<CoachAnalyticsScreen> createState() => _CoachAnalyticsScreenState();
}

class _CoachAnalyticsScreenState extends State<CoachAnalyticsScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<UserObjective> _objectives = [];
  List<ExercisePlan> _plans = [];
  List<UserPlanAssignment> _assignments = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final objectives = await _db.getUserObjectivesByCoach(widget.coach.id!);
      final plans = await _db.getExercisePlansByCoach(widget.coach.id!);
      final assignments = await _db.getUserPlanAssignmentsByCoach(widget.coach.id!);
      
      final analytics = _calculateAnalytics(objectives, plans, assignments);
      
      setState(() {
        _objectives = objectives;
        _plans = plans;
        _assignments = assignments;
        _analytics = analytics;
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

  Map<String, dynamic> _calculateAnalytics(
    List<UserObjective> objectives, 
    List<ExercisePlan> plans, 
    List<UserPlanAssignment> assignments
  ) {
    final activeObjectives = objectives.where((o) => !o.estAtteint).toList();
    final completedObjectives = objectives.where((o) => o.estAtteint).toList();
    final overdueObjectives = objectives.where((o) => o.estEnRetard).toList();
    
    final activeAssignments = assignments.where((a) => a.isActive).toList();
    final totalProgression = assignments.isNotEmpty 
        ? assignments.map((a) => a.progression).reduce((a, b) => a + b) / assignments.length
        : 0.0;
    
    return {
      'totalObjectives': objectives.length,
      'activeObjectives': activeObjectives.length,
      'completedObjectives': completedObjectives.length,
      'overdueObjectives': overdueObjectives.length,
      'completionRate': objectives.isNotEmpty 
          ? (completedObjectives.length / objectives.length * 100).round()
          : 0,
      'totalPlans': plans.length,
      'activeAssignments': activeAssignments.length,
      'averageProgression': totalProgression.round(),
      'successRate': objectives.isNotEmpty 
          ? ((completedObjectives.length / objectives.length) * 100).round()
          : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Analyses'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildOverviewCards(),
                    const SizedBox(height: 30),
                    _buildObjectivesAnalytics(),
                    const SizedBox(height: 30),
                    _buildProgramsAnalytics(),
                    const SizedBox(height: 30),
                    _buildPerformanceChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade400,
            Colors.teal.shade600,
            Colors.cyan.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyses Détaillées',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Suivez les performances de vos clients',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'Ensemble',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Taux de Réussite',
                '${_analytics['completionRate'] ?? 0}%',
                Icons.trending_up,
                Colors.green,
                'Objectifs atteints',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Progression Moy.',
                '${_analytics['averageProgression'] ?? 0}%',
                Icons.analytics,
                Colors.blue,
                'Progression moyenne',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Programmes Actifs',
                '${_analytics['activeAssignments'] ?? 0}',
                Icons.fitness_center,
                Colors.purple,
                'Programmes en cours',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Objectifs En Retard',
                '${_analytics['overdueObjectives'] ?? 0}',
                Icons.warning,
                Colors.red,
                'Nécessitent attention',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectivesAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analyses des Objectifs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: [
              _buildAnalyticsRow('Total Objectifs', '${_analytics['totalObjectives'] ?? 0}', Colors.grey),
              _buildAnalyticsRow('Objectifs Actifs', '${_analytics['activeObjectives'] ?? 0}', Colors.blue),
              _buildAnalyticsRow('Objectifs Atteints', '${_analytics['completedObjectives'] ?? 0}', Colors.green),
              _buildAnalyticsRow('Objectifs En Retard', '${_analytics['overdueObjectives'] ?? 0}', Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              value,
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

  Widget _buildProgramsAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analyses des Programmes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: [
              _buildAnalyticsRow('Total Programmes', '${_analytics['totalPlans'] ?? 0}', Colors.purple),
              _buildAnalyticsRow('Assignations Actives', '${_analytics['activeAssignments'] ?? 0}', Colors.orange),
              _buildAnalyticsRow('Progression Moyenne', '${_analytics['averageProgression'] ?? 0}%', Colors.teal),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Globale',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: [
              _buildPerformanceBar('Taux de Réussite', (_analytics['completionRate'] ?? 0) / 100, Colors.green),
              _buildPerformanceBar('Progression Moyenne', (_analytics['averageProgression'] ?? 0) / 100, Colors.blue),
              _buildPerformanceBar('Engagement', ((_analytics['activeAssignments'] ?? 0) / ((_analytics['totalPlans'] ?? 0) > 0 ? (_analytics['totalPlans'] ?? 1) : 1)).clamp(0.0, 1.0), Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
