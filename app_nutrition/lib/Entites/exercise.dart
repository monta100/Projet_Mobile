class Exercise {
  int? id;
  String nom;
  String description;
  String type; // cardio, musculation, mobilité, stretching, etc.
  String partieCorps; // jambes, bras, dos, abdos, etc.
  String niveau; // débutant, intermédiaire, avancé
  String objectif; // perte de poids, gain musculaire, tonification, performance
  String materiel; // aucun, haltères, élastique, machine, etc.
  String? videoUrl;
  String? imageUrl;
  int dureeEstimee; // en minutes
  int caloriesEstimees; // calories brûlées par minute
  String? instructions; // instructions détaillées
  bool isActive;

  Exercise({
    this.id,
    required this.nom,
    required this.description,
    required this.type,
    required this.partieCorps,
    required this.niveau,
    required this.objectif,
    required this.materiel,
    this.videoUrl,
    this.imageUrl,
    required this.dureeEstimee,
    required this.caloriesEstimees,
    this.instructions,
    this.isActive = true,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'type': type,
      'partie_corps': partieCorps,
      'niveau': niveau,
      'objectif': objectif,
      'materiel': materiel,
      'video_url': videoUrl,
      'image_url': imageUrl,
      'duree_estimee': dureeEstimee,
      'calories_estimees': caloriesEstimees,
      'instructions': instructions,
      'is_active': isActive ? 1 : 0,
    };
  }

  // Création d'un exercice depuis une Map
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      nom: map['nom'],
      description: map['description'],
      type: map['type'],
      partieCorps: map['partie_corps'],
      niveau: map['niveau'],
      objectif: map['objectif'],
      materiel: map['materiel'],
      videoUrl: map['video_url'],
      imageUrl: map['image_url'],
      dureeEstimee: map['duree_estimee'],
      caloriesEstimees: map['calories_estimees'],
      instructions: map['instructions'],
      isActive: map['is_active'] == null ? true : (map['is_active'] == 1),
    );
  }

  // Méthodes du diagramme UML

  /// Calcule les calories brûlées pour une durée donnée
  int calculerCalories(int dureeMinutes) {
    return (caloriesEstimees * dureeMinutes).round();
  }

  /// Vérifie si l'exercice est adapté à un niveau donné
  bool estAdaptePourNiveau(String niveauUtilisateur) {
    final niveaux = ['débutant', 'intermédiaire', 'avancé'];
    final indexNiveau = niveaux.indexOf(niveau);
    final indexUtilisateur = niveaux.indexOf(niveauUtilisateur);
    return indexUtilisateur >= indexNiveau;
  }

  /// Vérifie si l'exercice correspond à un objectif donné
  bool correspondAObjectif(String objectifUtilisateur) {
    return objectif.toLowerCase().contains(objectifUtilisateur.toLowerCase());
  }

  /// Vérifie si l'exercice cible une partie du corps donnée
  bool ciblePartieCorps(String partie) {
    return partieCorps.toLowerCase().contains(partie.toLowerCase());
  }

  @override
  String toString() {
    return 'Exercise{id: $id, nom: $nom, type: $type, niveau: $niveau, objectif: $objectif}';
  }
}
