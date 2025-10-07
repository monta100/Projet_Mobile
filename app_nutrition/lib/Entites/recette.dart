
class Recette {
  static const String tableName = 'recettes';

  final int? id;
  final String nom;
  final String? description;
  final double calories;
  final int repasId;

  Recette({
    this.id,
    required this.nom,
    this.description,
    required this.calories,
    required this.repasId,
  });

  Recette copyWith({
    int? id,
    String? nom,
    String? description,
    double? calories,
    int? repasId,
  }) {
    return Recette(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      repasId: repasId ?? this.repasId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'description': description,
    'calories': calories,
    'repas_id': repasId,
  };

  factory Recette.fromMap(Map<String, dynamic> map) => Recette(
    id: map['id'] as int?,
    nom: map['nom'] as String,
    description: map['description'] as String?,
    calories: (map['calories'] as num).toDouble(),
    repasId: map['repas_id'] as int,
  );

 
}
