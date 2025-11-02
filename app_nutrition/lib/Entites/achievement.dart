class Achievement {
  int? id;
  String nom;
  String description;
  String icone;
  String couleur;
  int points;
  String type; // 'workout', 'streak', 'calories', 'duration', 'special'
  int? conditionValue; // valeur nécessaire pour débloquer
  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    this.id,
    required this.nom,
    required this.description,
    required this.icone,
    required this.couleur,
    required this.points,
    required this.type,
    this.conditionValue,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'icone': icone,
      'couleur': couleur,
      'points': points,
      'type': type,
      'condition_value': conditionValue,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  // Création d'un achievement depuis une Map
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      nom: map['nom'],
      description: map['description'],
      icone: map['icone'],
      couleur: map['couleur'],
      points: map['points'],
      type: map['type'],
      conditionValue: map['condition_value'],
      isUnlocked: map['is_unlocked'] == null
          ? false
          : (map['is_unlocked'] == 1),
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'])
          : null,
    );
  }

  /// Débloque l'achievement
  void unlock() {
    isUnlocked = true;
    unlockedAt = DateTime.now();
  }

  /// Vérifie si l'achievement peut être débloqué
  bool canUnlock(int currentValue) {
    if (isUnlocked) return false;
    if (conditionValue == null) return true;
    return currentValue >= conditionValue!;
  }

  @override
  String toString() {
    return 'Achievement{id: $id, nom: $nom, type: $type, isUnlocked: $isUnlocked}';
  }
}
