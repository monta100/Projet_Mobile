class ExercisePlan {
  int? id;
  int coachId;
  String nom;
  String description;
  DateTime dateCreation;
  DateTime? dateDebut;
  DateTime? dateFin;
  bool isActive;
  String? notesCoach;

  ExercisePlan({
    this.id,
    required this.coachId,
    required this.nom,
    required this.description,
    required this.dateCreation,
    this.dateDebut,
    this.dateFin,
    this.isActive = true,
    this.notesCoach,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'nom': nom,
      'description': description,
      'date_creation': dateCreation.toIso8601String(),
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'notes_coach': notesCoach,
    };
  }

  // Création d'un plan depuis une Map
  factory ExercisePlan.fromMap(Map<String, dynamic> map) {
    return ExercisePlan(
      id: map['id'],
      coachId: map['coach_id'],
      nom: map['nom'],
      description: map['description'],
      dateCreation: DateTime.parse(map['date_creation']),
      dateDebut: map['date_debut'] != null ? DateTime.parse(map['date_debut']) : null,
      dateFin: map['date_fin'] != null ? DateTime.parse(map['date_fin']) : null,
      isActive: map['is_active'] == null ? true : (map['is_active'] == 1),
      notesCoach: map['notes_coach'],
    );
  }

  // Méthodes du diagramme UML

  /// Vérifie si le plan est actuellement actif
  bool estActif() {
    if (!isActive) return false;
    final maintenant = DateTime.now();
    if (dateDebut != null && maintenant.isBefore(dateDebut!)) return false;
    if (dateFin != null && maintenant.isAfter(dateFin!)) return false;
    return true;
  }

  /// Calcule la durée totale du plan en jours
  int? dureeEnJours() {
    if (dateDebut == null || dateFin == null) return null;
    return dateFin!.difference(dateDebut!).inDays;
  }

  /// Vérifie si le plan est en cours
  bool estEnCours() {
    if (!estActif()) return false;
    final maintenant = DateTime.now();
    if (dateDebut != null && dateFin != null) {
      return maintenant.isAfter(dateDebut!) && maintenant.isBefore(dateFin!);
    }
    return true;
  }

  @override
  String toString() {
    return 'ExercisePlan{id: $id, nom: $nom, coachId: $coachId, isActive: $isActive}';
  }
}
