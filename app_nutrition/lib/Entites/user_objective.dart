class UserObjective {
  int? id;
  int utilisateurId;
  String typeObjectif;
  String description;
  double poidsActuel;
  double poidsCible;
  double taille;
  int age;
  String niveauActivite;
  int dureeObjectif; // en semaines
  int coachId;
  DateTime dateCreation;
  DateTime dateDebut;
  DateTime dateFin;
  double progression;
  bool estAtteint;
  String? notes;

  UserObjective({
    this.id,
    required this.utilisateurId,
    required this.typeObjectif,
    required this.description,
    required this.poidsActuel,
    required this.poidsCible,
    required this.taille,
    required this.age,
    required this.niveauActivite,
    required this.dureeObjectif,
    required this.coachId,
    required this.dateCreation,
    required this.dateDebut,
    required this.dateFin,
    this.progression = 0.0,
    this.estAtteint = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateurId': utilisateurId,
      'typeObjectif': typeObjectif,
      'description': description,
      'poidsActuel': poidsActuel,
      'poidsCible': poidsCible,
      'taille': taille,
      'age': age,
      'niveauActivite': niveauActivite,
      'dureeObjectif': dureeObjectif,
      'coachId': coachId,
      'dateCreation': dateCreation.toIso8601String(),
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'progression': progression,
      'estAtteint': estAtteint,
      'notes': notes,
    };
  }

  factory UserObjective.fromMap(Map<String, dynamic> map) {
    return UserObjective(
      id: map['id'],
      utilisateurId: map['utilisateurId'],
      typeObjectif: map['typeObjectif'],
      description: map['description'],
      poidsActuel: map['poidsActuel'],
      poidsCible: map['poidsCible'],
      taille: map['taille'],
      age: map['age'],
      niveauActivite: map['niveauActivite'],
      dureeObjectif: map['dureeObjectif'],
      coachId: map['coachId'],
      dateCreation: DateTime.parse(map['dateCreation']),
      dateDebut: DateTime.parse(map['dateDebut']),
      dateFin: DateTime.parse(map['dateFin']),
      progression: map['progression'] ?? 0.0,
      estAtteint: map['estAtteint'] == 1,
      notes: map['notes'],
    );
  }

  double get imcActuel => poidsActuel / (taille * taille);
  double get imcCible => poidsCible / (taille * taille);
  
  String get imcActuelFormatted => imcActuel.toStringAsFixed(1);
  String get imcCibleFormatted => imcCible.toStringAsFixed(1);
  
  String get dureeFormatted {
    if (dureeObjectif < 4) {
      return '$dureeObjectif semaine${dureeObjectif > 1 ? 's' : ''}';
    } else {
      final mois = dureeObjectif ~/ 4;
      final semaines = dureeObjectif % 4;
      if (semaines == 0) {
        return '$mois mois';
      } else {
        return '$mois mois et $semaines semaine${semaines > 1 ? 's' : ''}';
      }
    }
  }
  
  double get progressionPourcentage => (progression / (poidsCible - poidsActuel).abs()) * 100;
  
  bool get estEnRetard => DateTime.now().isAfter(dateFin) && !estAtteint;
  
  int get joursRestants {
    final now = DateTime.now();
    if (now.isAfter(dateFin)) return 0;
    return dateFin.difference(now).inDays;
  }
}
