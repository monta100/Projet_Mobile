class Recette {
  static const String tableName = 'recettes';

  final int? id;
  final String nom;
  final String? description;
  final double calories;
  final int? repasId; // nullable: recette indépendante ou liée à un repas
  final int publie; // 0 = brouillon, 1 = publié
 final String? imageUrl; // URL de l'image de la recette
  final int?
  utilisateurId; // auteur de la recette (peut être null pour anciennes données)

  Recette({
    this.id,
    required this.nom,
    this.description,
    required this.calories,
    this.repasId,
    this.publie = 0,
    this.imageUrl,
    this.utilisateurId,
  });

  Recette copyWith({
    int? id,
    String? nom,
    String? description,
    double? calories,
    int? repasId,
    int? publie,
     String? imageUrl,
    int? utilisateurId,
  }) {
    return Recette(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      repasId: repasId ?? this.repasId,
      publie: publie ?? this.publie,
       imageUrl: imageUrl ?? this.imageUrl, // ✅ ajouté ici

      utilisateurId: utilisateurId ?? this.utilisateurId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'description': description,
    'calories': calories,
    'repas_id': repasId,
    'publie': publie,
    'imageUrl': imageUrl, // ✅ ajouté ici
    'utilisateur_id': utilisateurId,
  };

  factory Recette.fromMap(Map<String, dynamic> map) => Recette(
    id: map['id'] as int?,
    nom: map['nom'] as String,
    description: map['description'] as String?,
    calories: (map['calories'] as num).toDouble(),
    repasId: map['repas_id'] as int?,
    publie: (map['publie'] as int?) ?? 0,
    imageUrl: map['imageUrl'] as String?, // ✅ ajouté ici
    utilisateurId: map['utilisateur_id'] as int?,
  );
}
