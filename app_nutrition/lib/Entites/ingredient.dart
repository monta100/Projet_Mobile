
class Ingredient {
  static const String tableName = 'ingredients';

  final int? id;
  final String nom;
  final double quantite;
  final String unite;
  final double calories;
  final int recetteId;

  Ingredient({
    this.id,
    required this.nom,
    required this.quantite,
    required this.unite,
    required this.calories,
    required this.recetteId,
  });

  Ingredient copyWith({
    int? id,
    String? nom,
    double? quantite,
    String? unite,
    double? calories,
    int? recetteId,
  }) {
    return Ingredient(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      quantite: quantite ?? this.quantite,
      unite: unite ?? this.unite,
      calories: calories ?? this.calories,
      recetteId: recetteId ?? this.recetteId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'quantite': quantite,
    'unite': unite,
    'calories': calories,
    'recette_id': recetteId,
  };

  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
    id: map['id'] as int?,
    nom: map['nom'] as String,
    quantite: (map['quantite'] as num).toDouble(),
    unite: map['unite'] as String,
    calories: (map['calories'] as num).toDouble(),
    recetteId: map['recette_id'] as int,
  );

 
}
