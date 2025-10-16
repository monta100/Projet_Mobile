class ExerciseSession {
  int? id;
  int planId;
  int exerciseId;
  int utilisateurId;
  int nombreSeries;
  int repetitionsParSerie;
  int tempsRepos; // en secondes
  int? dureeReelle; // en minutes
  DateTime? dateDebut;
  DateTime? dateFin;
  bool estTerminee;
  int? difficulte; // 1-5 étoiles
  String? commentaireUtilisateur;
  String? notesCoach;
  int? caloriesBrulees;

  ExerciseSession({
    this.id,
    required this.planId,
    required this.exerciseId,
    required this.utilisateurId,
    required this.nombreSeries,
    required this.repetitionsParSerie,
    required this.tempsRepos,
    this.dureeReelle,
    this.dateDebut,
    this.dateFin,
    this.estTerminee = false,
    this.difficulte,
    this.commentaireUtilisateur,
    this.notesCoach,
    this.caloriesBrulees,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'exercise_id': exerciseId,
      'utilisateur_id': utilisateurId,
      'nombre_series': nombreSeries,
      'repetitions_par_serie': repetitionsParSerie,
      'temps_repos': tempsRepos,
      'duree_reelle': dureeReelle,
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'est_terminee': estTerminee ? 1 : 0,
      'difficulte': difficulte,
      'commentaire_utilisateur': commentaireUtilisateur,
      'notes_coach': notesCoach,
      'calories_brulées': caloriesBrulees,
    };
  }

  // Création d'une séance depuis une Map
  factory ExerciseSession.fromMap(Map<String, dynamic> map) {
    return ExerciseSession(
      id: map['id'],
      planId: map['plan_id'],
      exerciseId: map['exercise_id'],
      utilisateurId: map['utilisateur_id'],
      nombreSeries: map['nombre_series'],
      repetitionsParSerie: map['repetitions_par_serie'],
      tempsRepos: map['temps_repos'],
      dureeReelle: map['duree_reelle'],
      dateDebut: map['date_debut'] != null ? DateTime.parse(map['date_debut']) : null,
      dateFin: map['date_fin'] != null ? DateTime.parse(map['date_fin']) : null,
      estTerminee: map['est_terminee'] == null ? false : (map['est_terminee'] == 1),
      difficulte: map['difficulte'],
      commentaireUtilisateur: map['commentaire_utilisateur'],
      notesCoach: map['notes_coach'],
      caloriesBrulees: map['calories_brulées'],
    );
  }

  // Méthodes du diagramme UML

  /// Démarre la séance d'exercice
  void demarrerSession() {
    dateDebut = DateTime.now();
    estTerminee = false;
  }

  /// Termine la séance d'exercice
  void terminerSession() {
    dateFin = DateTime.now();
    estTerminee = true;
    if (dateDebut != null) {
      dureeReelle = dateFin!.difference(dateDebut!).inMinutes;
    }
  }

  /// Calcule la durée totale de la séance
  int? dureeTotaleMinutes() {
    if (dateDebut == null || dateFin == null) return null;
    return dateFin!.difference(dateDebut!).inMinutes;
  }

  /// Calcule le temps total avec repos
  int tempsTotalAvecRepos() {
    final tempsExercice = nombreSeries * repetitionsParSerie; // estimation basique
    final tempsReposTotal = (nombreSeries - 1) * tempsRepos; // repos entre séries
    return tempsExercice + tempsReposTotal;
  }

  /// Vérifie si la séance est en cours
  bool estEnCours() {
    return dateDebut != null && !estTerminee;
  }

  /// Évalue la performance de la séance
  String evaluerPerformance() {
    if (!estTerminee) return 'En cours';
    if (difficulte == null) return 'Non évaluée';
    
    if (difficulte! <= 2) return 'Facile';
    if (difficulte! <= 3) return 'Modérée';
    if (difficulte! <= 4) return 'Difficile';
    return 'Très difficile';
  }

  @override
  String toString() {
    return 'ExerciseSession{id: $id, planId: $planId, exerciseId: $exerciseId, estTerminee: $estTerminee}';
  }
}
