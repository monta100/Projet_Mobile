class PlanExerciseAssignment {
  int? id;
  int planId;
  int exerciseId;
  int ordre; // ordre dans le plan
  int nombreSeries;
  int repetitionsParSerie;
  int tempsRepos; // en secondes
  String? notesPersonnalisees;
  bool isActive;

  PlanExerciseAssignment({
    this.id,
    required this.planId,
    required this.exerciseId,
    required this.ordre,
    required this.nombreSeries,
    required this.repetitionsParSerie,
    required this.tempsRepos,
    this.notesPersonnalisees,
    this.isActive = true,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'exercise_id': exerciseId,
      'ordre': ordre,
      'nombre_series': nombreSeries,
      'repetitions_par_serie': repetitionsParSerie,
      'temps_repos': tempsRepos,
      'notes_personnalisees': notesPersonnalisees,
      'is_active': isActive ? 1 : 0,
    };
  }

  // Création d'une assignation depuis une Map
  factory PlanExerciseAssignment.fromMap(Map<String, dynamic> map) {
    return PlanExerciseAssignment(
      id: map['id'],
      planId: map['plan_id'],
      exerciseId: map['exercise_id'],
      ordre: map['ordre'],
      nombreSeries: map['nombre_series'],
      repetitionsParSerie: map['repetitions_par_serie'],
      tempsRepos: map['temps_repos'],
      notesPersonnalisees: map['notes_personnalisees'],
      isActive: map['is_active'] == null ? true : (map['is_active'] == 1),
    );
  }

  // Méthodes du diagramme UML

  /// Calcule le temps total estimé pour cet exercice dans le plan
  int tempsTotalEstime() {
    final tempsExercice = nombreSeries * repetitionsParSerie; // estimation basique
    final tempsReposTotal = (nombreSeries - 1) * tempsRepos;
    return tempsExercice + tempsReposTotal;
  }

  /// Vérifie si l'assignation est valide
  bool estValide() {
    return nombreSeries > 0 && 
           repetitionsParSerie > 0 && 
           tempsRepos >= 0 && 
           ordre > 0;
  }

  @override
  String toString() {
    return 'PlanExerciseAssignment{id: $id, planId: $planId, exerciseId: $exerciseId, ordre: $ordre}';
  }
}
