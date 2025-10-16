class ProgressStats {
  final int utilisateurId;
  final String period; // 'week', 'month', 'year'
  final DateTime startDate;
  final DateTime endDate;
  
  // Statistiques d'entraînement
  final int totalWorkouts;
  final double totalCaloriesBurned;
  final double totalDuration; // en minutes
  final double averageWorkoutDuration;
  final int totalSets;
  final int totalReps;
  
  // Statistiques de poids
  final double? startWeight;
  final double? endWeight;
  final double? weightChange;
  final double? averageWeight;
  
  // Statistiques corporelles
  final double? startBodyFat;
  final double? endBodyFat;
  final double? bodyFatChange;
  final double? startMuscleMass;
  final double? endMuscleMass;
  final double? muscleMassChange;
  
  // Objectifs
  final int totalObjectives;
  final int completedObjectives;
  final double objectiveCompletionRate;
  
  // Récompenses
  final int totalAchievements;
  final int newAchievements;
  
  // Consistance
  final int workoutDays;
  final double consistencyRate; // pourcentage de jours avec entraînement
  final int longestStreak; // plus longue série d'entraînements consécutifs
  final int currentStreak; // série actuelle
  
  // Progression par exercice
  final Map<String, ExerciseProgress> exerciseProgress;
  
  // Tendances
  final List<WeightTrend> weightTrends;
  final List<WorkoutTrend> workoutTrends;

  ProgressStats({
    required this.utilisateurId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalWorkouts,
    required this.totalCaloriesBurned,
    required this.totalDuration,
    required this.averageWorkoutDuration,
    required this.totalSets,
    required this.totalReps,
    this.startWeight,
    this.endWeight,
    this.weightChange,
    this.averageWeight,
    this.startBodyFat,
    this.endBodyFat,
    this.bodyFatChange,
    this.startMuscleMass,
    this.endMuscleMass,
    this.muscleMassChange,
    required this.totalObjectives,
    required this.completedObjectives,
    required this.objectiveCompletionRate,
    required this.totalAchievements,
    required this.newAchievements,
    required this.workoutDays,
    required this.consistencyRate,
    required this.longestStreak,
    required this.currentStreak,
    required this.exerciseProgress,
    required this.weightTrends,
    required this.workoutTrends,
  });

  // Méthodes utilitaires
  String get periodDisplayName {
    switch (period) {
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      case 'year':
        return 'Cette année';
      default:
        return period;
    }
  }

  String get weightChangeFormatted {
    if (weightChange == null) return 'N/A';
    final change = weightChange!;
    if (change > 0) {
      return '+${change.toStringAsFixed(1)} kg';
    } else if (change < 0) {
      return '${change.toStringAsFixed(1)} kg';
    } else {
      return '0.0 kg';
    }
  }

  String get bodyFatChangeFormatted {
    if (bodyFatChange == null) return 'N/A';
    final change = bodyFatChange!;
    if (change > 0) {
      return '+${change.toStringAsFixed(1)}%';
    } else if (change < 0) {
      return '${change.toStringAsFixed(1)}%';
    } else {
      return '0.0%';
    }
  }

  String get muscleMassChangeFormatted {
    if (muscleMassChange == null) return 'N/A';
    final change = muscleMassChange!;
    if (change > 0) {
      return '+${change.toStringAsFixed(1)} kg';
    } else if (change < 0) {
      return '${change.toStringAsFixed(1)} kg';
    } else {
      return '0.0 kg';
    }
  }

  String get durationFormatted {
    final hours = (totalDuration / 60).floor();
    final minutes = (totalDuration % 60).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  String get averageDurationFormatted {
    final hours = (averageWorkoutDuration / 60).floor();
    final minutes = (averageWorkoutDuration % 60).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  bool get isWeightLoss {
    return weightChange != null && weightChange! < 0;
  }

  bool get isWeightGain {
    return weightChange != null && weightChange! > 0;
  }

  bool get isMuscleGain {
    return muscleMassChange != null && muscleMassChange! > 0;
  }

  bool get isBodyFatLoss {
    return bodyFatChange != null && bodyFatChange! < 0;
  }
}

class ExerciseProgress {
  final String exerciseName;
  final int totalSessions;
  final double totalWeight; // poids total soulevé
  final double maxWeight; // poids maximum
  final int totalReps;
  final int totalSets;
  final double averageReps;
  final double averageWeight;
  final double improvement; // pourcentage d'amélioration

  ExerciseProgress({
    required this.exerciseName,
    required this.totalSessions,
    required this.totalWeight,
    required this.maxWeight,
    required this.totalReps,
    required this.totalSets,
    required this.averageReps,
    required this.averageWeight,
    required this.improvement,
  });
}

class WeightTrend {
  final DateTime date;
  final double weight;
  final double? bodyFat;
  final double? muscleMass;

  WeightTrend({
    required this.date,
    required this.weight,
    this.bodyFat,
    this.muscleMass,
  });
}

class WorkoutTrend {
  final DateTime date;
  final double duration;
  final double calories;
  final int exercises;

  WorkoutTrend({
    required this.date,
    required this.duration,
    required this.calories,
    required this.exercises,
  });
}
