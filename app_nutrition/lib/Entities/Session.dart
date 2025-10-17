class Session {
  static const String tableName = 'sessions';

  final int? id;
  final String typeActivite;
  final int duree; // en minutes
  final String intensite; // faible, moyenne, forte
  final int calories;

  Session({
    this.id,
    required this.typeActivite,
    required this.duree,
    required this.intensite,
    required this.calories,
  });

  Session copyWith({
    int? id,
    String? typeActivite,
    int? duree,
    String? intensite,
    int? calories,
  }) {
    return Session(
      id: id ?? this.id,
      typeActivite: typeActivite ?? this.typeActivite,
      duree: duree ?? this.duree,
      intensite: intensite ?? this.intensite,
      calories: calories ?? this.calories,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type_activite': typeActivite,
        'duree': duree,
        'intensite': intensite,
        'calories': calories,
      };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as int?,
        typeActivite: map['type_activite'] as String,
        duree: map['duree'] as int,
        intensite: map['intensite'] as String,
        calories: map['calories'] as int,
      );
}
