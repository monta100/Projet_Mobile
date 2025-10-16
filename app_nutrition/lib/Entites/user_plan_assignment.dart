class UserPlanAssignment {
  int? id;
  int utilisateurId;
  int planId;
  DateTime dateAttribution;
  DateTime? dateDebut;
  DateTime? dateFin;
  bool isActive;
  String? messageCoach;
  int progression; // pourcentage de progression (0-100)

  UserPlanAssignment({
    this.id,
    required this.utilisateurId,
    required this.planId,
    required this.dateAttribution,
    this.dateDebut,
    this.dateFin,
    this.isActive = true,
    this.messageCoach,
    this.progression = 0,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'plan_id': planId,
      'date_attribution': dateAttribution.toIso8601String(),
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'message_coach': messageCoach,
      'progression': progression,
    };
  }

  // Création d'une assignation utilisateur depuis une Map
  factory UserPlanAssignment.fromMap(Map<String, dynamic> map) {
    return UserPlanAssignment(
      id: map['id'],
      utilisateurId: map['utilisateur_id'],
      planId: map['plan_id'],
      dateAttribution: DateTime.parse(map['date_attribution']),
      dateDebut: map['date_debut'] != null ? DateTime.parse(map['date_debut']) : null,
      dateFin: map['date_fin'] != null ? DateTime.parse(map['date_fin']) : null,
      isActive: map['is_active'] == null ? true : (map['is_active'] == 1),
      messageCoach: map['message_coach'],
      progression: map['progression'] ?? 0,
    );
  }

  // Méthodes du diagramme UML

  /// Démarre le plan pour l'utilisateur
  void demarrerPlan() {
    dateDebut = DateTime.now();
    isActive = true;
  }

  /// Termine le plan pour l'utilisateur
  void terminerPlan() {
    dateFin = DateTime.now();
    isActive = false;
    progression = 100;
  }

  /// Met à jour la progression
  void mettreAJourProgression(int nouvelleProgression) {
    progression = nouvelleProgression.clamp(0, 100);
  }

  /// Vérifie si le plan est en cours
  bool estEnCours() {
    if (!isActive) return false;
    final maintenant = DateTime.now();
    if (dateDebut != null && dateFin != null) {
      return maintenant.isAfter(dateDebut!) && maintenant.isBefore(dateFin!);
    }
    return dateDebut != null;
  }

  /// Calcule la durée du plan en jours
  int? dureeEnJours() {
    if (dateDebut == null || dateFin == null) return null;
    return dateFin!.difference(dateDebut!).inDays;
  }

  /// Vérifie si le plan est terminé
  bool estTermine() {
    return !isActive && progression >= 100;
  }

  @override
  String toString() {
    return 'UserPlanAssignment{id: $id, utilisateurId: $utilisateurId, planId: $planId, progression: $progression}';
  }
}
