class Repas {
  static const String tableName = 'repas';

  final int? id;
  final String type;
  final DateTime date;
  final double caloriesTotales;
  final String nom;
  final int utilisateurId;

  Repas({
    this.id,
    required this.type,
    required this.date,
    required this.caloriesTotales,
    required this.nom,
    required this.utilisateurId,
  });

  Repas copyWith({
    int? id,
    String? type,
    DateTime? date,
    double? caloriesTotales,
    String? nom,
    int? utilisateurId,
  }) => Repas(
    id: id ?? this.id,
    type: type ?? this.type,
    date: date ?? this.date,
    caloriesTotales: caloriesTotales ?? this.caloriesTotales,
    nom: nom ?? this.nom,
    utilisateurId: utilisateurId ?? this.utilisateurId,
  );

  // ✅ Ajout du champ 'nom' ici
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'date': date.toIso8601String(),
    'calories_totales': caloriesTotales,
    'nom': nom,
    'utilisateur_id': utilisateurId,
  };

  factory Repas.fromMap(Map<String, dynamic> map) => Repas(
    id: map['id'] as int?,
    type: map['type'] as String,
    date: DateTime.parse(map['date'] as String),
    caloriesTotales: (map['calories_totales'] as num).toDouble(),
    nom: map['nom'] as String,
    utilisateurId: map['utilisateur_id'] as int,
  );
}
