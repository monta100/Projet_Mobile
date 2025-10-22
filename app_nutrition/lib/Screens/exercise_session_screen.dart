import 'package:flutter/material.dart';
import 'dart:async';
import '../Entites/exercise.dart';
import '../Entites/exercise_plan.dart';
import '../Entites/exercise_session.dart';
import '../Entites/plan_exercise_assignment.dart';
import '../Services/exercise_service.dart';
import '../Services/database_helper.dart';

class ExerciseSessionScreen extends StatefulWidget {
  final int utilisateurId;
  final int planId;
  final int userPlanId;

  const ExerciseSessionScreen({
    Key? key,
    required this.utilisateurId,
    required this.planId,
    required this.userPlanId,
  }) : super(key: key);

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final DatabaseHelper _db = DatabaseHelper();
  
  ExercisePlan? _plan;
  List<PlanExerciseAssignment> _planExercises = [];
  List<Exercise> _exercises = [];
  List<ExerciseSession> _sessions = [];
  
  bool _isLoading = true;
  bool _isWorkoutActive = false;
  int _currentExerciseIndex = 0;
  ExerciseSession? _currentSession;
  
  // Timer pour la séance
  Timer? _workoutTimer;
  int _workoutDuration = 0; // en secondes
  int _currentSet = 1;
  int _currentReps = 0;
  bool _isResting = false;
  int _restTimeRemaining = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWorkoutData() async {
    setState(() => _isLoading = true);
    try {
      final plan = await _exerciseService.getPlanById(widget.planId);
      final planExercises = await _exerciseService.getPlanExercises(widget.planId);
      final exercises = <Exercise>[];
      
      for (final assignment in planExercises) {
        final exercise = await _exerciseService.getExerciseById(assignment.exerciseId);
        if (exercise != null) {
          exercises.add(exercise);
        }
      }
      
      final sessions = await _exerciseService.getExerciseSessionsByUserAndPlan(
        widget.utilisateurId,
        widget.planId,
      );
      
      setState(() {
        _plan = plan;
        _planExercises = planExercises;
        _exercises = exercises;
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _startWorkout() {
    if (_planExercises.isEmpty) return;
    
    setState(() {
      _isWorkoutActive = true;
      _currentExerciseIndex = 0;
      _currentSet = 1;
      _currentReps = 0;
      _workoutDuration = 0;
    });
    
    _startWorkoutTimer();
    _startCurrentExercise();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _workoutDuration++;
      });
    });
  }

  void _startCurrentExercise() {
    if (_currentExerciseIndex >= _planExercises.length) {
      _finishWorkout();
      return;
    }
    
    final assignment = _planExercises[_currentExerciseIndex];
    final exercise = _exercises[_currentExerciseIndex];
    
    _exerciseService.startExerciseSession(
      planId: widget.planId,
      exerciseId: exercise.id!,
      utilisateurId: widget.utilisateurId,
      nombreSeries: assignment.nombreSeries,
      repetitionsParSerie: assignment.repetitionsParSerie,
      tempsRepos: assignment.tempsRepos,
      notesCoach: assignment.notesPersonnalisees,
    ).then((session) {
      setState(() {
        _currentSession = session;
      });
    });
  }

  void _completeSet() {
    // Animation de félicitations
    _showSetCompletedAnimation();
    
    setState(() {
      _currentReps = 0;
      _currentSet++;
    });
    
    final assignment = _planExercises[_currentExerciseIndex];
    
    if (_currentSet > assignment.nombreSeries) {
      _completeExercise();
    } else {
      _startRest();
    }
  }

