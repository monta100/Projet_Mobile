import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/progress_tracking.dart';
import '../Services/progress_service.dart';
import '../Services/database_helper.dart';
import '../Entites/exercise_session.dart';

class UserWorkoutHistoryScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserWorkoutHistoryScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserWorkoutHistoryScreen> createState() => _UserWorkoutHistoryScreenState();
}

class _UserWorkoutHistoryScreenState extends State<UserWorkoutHistoryScreen>
    with TickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  final DatabaseHelper _db = DatabaseHelper();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ExerciseSession> _workoutSessions = [];
  List<ProgressTracking> _workoutProgress = [];
  String _selectedFilter = 'all'; // 'all', 'week', 'month', 'year'
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
    
    _loadWorkoutHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutHistory() async {
    setState(() => _isLoading = true);
    try {
      // Charger les séances d'entraînement
      final sessions = await _db.getExerciseSessionsByUser(widget.utilisateur.id!);
      
      // Charger les données de progression des entraînements
      final progress = await _progressService.getUserProgress(
        widget.utilisateur.id!,
        type: 'workout',
      );
      
      setState(() {
        _workoutSessions = sessions;
        _workoutProgress = progress;
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

  List<ExerciseSession> get _filteredSessions {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedFilter) {
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return _workoutSessions;
    }
    
    return _workoutSessions.where((session) => 
      session.dateDebut != null && (
        session.dateDebut!.isAfter(startDate) || session.dateDebut!.isAtSameMomentAs(startDate)
      )
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Historique des Entraînements'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkoutHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildFilterTabs(),
                  Expanded(
                    child: _workoutSessions.isEmpty
                        ? _buildEmptyHistory()
                        : _buildWorkoutList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterTabs() {
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
          _buildFilterTab('all', 'Tous'),
          _buildFilterTab('week', 'Cette semaine'),
          _buildFilterTab('month', 'Ce mois'),
          _buildFilterTab('year', 'Cette année'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun entraînement',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore d\'entraînements enregistrés.\nCommencez votre premier entraînement !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    final filteredSessions = _filteredSessions;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(filteredSessions),
          const SizedBox(height: 20),
          ...filteredSessions.map((session) => _buildWorkoutCard(session)).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<ExerciseSession> sessions) {
    final totalSessions = sessions.length;
    final totalDuration = sessions.fold(0.0, (sum, session) => sum + (session.dureeReelle ?? 0).toDouble());
    final totalCalories = sessions.fold(0, (sum, session) => sum + (session.caloriesBrulees ?? 0));
    final averageDuration = totalSessions > 0 ? totalDuration / totalSessions : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
            Colors.deepOrange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
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
                      'Résumé - ${_getFilterDisplayName()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$totalSessions séance${totalSessions > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  'Durée totale',
                  _formatDuration(totalDuration),
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildSummaryStat(
                  'Calories',
                  '$totalCalories',
                  Icons.local_fire_department,
                ),
              ),
              Expanded(
                child: _buildSummaryStat(
                  'Durée moy.',
                  _formatDuration(averageDuration),
                  Icons.av_timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(ExerciseSession session) {
    final progressEntries = _workoutProgress.where((p) => 
      session.dateDebut != null &&
      p.date.day == session.dateDebut!.day &&
      p.date.month == session.dateDebut!.month &&
      p.date.year == session.dateDebut!.year
    ).toList();
    
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Séance d\'entraînement',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      session.dateDebut != null ? _formatDate(session.dateDebut!) : 'Date inconnue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: session.estTerminee ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  session.estTerminee ? 'Terminée' : 'En cours',
                  style: const TextStyle(
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
                child: _buildWorkoutStat(
                  'Durée',
                  _formatDuration((session.dureeReelle ?? 0).toDouble()),
                  Icons.timer,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildWorkoutStat(
                  'Calories',
                  '${session.caloriesBrulees ?? 0}',
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildWorkoutStat(
                  'Difficulté',
                  '${session.difficulte ?? 0}/5',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
          if (session.commentaireUtilisateur != null && session.commentaireUtilisateur!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commentaires:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.commentaireUtilisateur!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterDisplayName() {
    switch (_selectedFilter) {
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      case 'year':
        return 'Cette année';
      default:
        return 'Tous les temps';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDuration(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).floor();
    
    if (hours > 0) {
      return '${hours}h ${mins}min';
    } else {
      return '${mins}min';
    }
  }
}
