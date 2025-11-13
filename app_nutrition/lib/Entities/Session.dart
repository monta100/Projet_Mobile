class Session {
  static const String tableName = 'sessions';

  final int? id;
  final String typeActivite; // ex : cardio, musculation, yoga...
  final int duree; // en minutes
  final String intensite; // faible, moyenne, forte
  final int calories; // calories brûlées
  final String date; // date de la séance
  final int programmeId; // lien avec un programme (facultatif)
  final int? userId; // utilisateur propriétaire

  Session({
    this.id,
    required this.typeActivite,
    required this.duree,
    required this.intensite,
    required this.calories,
    required this.date,
    required this.programmeId,
    this.userId,
  });

  Session copyWith({
    int? id,
    String? typeActivite,
    int? duree,
    String? intensite,
    int? calories,
    String? date,
    int? programmeId,
    int? userId,
  }) {
    return Session(
      id: id ?? this.id,
      typeActivite: typeActivite ?? this.typeActivite,
      duree: duree ?? this.duree,
      intensite: intensite ?? this.intensite,
      calories: calories ?? this.calories,
      date: date ?? this.date,
      programmeId: programmeId ?? this.programmeId,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type_activite': typeActivite,
    'duree': duree,
    'intensite': intensite,
    'calories': calories,
    'date': date,
    'programme_id': programmeId,
    'user_id': userId,
  };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
    id: map['id'] as int?,
    typeActivite: map['type_activite'] as String,
    duree: map['duree'] is int
        ? map['duree'] as int
        : int.tryParse(map['duree'].toString()) ?? 0,
    intensite: map['intensite'] as String,
    calories: map['calories'] is int
        ? map['calories'] as int
        : int.tryParse(map['calories'].toString()) ?? 0,
    date: map['date']?.toString() ?? '',
    programmeId: map['programme_id'] is int
        ? map['programme_id'] as int
        : int.tryParse(map['programme_id']?.toString() ?? '0') ?? 0,
    userId: map['user_id'] is int
        ? map['user_id'] as int
        : int.tryParse(map['user_id']?.toString() ?? ''),
  );
}
