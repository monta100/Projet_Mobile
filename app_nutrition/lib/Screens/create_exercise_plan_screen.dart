import 'package:flutter/material.dart';
import '../Entites/exercise.dart';
import '../Entites/exercise_plan.dart';
import '../Entites/plan_exercise_assignment.dart';
import '../Services/exercise_service.dart';

class CreateExercisePlanScreen extends StatefulWidget {
  final int coachId;
  final ExercisePlan? existingPlan;

  const CreateExercisePlanScreen({
    Key? key,
    required this.coachId,
    this.existingPlan,
  }) : super(key: key);

  @override
  State<CreateExercisePlanScreen> createState() => _CreateExercisePlanScreenState();
}

class _CreateExercisePlanScreenState extends State<CreateExercisePlanScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs du plan
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Liste des exercices ajoutés au plan
  List<PlanExerciseAssignment> _planExercises = [];
  List<Exercise> _availableExercises = [];
  
  bool _isLoading = false;
  bool _isLoadingExercises = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableExercises();
    if (widget.existingPlan != null) {
      _loadExistingPlan();
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableExercises() async {
    setState(() => _isLoadingExercises = true);
    try {
      final exercises = await _exerciseService.getAllExercises();
      setState(() {
        _availableExercises = exercises;
        _isLoadingExercises = false;
      });
    } catch (e) {
      setState(() => _isLoadingExercises = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _loadExistingPlan() {
    final plan = widget.existingPlan!;
    _nomController.text = plan.nom;
    _descriptionController.text = plan.description;
    _notesController.text = plan.notesCoach ?? '';
    // TODO: Charger les exercices du plan existant
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_planExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un exercice au plan')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      ExercisePlan plan;
      
      if (widget.existingPlan != null) {
        // Mise à jour d'un plan existant
        plan = widget.existingPlan!;
        plan.nom = _nomController.text;
        plan.description = _descriptionController.text;
        plan.notesCoach = _notesController.text;
        await _exerciseService.updateExercisePlan(plan);
      } else {
        // Création d'un nouveau plan
        plan = await _exerciseService.createExercisePlan(
          coachId: widget.coachId,
          nom: _nomController.text,
          description: _descriptionController.text,
          notesCoach: _notesController.text,
        );
      }

      // Ajouter les exercices au plan
      for (final assignment in _planExercises) {
        assignment.planId = plan.id!;
        await _exerciseService.addExerciseToPlan(
          planId: plan.id!,
          exerciseId: assignment.exerciseId,
          ordre: assignment.ordre,
          nombreSeries: assignment.nombreSeries,
          repetitionsParSerie: assignment.repetitionsParSerie,
          tempsRepos: assignment.tempsRepos,
          notesPersonnalisees: assignment.notesPersonnalisees,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingPlan != null 
                ? 'Plan mis à jour avec succès' 
                : 'Plan créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, plan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addExercise() {
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
                  'Ajouter un exercice',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _isLoadingExercises
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _availableExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _availableExercises[index];
                          return _buildExerciseListItem(exercise);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseListItem(Exercise exercise) {
    final isAlreadyAdded = _planExercises.any((pe) => pe.exerciseId == exercise.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.fitness_center,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          exercise.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.description),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(exercise.type, Colors.blue),
                const SizedBox(width: 4),
                _buildChip(exercise.niveau, Colors.green),
                const SizedBox(width: 4),
                _buildChip('${exercise.dureeEstimee}min', Colors.orange),
              ],
            ),
          ],
        ),
        trailing: isAlreadyAdded
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.add_circle_outline),
        onTap: isAlreadyAdded ? null : () => _selectExercise(exercise),
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _selectExercise(Exercise exercise) {
    Navigator.pop(context);
    _showExerciseConfiguration(exercise);
  }

  void _showExerciseConfiguration(Exercise exercise) {
    final nombreSeriesController = TextEditingController(text: '3');
    final repetitionsController = TextEditingController(text: '10');
    final tempsReposController = TextEditingController(text: '60');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configurer ${exercise.nom}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreSeriesController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de séries',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repetitionsController,
                decoration: const InputDecoration(
                  labelText: 'Répétitions par série',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tempsReposController,
                decoration: const InputDecoration(
                  labelText: 'Temps de repos (secondes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes personnalisées (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final assignment = PlanExerciseAssignment(
                planId: 0, // Sera mis à jour lors de la sauvegarde
                exerciseId: exercise.id!,
                ordre: _planExercises.length + 1,
                nombreSeries: int.parse(nombreSeriesController.text),
                repetitionsParSerie: int.parse(repetitionsController.text),
                tempsRepos: int.parse(tempsReposController.text),
                notesPersonnalisees: notesController.text.isEmpty ? null : notesController.text,
              );
              
              setState(() {
                _planExercises.add(assignment);
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${exercise.nom} ajouté au plan')),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _planExercises.removeAt(index);
      // Réorganiser l'ordre
      for (int i = 0; i < _planExercises.length; i++) {
        _planExercises[i].ordre = i + 1;
      }
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _planExercises.removeAt(oldIndex);
      _planExercises.insert(newIndex, item);
      
      // Réorganiser l'ordre
      for (int i = 0; i < _planExercises.length; i++) {
        _planExercises[i].ordre = i + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPlan != null ? 'Modifier le plan' : 'Nouveau plan'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePlan,
              child: const Text(
                'Sauvegarder',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Informations du plan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du plan *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir un nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes pour les utilisateurs',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            // Liste des exercices
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Exercices du plan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _planExercises.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Aucun exercice ajouté',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Appuyez sur "Ajouter" pour commencer',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _planExercises.length,
                            onReorder: _reorderExercises,
                            itemBuilder: (context, index) {
                              final assignment = _planExercises[index];
                              final exercise = _availableExercises.firstWhere(
                                (e) => e.id == assignment.exerciseId,
                                orElse: () => Exercise(
                                  nom: 'Exercice inconnu',
                                  description: '',
                                  type: '',
                                  partieCorps: '',
                                  niveau: '',
                                  objectif: '',
                                  materiel: '',
                                  dureeEstimee: 0,
                                  caloriesEstimees: 0,
                                ),
                              );
                              
                              return _buildPlanExerciseCard(assignment, exercise, index);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanExerciseCard(PlanExerciseAssignment assignment, Exercise exercise, int index) {
    return Card(
      key: ValueKey(assignment.exerciseId),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          exercise.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${assignment.nombreSeries} séries × ${assignment.repetitionsParSerie} répétitions'),
            Text('Repos: ${assignment.tempsRepos}s'),
            if (assignment.notesPersonnalisees != null)
              Text(
                'Note: ${assignment.notesPersonnalisees}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeExercise(index),
        ),
        isThreeLine: true,
      ),
    );
  }
}
