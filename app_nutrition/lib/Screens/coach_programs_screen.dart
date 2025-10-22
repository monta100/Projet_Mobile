import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/database_helper.dart';
import '../Entites/exercise_plan.dart';
import '../Entites/user_plan_assignment.dart';
import 'coach_plans_screen.dart';

class CoachProgramsScreen extends StatefulWidget {
  final Utilisateur coach;

  const CoachProgramsScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<CoachProgramsScreen> createState() => _CoachProgramsScreenState();
}

class _CoachProgramsScreenState extends State<CoachProgramsScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ExercisePlan> _plans = [];
  List<UserPlanAssignment> _assignments = [];
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
    
    _loadProgramsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgramsData() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _db.getExercisePlansByCoach(widget.coach.id!);
      final assignments = await _db.getUserPlanAssignmentsByCoach(widget.coach.id!);
      
      setState(() {
        _plans = plans;
        _assignments = assignments;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mes Programmes'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewProgram,
          ),
        ],
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
                    _buildProgramsSection(),
                    const SizedBox(height: 30),
                    _buildAssignmentsSection(),
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
            Colors.purple.shade400,
            Colors.purple.shade600,
            Colors.indigo.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
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
                  '${_plans.length} Programme${_plans.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Créez et gérez vos programmes d\'entraînement',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes Programmes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _createNewProgram,
              child: const Text('Créer'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _plans.isEmpty
            ? _buildEmptyPrograms()
            : Column(
                children: _plans.map((plan) => _buildProgramCard(plan)).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyPrograms() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun programme créé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier programme d\'entraînement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createNewProgram,
            icon: const Icon(Icons.add),
            label: const Text('Créer un programme'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
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

  Widget _buildProgramCard(ExercisePlan plan) {
    final assignments = _assignments.where((a) => a.planId == plan.id).toList();
    
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      children: [
                        Icon(Icons.person_add, size: 20),
                        SizedBox(width: 8),
                        Text('Assigner'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _editProgram(plan);
                  } else if (value == 'assign') {
                    _assignProgram(plan);
                  } else if (value == 'delete') {
                    _deleteProgram(plan);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgramStat(
                  'Assignations',
                  '${assignments.length}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildProgramStat(
                  'Actifs',
                  '${assignments.where((a) => a.isActive).length}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildProgramStat(
                  'Progression Moy.',
                  '${assignments.isNotEmpty ? (assignments.map((a) => a.progression).reduce((a, b) => a + b) / assignments.length).round() : 0}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramStat(String label, String value, IconData icon, Color color) {
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
              fontSize: 16,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignations Récentes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _assignments.isEmpty
            ? _buildEmptyAssignments()
            : Column(
                children: _assignments.take(5).map((assignment) => _buildAssignmentCard(assignment)).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyAssignments() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.assignment,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune assignation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aucun programme n\'a encore été assigné à vos clients',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(UserPlanAssignment assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: assignment.isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              assignment.isActive ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan ID: ${assignment.planId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Progression: ${assignment.progression}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Assigné le: ${assignment.dateAttribution.day}/${assignment.dateAttribution.month}/${assignment.dateAttribution.year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: assignment.isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              assignment.isActive ? 'Actif' : 'Inactif',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createNewProgram() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachPlansScreen(coachId: widget.coach.id!),
      ),
    ).then((_) => _loadProgramsData());
  }

  void _editProgram(ExercisePlan plan) {
    // Navigation vers l'édition du programme
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachPlansScreen(coachId: widget.coach.id!),
      ),
    ).then((_) => _loadProgramsData());
  }

  void _assignProgram(ExercisePlan plan) {
    // Afficher la liste des clients pour assigner le programme
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assigner "${plan.nom}"'),
        content: const Text('Fonctionnalité d\'assignation à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _deleteProgram(ExercisePlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le programme'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${plan.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _db.deleteExercisePlan(plan.id!);
              Navigator.pop(context);
              _loadProgramsData();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
