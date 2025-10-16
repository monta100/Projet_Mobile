class UserAchievement {
  int? id;
  int utilisateurId;
  int achievementId;
  DateTime unlockedAt;
  int pointsEarned;

  UserAchievement({
    this.id,
    required this.utilisateurId,
    required this.achievementId,
    required this.unlockedAt,
    required this.pointsEarned,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'points_earned': pointsEarned,
    };
  }

  // Création d'un user achievement depuis une Map
  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: map['id'],
      utilisateurId: map['utilisateur_id'],
      achievementId: map['achievement_id'],
      unlockedAt: DateTime.parse(map['unlocked_at']),
      pointsEarned: map['points_earned'],
    );
  }

  @override
  String toString() {
    return 'UserAchievement{id: $id, utilisateurId: $utilisateurId, achievementId: $achievementId, pointsEarned: $pointsEarned}';
  }
}
