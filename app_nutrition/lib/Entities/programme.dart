class Programme {
  static const String tableName = 'programmes';

  final int? id;
  final String nom;
  final String objectif;
  final String dateDebut;
  final String dateFin;
  final int? userId; // utilisateur propriétaire

  Programme({
    this.id,
    required this.nom,
    required this.objectif,
    required this.dateDebut,
    required this.dateFin,
    this.userId,
  });

  Programme copyWith({
    int? id,
    String? nom,
    String? objectif,
    String? dateDebut,
    String? dateFin,
    int? userId,
  }) {
    return Programme(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      objectif: objectif ?? this.objectif,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'objectif': objectif,
    'date_debut': dateDebut,
    'date_fin': dateFin,
    'user_id': userId,
  };

  factory Programme.fromMap(Map<String, dynamic> map) => Programme(
    id: map['id'] as int?,
    nom: map['nom'] as String,
    objectif: map['objectif'] as String,
    dateDebut: map['date_debut'] as String,
    dateFin: map['date_fin'] as String,
    userId: map['user_id'] as int?,
  );
}
