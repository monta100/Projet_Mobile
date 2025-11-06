// ignore_for_file: avoid_print

class Objectif {
  int? id;
  int? utilisateurId; // Relation avec Utilisateur
  String type;
  double valeurCible;
  DateTime dateFixee;
  double progression;

  Objectif({
    this.id,
    this.utilisateurId,
    required this.type,
    required this.valeurCible,
    required this.dateFixee,
    this.progression = 0.0,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'type': type,
      'valeurCible': valeurCible,
      'dateFixee': dateFixee.toIso8601String(),
      'progression': progression,
    };
  }

  // Création d'un objectif depuis une Map
  factory Objectif.fromMap(Map<String, dynamic> map) {
    return Objectif(
      id: map['id'],
      utilisateurId: map['utilisateur_id'],
      type: map['type'],
      valeurCible: map['valeurCible'].toDouble(),
      dateFixee: DateTime.parse(map['dateFixee']),
      progression: map['progression']?.toDouble() ?? 0.0,
    );
  }

  // Méthodes du diagramme UML

  /// Fixe un nouvel objectif
  void fixerObjectif(
    String nouveauType,
    double nouvelleValeur,
    DateTime nouvelleDateFixee,
  ) {
    type = nouveauType;
    valeurCible = nouvelleValeur;
    dateFixee = nouvelleDateFixee;
    progression = 0.0;
    print(
      'Objectif fixé: $type - Cible: $valeurCible - Date: ${dateFixee.toLocal()}',
    );
  }

  /// Modifie un objectif existant
  void modifierObjectif({
    String? nouveauType,
    double? nouvelleValeurCible,
    DateTime? nouvelleDateFixee,
  }) {
    if (nouveauType != null) type = nouveauType;
    if (nouvelleValeurCible != null) valeurCible = nouvelleValeurCible;
    if (nouvelleDateFixee != null) dateFixee = nouvelleDateFixee;
    print('Objectif modifié: $type');
  }

  /// Calcule la progression actuelle en pourcentage
  double calculerProgression() {
    if (valeurCible == 0) return 0.0;
    double pourcentage = (progression / valeurCible) * 100;
    return pourcentage > 100 ? 100.0 : pourcentage;
  }

  /// Met à jour la progression
  void mettreAJourProgression(double nouvelleProgression) {
    progression = nouvelleProgression;
    print(
      'Progression mise à jour: ${calculerProgression().toStringAsFixed(1)}%',
    );
  }

  /// Vérifie si l'objectif est atteint
  bool estAtteint() {
    return progression >= valeurCible;
  }

  /// Vérifie si l'objectif est en retard
  bool estEnRetard() {
    return DateTime.now().isAfter(dateFixee) && !estAtteint();
  }

  @override
  String toString() {
    return 'Objectif{id: $id, type: $type, valeurCible: $valeurCible, dateFixee: $dateFixee, progression: $progression}';
  }
}