  void _showSetCompletedAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Série terminée !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Excellent travail !',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Fermer automatiquement après 1 seconde
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _startRest() {
    final assignment = _planExercises[_currentExerciseIndex];
    setState(() {
      _isResting = true;
      _restTimeRemaining = assignment.tempsRepos;
    });
    
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restTimeRemaining--;
      });
      
      if (_restTimeRemaining <= 0) {
        timer.cancel();
        setState(() {
          _isResting = false;
        });
        _showRestCompletedAnimation();
      }
    });
  }

  void _showRestCompletedAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⏰',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Repos terminé !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prêt pour la suite ?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Fermer automatiquement après 1.5 secondes
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
    });
  }

  void _completeExercise() {
    if (_currentSession != null) {
      _exerciseService.completeExerciseSession(
        sessionId: _currentSession!.id!,
        difficulte: null, // L'utilisateur pourra l'évaluer plus tard
      );
    }
    
    setState(() {
      _currentExerciseIndex++;
      _currentSet = 1;
      _currentReps = 0;
      _currentSession = null;
    });
    
    if (_currentExerciseIndex < _planExercises.length) {
      _startCurrentExercise();
    } else {
      _finishWorkout();
    }
  }

  void _finishWorkout() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    
    setState(() {
      _isWorkoutActive = false;
      _currentExerciseIndex = 0;
      _currentSet = 1;
      _currentReps = 0;
      _isResting = false;
      _currentSession = null;
    });
    
    _showWorkoutSummary();
  }

  void _showWorkoutSummary() {
    final duration = Duration(seconds: _workoutDuration);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final calories = _calculateEstimatedCalories();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.celebration, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Séance terminée !',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Félicitations ! 🎉',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous avez terminé votre séance avec succès',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryItem('⏱️', 'Durée', '${minutes}m ${seconds}s'),
            _buildSummaryItem('💪', 'Exercices', '${_planExercises.length}'),
            _buildSummaryItem('🔥', 'Calories', '$calories cal'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Continuez comme ça ! Votre progression est excellente.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadWorkoutData(); // Recharger les données
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Voir progression'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateEstimatedCalories() {
    int totalCalories = 0;
    for (int i = 0; i < _currentExerciseIndex; i++) {
      final exercise = _exercises[i];
      final assignment = _planExercises[i];
      final estimatedDuration = assignment.nombreSeries * 2; // Estimation basique
      totalCalories += exercise.caloriesEstimees * estimatedDuration;
    }
    return totalCalories;
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan?.nom ?? 'Séance d\'exercice'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: _isWorkoutActive
            ? [
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: _finishWorkout,
                  tooltip: 'Terminer la séance',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isWorkoutActive
              ? _buildActiveWorkout()
              : _buildWorkoutOverview(),
    );
  }

  Widget _buildWorkoutOverview() {
    return Column(
      children: [
        // En-tête du plan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _plan?.nom ?? 'Plan d\'exercices',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _plan?.description ?? '',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildOverviewStat('Exercices', '${_planExercises.length}', Icons.fitness_center),
                  const SizedBox(width: 16),
                  _buildOverviewStat('Durée estimée', '${_calculateTotalDuration()} min', Icons.timer),
                  const SizedBox(width: 16),
                  _buildOverviewStat('Calories', '${_calculateTotalCalories()}', Icons.local_fire_department),
                ],
              ),
            ],
          ),
        ),
        // Liste des exercices
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _planExercises.length,
            itemBuilder: (context, index) {
              final assignment = _planExercises[index];
              final exercise = _exercises[index];
              return _buildExerciseOverviewCard(assignment, exercise, index);
            },
          ),
        ),
        // Bouton de démarrage
        Container(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startWorkout,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer l\'entraînement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
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

  Widget _buildExerciseOverviewCard(PlanExerciseAssignment assignment, Exercise exercise, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${assignment.nombreSeries} séries × ${assignment.repetitionsParSerie} répétitions',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Repos: ${assignment.tempsRepos}s',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveWorkout() {
    if (_currentExerciseIndex >= _planExercises.length) {
      return const Center(
        child: Text('Séance terminée !'),
      );
    }
    
    final assignment = _planExercises[_currentExerciseIndex];
    final exercise = _exercises[_currentExerciseIndex];
    
    return Column(
      children: [
        // Timer et progression
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              Text(
                'Exercice ${_currentExerciseIndex + 1} sur ${_planExercises.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDuration(_workoutDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (_currentExerciseIndex + 1) / _planExercises.length,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
        // Exercice actuel
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  exercise.nom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Série actuelle
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Série $_currentSet sur ${assignment.nombreSeries}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${assignment.repetitionsParSerie} répétitions',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Boutons d'action
                if (_isResting) ...[
                  Text(
                    'Temps de repos',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDuration(_restTimeRemaining),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _skipRest,
                          child: const Text('Passer le repos'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _completeSet,
                          icon: const Icon(Icons.check),
                          label: const Text('Série terminée'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (assignment.notesPersonnalisees != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            assignment.notesPersonnalisees!,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _calculateTotalDuration() {
    int totalMinutes = 0;
    for (final assignment in _planExercises) {
      // Estimation basique: 2 minutes par série + temps de repos
      final exerciseTime = assignment.nombreSeries * 2;
      final restTime = (assignment.nombreSeries - 1) * (assignment.tempsRepos / 60);
      totalMinutes += (exerciseTime + restTime).round();
    }
    return totalMinutes;
  }

  int _calculateTotalCalories() {
    int totalCalories = 0;
    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      final assignment = _planExercises[i];
      final estimatedDuration = assignment.nombreSeries * 2; // Estimation basique
      totalCalories += exercise.caloriesEstimees * estimatedDuration;
    }
    return totalCalories;
  }
}
