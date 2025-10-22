import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/progress_stats.dart';
import '../Services/progress_service.dart';
import 'user_progress_charts_screen.dart';
import 'user_workout_history_screen.dart';
import 'user_weight_tracking_screen.dart';

class UserProgressDashboardScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserProgressDashboardScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserProgressDashboardScreen> createState() => _UserProgressDashboardScreenState();
}

class _UserProgressDashboardScreenState extends State<UserProgressDashboardScreen>
    with TickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  ProgressStats? _weeklyStats;
  ProgressStats? _monthlyStats;
  String _selectedPeriod = 'week';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadProgressData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);
    try {
      final weeklyStats = await _progressService.getProgressStats(widget.utilisateur.id!, 'week');
      final monthlyStats = await _progressService.getProgressStats(widget.utilisateur.id!, 'month');
      
      setState(() {
        _weeklyStats = weeklyStats;
        _monthlyStats = monthlyStats;
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

  ProgressStats? get _currentStats {
    return _selectedPeriod == 'week' ? _weeklyStats : _monthlyStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Ma Progression'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProgressData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 30),
                      _buildQuickStats(),
                      const SizedBox(height: 30),
                      _buildWeightProgress(),
                      const SizedBox(height: 30),
                      _buildWorkoutStats(),
                      const SizedBox(height: 30),
                      _buildConsistencyStats(),
                      const SizedBox(height: 30),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
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
          Expanded(
            child: _buildPeriodTab('week', 'Cette semaine'),
          ),
          Expanded(
            child: _buildPeriodTab('month', 'Ce mois'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final stats = _currentStats;
    if (stats == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
            Colors.indigo.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
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
                      stats.periodDisplayName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeaderStats(stats),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(ProgressStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildHeaderStatCard(
            'Entraînements',
            '${stats.totalWorkouts}',
            Icons.fitness_center,
            Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHeaderStatCard(
            'Calories',
            '${stats.totalCaloriesBurned.toInt()}',
            Icons.local_fire_department,
            Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHeaderStatCard(
            'Consistance',
            '${stats.consistencyRate.toInt()}%',
            Icons.schedule,
            Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = _currentStats;
    if (stats == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques Rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Durée Totale',
                stats.durationFormatted,
                Icons.timer,
                Colors.orange,
                'Temps d\'entraînement',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Séries',
                '${stats.totalSets}',
                Icons.repeat,
                Colors.green,
                'Séries complétées',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Répétitions',
                '${stats.totalReps}',
                Icons.repeat_one,
                Colors.purple,
                'Répétitions totales',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Série Actuelle',
                '${stats.currentStreak}',
                Icons.local_fire_department,
                Colors.red,
                'Jours consécutifs',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _buildWeightProgress() {
    final stats = _currentStats;
    if (stats == null || stats.startWeight == null) {
      return _buildEmptySection(
        'Poids',
        'Aucune donnée de poids disponible',
        Icons.monitor_weight,
        () => _navigateToWeightTracking(),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progression du Poids',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWeightInfo('Début', '${stats.startWeight!.toStringAsFixed(1)} kg', Colors.grey),
                  _buildWeightInfo('Actuel', '${stats.endWeight!.toStringAsFixed(1)} kg', Colors.blue),
                  _buildWeightInfo('Changement', stats.weightChangeFormatted, 
                    stats.isWeightLoss ? Colors.green : stats.isWeightGain ? Colors.red : Colors.grey),
                ],
              ),
              const SizedBox(height: 20),
              if (stats.bodyFatChange != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWeightInfo('Masse grasse', stats.bodyFatChangeFormatted,
                      stats.isBodyFatLoss ? Colors.green : Colors.red),
                    if (stats.muscleMassChange != null)
                      _buildWeightInfo('Masse musculaire', stats.muscleMassChangeFormatted,
                        stats.isMuscleGain ? Colors.green : Colors.red),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutStats() {
    final stats = _currentStats;
    if (stats == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques d\'Entraînement',
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
              _buildWorkoutStatRow('Entraînements', '${stats.totalWorkouts}', Icons.fitness_center),
              _buildWorkoutStatRow('Durée moyenne', stats.averageDurationFormatted, Icons.timer),
              _buildWorkoutStatRow('Calories brûlées', '${stats.totalCaloriesBurned.toInt()}', Icons.local_fire_department),
              _buildWorkoutStatRow('Plus longue série', '${stats.longestStreak} jours', Icons.local_fire_department),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyStats() {
    final stats = _currentStats;
    if (stats == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consistance',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taux de consistance',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${stats.consistencyRate.toInt()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (stats.consistencyRate / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  stats.consistencyRate >= 70 ? Colors.green : 
                  stats.consistencyRate >= 50 ? Colors.orange : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildConsistencyItem(
                      'Jours d\'entraînement',
                      '${stats.workoutDays}',
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildConsistencyItem(
                      'Série actuelle',
                      '${stats.currentStreak}',
                      Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencyItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
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
                'Graphiques',
                'Voir les tendances',
                Icons.show_chart,
                Colors.purple,
                () => _navigateToCharts(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Historique',
                'Séances passées',
                Icons.history,
                Colors.orange,
                () => _navigateToHistory(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Poids',
                'Enregistrer poids',
                Icons.monitor_weight,
                Colors.green,
                () => _navigateToWeightTracking(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Rapport',
                'Rapport détaillé',
                Icons.assessment,
                Colors.teal,
                () => _showDetailedReport(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildEmptySection(String title, String message, IconData icon, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(icon, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez pour commencer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToCharts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProgressChartsScreen(utilisateur: widget.utilisateur),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserWorkoutHistoryScreen(utilisateur: widget.utilisateur),
      ),
    );
  }

  void _navigateToWeightTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserWeightTrackingScreen(utilisateur: widget.utilisateur),
      ),
    );
  }

  void _showDetailedReport() {
    final stats = _currentStats;
    if (stats == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                  'Rapport Détaillé - ${stats.periodDisplayName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildReportSection('Entraînements', [
                      'Total: ${stats.totalWorkouts} séances',
                      'Durée totale: ${stats.durationFormatted}',
                      'Durée moyenne: ${stats.averageDurationFormatted}',
                      'Calories brûlées: ${stats.totalCaloriesBurned.toInt()} kcal',
                    ]),
                    _buildReportSection('Consistance', [
                      'Taux: ${stats.consistencyRate.toInt()}%',
                      'Jours d\'entraînement: ${stats.workoutDays}',
                      'Série actuelle: ${stats.currentStreak} jours',
                      'Plus longue série: ${stats.longestStreak} jours',
                    ]),
                    if (stats.startWeight != null) _buildReportSection('Poids', [
                      'Poids de départ: ${stats.startWeight!.toStringAsFixed(1)} kg',
                      'Poids actuel: ${stats.endWeight!.toStringAsFixed(1)} kg',
                      'Changement: ${stats.weightChangeFormatted}',
                      if (stats.bodyFatChange != null) 'Masse grasse: ${stats.bodyFatChangeFormatted}',
                    ]),
                    _buildReportSection('Objectifs', [
                      'Total: ${stats.totalObjectives}',
                      'Atteints: ${stats.completedObjectives}',
                      'Taux de réussite: ${stats.objectiveCompletionRate.toInt()}%',
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $item',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
