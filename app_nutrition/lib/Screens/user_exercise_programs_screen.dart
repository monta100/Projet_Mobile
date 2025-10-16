import 'package:flutter/material.dart';
import '../Entites/user_plan_assignment.dart';
import '../Entites/exercise_plan.dart';
import '../Services/exercise_service.dart';
import '../Services/database_helper.dart';
import 'exercise_session_screen.dart';

class UserExerciseProgramsScreen extends StatefulWidget {
  final int utilisateurId;

  const UserExerciseProgramsScreen({
    Key? key,
    required this.utilisateurId,
  }) : super(key: key);

  @override
  State<UserExerciseProgramsScreen> createState() => _UserExerciseProgramsScreenState();
}

class _UserExerciseProgramsScreenState extends State<UserExerciseProgramsScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final DatabaseHelper _db = DatabaseHelper();
  
  List<UserPlanAssignment> _userPlans = [];
  Map<int, ExercisePlan> _plans = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPlans();
    _showWelcomeNotification();
  }

  void _showWelcomeNotification() {
    // Afficher une notification de bienvenue après un court délai
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bienvenue dans vos programmes ! 💪',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Votre coach vous a préparé des exercices personnalisés',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });
  }

  Future<void> _loadUserPlans() async {
    setState(() => _isLoading = true);
    try {
      final userPlans = await _exerciseService.getUserPlans(widget.utilisateurId);
      final plans = <int, ExercisePlan>{};
      
      for (final userPlan in userPlans) {
        final plan = await _exerciseService.getPlanById(userPlan.planId);
        if (plan != null) {
          plans[userPlan.planId] = plan;
        }
      }
      
      setState(() {
        _userPlans = userPlans;
        _plans = plans;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Programmes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserPlans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques rapides
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Plans actifs',
                          '${_userPlans.where((up) => up.isActive).length}',
                          Icons.fitness_center,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Progression moyenne',
                          '${_userPlans.isNotEmpty ? (_userPlans.map((up) => up.progression).reduce((a, b) => a + b) / _userPlans.length).round() : 0}%',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                // Liste des programmes
                Expanded(
                  child: _userPlans.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _userPlans.length,
                          itemBuilder: (context, index) {
                            final userPlan = _userPlans[index];
                            final plan = _plans[userPlan.planId];
                            if (plan == null) return const SizedBox.shrink();
                            return _buildProgramCard(userPlan, plan);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun programme assigné',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre coach vous assignera bientôt\ndes programmes d\'exercices personnalisés',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(UserPlanAssignment userPlan, ExercisePlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProgramDetails(userPlan, plan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(userPlan.isActive),
                ],
              ),
              const SizedBox(height: 8),
              if (plan.description.isNotEmpty) ...[
                Text(
                  plan.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              // Barre de progression
              Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Progression: ${userPlan.progression}%',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: userPlan.progression / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  userPlan.progression >= 100 ? Colors.green : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Assigné le ${_formatDate(userPlan.dateAttribution)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (userPlan.messageCoach != null)
                    Icon(Icons.message, size: 16, color: Colors.blue.shade600),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewProgramDetails(userPlan, plan),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Voir détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: userPlan.isActive ? () => _startWorkout(userPlan, plan) : null,
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Commencer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Text(
        isActive ? 'Actif' : 'Terminé',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showProgramDetails(UserPlanAssignment userPlan, ExercisePlan plan) {
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.nom,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(userPlan.isActive),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        plan.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      // Barre de progression
                      const Text(
                        'Progression',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: userPlan.progression / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                userPlan.progression >= 100 ? Colors.green : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${userPlan.progression}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Informations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date d\'assignation', _formatDate(userPlan.dateAttribution)),
                      if (userPlan.dateDebut != null)
                        _buildDetailRow('Date de début', _formatDate(userPlan.dateDebut!)),
                      if (userPlan.dateFin != null)
                        _buildDetailRow('Date de fin', _formatDate(userPlan.dateFin!)),
                      if (userPlan.messageCoach != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Message du coach',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.message, color: Colors.blue.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  userPlan.messageCoach!,
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
                      if (plan.notesCoach != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Notes du coach',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          plan.notesCoach!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (userPlan.isActive)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _startWorkout(userPlan, plan);
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Commencer l\'entraînement'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _viewProgramDetails(UserPlanAssignment userPlan, ExercisePlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSessionScreen(
          utilisateurId: widget.utilisateurId,
          planId: plan.id!,
          userPlanId: userPlan.id!,
        ),
      ),
    );
  }

  void _startWorkout(UserPlanAssignment userPlan, ExercisePlan plan) async {
    // Démarrer le plan si ce n'est pas déjà fait
    if (userPlan.dateDebut == null) {
      await _exerciseService.startUserPlan(userPlan.id!, widget.utilisateurId);
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSessionScreen(
          utilisateurId: widget.utilisateurId,
          planId: plan.id!,
          userPlanId: userPlan.id!,
        ),
      ),
    ).then((_) => _loadUserPlans()); // Recharger les données après la séance
  }
}
