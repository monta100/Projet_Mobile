import 'package:flutter/material.dart';
import '../Entites/exercise_plan.dart';
import '../Entites/utilisateur.dart';
import '../Services/exercise_service.dart';
import '../Services/database_helper.dart';
import 'create_exercise_plan_screen.dart';
import 'exercise_library_screen.dart';

class CoachPlansScreen extends StatefulWidget {
  final int coachId;

  const CoachPlansScreen({
    Key? key,
    required this.coachId,
  }) : super(key: key);

  @override
  State<CoachPlansScreen> createState() => _CoachPlansScreenState();
}

class _CoachPlansScreenState extends State<CoachPlansScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final DatabaseHelper _db = DatabaseHelper();
  
  List<ExercisePlan> _plans = [];
  List<Utilisateur> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _exerciseService.getPlansByCoach(widget.coachId);
      final clients = await _db.getClientsByCoach(widget.coachId);
      
      setState(() {
        _plans = plans;
        _clients = clients;
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
        title: const Text('Mes Plans d\'Exercices'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                          '${_plans.where((p) => p.isActive).length}',
                          Icons.fitness_center,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Clients',
                          '${_clients.length}',
                          Icons.people,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                // Liste des plans
                Expanded(
                  child: _plans.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _plans.length,
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            return _buildPlanCard(plan);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "library",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseLibraryScreen(coachId: widget.coachId),
                ),
              );
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.library_books, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "create",
            onPressed: () => _createNewPlan(),
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
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
            'Aucun plan créé',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier plan d\'exercices\npour vos clients',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _createNewPlan(),
            icon: const Icon(Icons.add),
            label: const Text('Créer un plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(ExercisePlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPlanDetails(plan),
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
                  _buildStatusChip(plan.isActive),
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
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Créé le ${_formatDate(plan.dateCreation)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '0 clients', // TODO: Récupérer le nombre réel de clients
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editPlan(plan),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _assignPlan(plan),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Assigner'),
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
        isActive ? 'Actif' : 'Inactif',
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

  void _createNewPlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExercisePlanScreen(coachId: widget.coachId),
      ),
    );
    
    if (result != null) {
      _loadData(); // Recharger les données
    }
  }

  void _editPlan(ExercisePlan plan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExercisePlanScreen(
          coachId: widget.coachId,
          existingPlan: plan,
        ),
      ),
    );
    
    if (result != null) {
      _loadData(); // Recharger les données
    }
  }

  void _assignPlan(ExercisePlan plan) {
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun client disponible pour assigner ce plan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
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
                  'Assigner "${plan.nom}"',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    return _buildClientListItem(client, plan);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientListItem(Utilisateur client, ExercisePlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            client.prenom[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${client.prenom} ${client.nom}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(client.email),
        trailing: ElevatedButton(
          onPressed: () => _confirmAssignment(client, plan),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Assigner'),
        ),
      ),
    );
  }

  void _confirmAssignment(Utilisateur client, ExercisePlan plan) async {
    Navigator.pop(context); // Fermer le modal
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'assignation'),
        content: Text(
          'Voulez-vous assigner le plan "${plan.nom}" à ${client.prenom} ${client.nom} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Assigner'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _exerciseService.assignPlanToUser(
          utilisateurId: client.id!,
          planId: plan.id!,
          messageCoach: 'Votre coach vous a assigné un nouveau plan d\'exercices ! 💪',
          context: context,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plan assigné à ${client.prenom} ${client.nom}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'assignation: $e')),
          );
        }
      }
    }
  }

  void _showPlanDetails(ExercisePlan plan) {
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
                          _buildStatusChip(plan.isActive),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        plan.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
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
                      _buildDetailRow('Date de création', _formatDate(plan.dateCreation)),
                      if (plan.dateDebut != null)
                        _buildDetailRow('Date de début', _formatDate(plan.dateDebut!)),
                      if (plan.dateFin != null)
                        _buildDetailRow('Date de fin', _formatDate(plan.dateFin!)),
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
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _editPlan(plan);
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Modifier'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _assignPlan(plan);
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Assigner'),
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
}
