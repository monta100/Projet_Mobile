import 'package:flutter/material.dart';
import '../Entites/exercise.dart';
import '../Services/exercise_service.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  final int coachId;

  const ExerciseLibraryScreen({
    Key? key,
    required this.coachId,
  }) : super(key: key);

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;

  // Filtres
  String _selectedType = 'Tous';
  String _selectedNiveau = 'Tous';
  String _selectedObjectif = 'Tous';
  String _selectedPartieCorps = 'Tous';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  // Options de filtres
  final List<String> _types = ['Tous', 'cardio', 'musculation', 'mobilité', 'stretching'];
  final List<String> _niveaux = ['Tous', 'débutant', 'intermédiaire', 'avancé'];
  final List<String> _objectifs = ['Tous', 'perte de poids', 'gain musculaire', 'tonification', 'performance'];
  final List<String> _partiesCorps = ['Tous', 'jambes', 'bras', 'dos', 'abdos', 'poitrine', 'fessiers'];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _exerciseService.getAllExercises();
      setState(() {
        _exercises = exercises;
        _filteredExercises = exercises;
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

  void _applyFilters() {
    setState(() {
      _filteredExercises = _exercises.where((exercise) {
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          if (!exercise.nom.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !exercise.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Filtre par type
        if (_selectedType != 'Tous' && exercise.type != _selectedType) {
          return false;
        }

        // Filtre par niveau
        if (_selectedNiveau != 'Tous' && exercise.niveau != _selectedNiveau) {
          return false;
        }

        // Filtre par objectif
        if (_selectedObjectif != 'Tous' && !exercise.objectif.contains(_selectedObjectif)) {
          return false;
        }

        // Filtre par partie du corps
        if (_selectedPartieCorps != 'Tous' && !exercise.partieCorps.contains(_selectedPartieCorps)) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque d\'Exercices'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExercises,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un exercice...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                // Filtres
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Type', _selectedType, _types, (value) {
                        setState(() => _selectedType = value);
                        _applyFilters();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Niveau', _selectedNiveau, _niveaux, (value) {
                        setState(() => _selectedNiveau = value);
                        _applyFilters();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Objectif', _selectedObjectif, _objectifs, (value) {
                        setState(() => _selectedObjectif = value);
                        _applyFilters();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Partie', _selectedPartieCorps, _partiesCorps, (value) {
                        setState(() => _selectedPartieCorps = value);
                        _applyFilters();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Liste des exercices
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun exercice trouvé',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Essayez de modifier vos filtres',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          return _buildExerciseCard(exercise);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedValue == 'Tous' ? Colors.grey.shade200 : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $selectedValue',
              style: TextStyle(
                color: selectedValue == 'Tous' ? Colors.black87 : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: selectedValue == 'Tous' ? Colors.black87 : Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) => PopupMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
      onSelected: onChanged,
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showExerciseDetails(exercise),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildBadge(exercise.type, Colors.blue),
                  const SizedBox(width: 8),
                  _buildBadge(exercise.niveau, Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exercise.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.accessibility, exercise.partieCorps),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.timer, '${exercise.dureeEstimee} min'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.local_fire_department, '${exercise.caloriesEstimees} cal/min'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(Icons.sports, exercise.objectif),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.build, exercise.materiel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showExerciseDetails(Exercise exercise) {
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
                              exercise.nom,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildBadge(exercise.type, Colors.blue),
                          const SizedBox(width: 8),
                          _buildBadge(exercise.niveau, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        exercise.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Détails',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Partie du corps', exercise.partieCorps),
                      _buildDetailRow('Objectif', exercise.objectif),
                      _buildDetailRow('Matériel', exercise.materiel),
                      _buildDetailRow('Durée estimée', '${exercise.dureeEstimee} minutes'),
                      _buildDetailRow('Calories/min', '${exercise.caloriesEstimees} cal/min'),
                      if (exercise.instructions != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          exercise.instructions!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _addToPlan(exercise);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter à un plan'),
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

  void _addToPlan(Exercise exercise) {
    // TODO: Naviguer vers l'écran de création/modification de plan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ajout de "${exercise.nom}" à un plan - À implémenter'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}
