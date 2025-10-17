class Progression {
  static const String tableName = 'progressions';

  final int? id;
  final String date;
  final int caloriesBrulees;
  final int dureeTotale;
  final String commentaire;
  final int sessionId;

  Progression({
    this.id,
    required this.date,
    required this.caloriesBrulees,
    required this.dureeTotale,
    required this.commentaire,
    required this.sessionId,
  });

  Progression copyWith({
    int? id,
    String? date,
    int? caloriesBrulees,
    int? dureeTotale,
    String? commentaire,
    int? sessionId,
  }) {
    return Progression(
      id: id ?? this.id,
      date: date ?? this.date,
      caloriesBrulees: caloriesBrulees ?? this.caloriesBrulees,
      dureeTotale: dureeTotale ?? this.dureeTotale,
      commentaire: commentaire ?? this.commentaire,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'calories_brulees': caloriesBrulees,
        'duree_totale': dureeTotale,
        'commentaire': commentaire,
        'session_id': sessionId,
      };

  factory Progression.fromMap(Map<String, dynamic> map) => Progression(
        id: map['id'] as int?,
        date: map['date'] as String,
        caloriesBrulees: map['calories_brulees'] as int,
        dureeTotale: map['duree_totale'] as int,
        commentaire: map['commentaire'] as String,
        sessionId: map['session_id'] as int,
      );
}
