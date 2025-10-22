import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/database_helper.dart';
import '../Entites/user_objective.dart';

class CoachObjectivesScreen extends StatefulWidget {
  final Utilisateur coach;

  const CoachObjectivesScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<CoachObjectivesScreen> createState() => _CoachObjectivesScreenState();
}

class _CoachObjectivesScreenState extends State<CoachObjectivesScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<UserObjective> _objectives = [];
  int _selectedFilter = 0; // 0: Tous, 1: Actifs, 2: Atteints, 3: En retard
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
    
    _loadObjectives();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadObjectives() async {
    setState(() => _isLoading = true);
    try {
      final objectives = await _db.getUserObjectivesByCoach(widget.coach.id!);
      setState(() {
        _objectives = objectives;
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

  List<UserObjective> get _filteredObjectives {
    switch (_selectedFilter) {
      case 1:
        return _objectives.where((o) => !o.estAtteint && !o.estEnRetard).toList();
      case 2:
        return _objectives.where((o) => o.estAtteint).toList();
      case 3:
        return _objectives.where((o) => o.estEnRetard).toList();
      default:
        return _objectives;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Objectifs des Clients'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildFilterTabs(),
                  Expanded(
                    child: _objectives.isEmpty
                        ? _buildEmptyObjectives()
                        : _buildObjectivesList(),
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
          _buildFilterTab('Tous', 0, Colors.grey),
          _buildFilterTab('Actifs', 1, Colors.blue),
          _buildFilterTab('Atteints', 2, Colors.green),
          _buildFilterTab('En retard', 3, Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, int index, Color color) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
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

  Widget _buildEmptyObjectives() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun objectif',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos clients n\'ont pas encore créé d\'objectifs.\nVous pouvez les aider à en créer depuis l\'écran des clients.',
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

  Widget _buildObjectivesList() {
    final filteredObjectives = _filteredObjectives;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildObjectivesHeader(filteredObjectives),
          const SizedBox(height: 20),
          ...filteredObjectives.map((objective) => _buildObjectiveCard(objective)).toList(),
        ],
      ),
    );
  }

  Widget _buildObjectivesHeader(List<UserObjective> filteredObjectives) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.track_changes,
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
                  '${filteredObjectives.length} Objectif${filteredObjectives.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Suivez les progrès de vos clients',
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

  Widget _buildObjectiveCard(UserObjective objective) {
    final isCompleted = objective.estAtteint;
    final isOverdue = objective.estEnRetard;
    final progress = objective.progressionPourcentage / 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.shade200 
              : isOverdue 
                  ? Colors.red.shade200 
                  : Colors.blue.shade200,
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
          if (objective.notes != null && objective.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
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
                    'Notes:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    objective.notes!,
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
}
