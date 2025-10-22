class ProgressTracking {
  final int? id;
  final int utilisateurId;
  final int? planId;
  final int? objectiveId;
  final DateTime date;
  final String type; // 'workout', 'weight', 'measurement', 'achievement'
  final String metric; // 'weight', 'body_fat', 'muscle_mass', 'calories', 'duration', etc.
  final double value;
  final String? unit; // 'kg', '%', 'kcal', 'min', etc.
  final String? notes;
  final Map<String, dynamic>? metadata; // Données supplémentaires (JSON)
  final DateTime dateCreated;

  ProgressTracking({
    this.id,
    required this.utilisateurId,
    this.planId,
    this.objectiveId,
    required this.date,
    required this.type,
    required this.metric,
    required this.value,
    this.unit,
    this.notes,
    this.metadata,
    required this.dateCreated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'plan_id': planId,
      'objective_id': objectiveId,
      'date': date.toIso8601String(),
      'type': type,
      'metric': metric,
      'value': value,
      'unit': unit,
      'notes': notes,
      'metadata': metadata != null ? metadata.toString() : null,
      'date_created': dateCreated.toIso8601String(),
    };
  }

  factory ProgressTracking.fromMap(Map<String, dynamic> map) {
    return ProgressTracking(
      id: map['id'],
      utilisateurId: map['utilisateur_id'],
      planId: map['plan_id'],
      objectiveId: map['objective_id'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      metric: map['metric'],
      value: map['value'].toDouble(),
      unit: map['unit'],
      notes: map['notes'],
      metadata: map['metadata'] != null ? _parseMetadata(map['metadata']) : null,
      dateCreated: DateTime.parse(map['date_created']),
    );
  }

  static Map<String, dynamic>? _parseMetadata(String metadataString) {
    try {
      // Simple JSON parsing - in a real app, you'd use proper JSON parsing
      return {'raw': metadataString};
    } catch (e) {
      return null;
    }
  }

  // Méthodes utilitaires
  String get formattedValue {
    if (unit != null) {
      return '${value.toStringAsFixed(1)} $unit';
    }
    return value.toStringAsFixed(1);
  }

  String get displayName {
    switch (metric) {
      case 'weight':
        return 'Poids';
      case 'body_fat':
        return 'Masse grasse';
      case 'muscle_mass':
        return 'Masse musculaire';
      case 'calories':
        return 'Calories brûlées';
      case 'duration':
        return 'Durée d\'entraînement';
      case 'reps':
        return 'Répétitions';
      case 'sets':
        return 'Séries';
      case 'distance':
        return 'Distance';
      case 'heart_rate':
        return 'Fréquence cardiaque';
      default:
        return metric;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'workout':
        return 'Entraînement';
      case 'weight':
        return 'Pesée';
      case 'measurement':
        return 'Mesure corporelle';
      case 'achievement':
        return 'Récompense';
      default:
        return type;
    }
  }
}
