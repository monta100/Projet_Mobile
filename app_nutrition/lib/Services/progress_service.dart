import '../Entites/progress_tracking.dart';
import '../Entites/progress_stats.dart';
import '../Entites/user_objective.dart';
import '../Entites/exercise_session.dart';
import '../Services/database_helper.dart';

class ProgressService {
  final DatabaseHelper _db = DatabaseHelper();

  // Ajouter une entrée de progression
  Future<int> addProgressEntry(ProgressTracking entry) async {
    return await _db.insert('progress_tracking', entry.toMap());
  }

  // Obtenir toutes les entrées de progression d'un utilisateur
  Future<List<ProgressTracking>> getUserProgress(int utilisateurId, {
    String? type,
    String? metric,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;
    
    String whereClause = 'utilisateur_id = ?';
    List<dynamic> whereArgs = [utilisateurId];
    
    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }
    
    if (metric != null) {
      whereClause += ' AND metric = ?';
      whereArgs.add(metric);
    }
    
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    final rows = await db.query(
      'progress_tracking',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    
    return rows.map((r) => ProgressTracking.fromMap(r)).toList();
  }

  // Obtenir les statistiques de progression
  Future<ProgressStats> getProgressStats(int utilisateurId, String period) async {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (period) {
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }
    
    final endDate = now;
    
    // Obtenir les données d'entraînement
    final workoutEntries = await getUserProgress(
      utilisateurId,
      type: 'workout',
      startDate: startDate,
      endDate: endDate,
    );
    
    // Obtenir les données de poids
    final weightEntries = await getUserProgress(
      utilisateurId,
      type: 'weight',
      startDate: startDate,
      endDate: endDate,
    );
    
    // Calculer les statistiques d'entraînement
    final totalWorkouts = workoutEntries.length;
    final totalCaloriesBurned = workoutEntries
        .where((e) => e.metric == 'calories')
        .fold(0.0, (sum, e) => sum + e.value);
    final totalDuration = workoutEntries
        .where((e) => e.metric == 'duration')
        .fold(0.0, (sum, e) => sum + e.value);
    final averageWorkoutDuration = totalWorkouts > 0 ? totalDuration / totalWorkouts : 0.0;
    final totalSets = workoutEntries
        .where((e) => e.metric == 'sets')
        .fold(0, (sum, e) => sum + e.value.toInt());
    final totalReps = workoutEntries
        .where((e) => e.metric == 'reps')
        .fold(0, (sum, e) => sum + e.value.toInt());
    
    // Calculer les statistiques de poids
    final sortedWeightEntries = weightEntries.where((e) => e.metric == 'weight').toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final startWeight = sortedWeightEntries.isNotEmpty ? sortedWeightEntries.first.value : null;
    final endWeight = sortedWeightEntries.isNotEmpty ? sortedWeightEntries.last.value : null;
    final weightChange = (startWeight != null && endWeight != null) ? endWeight - startWeight : null;
    final averageWeight = sortedWeightEntries.isNotEmpty 
        ? sortedWeightEntries.fold(0.0, (sum, e) => sum + e.value) / sortedWeightEntries.length 
        : null;
    
    // Calculer les statistiques corporelles
    final bodyFatEntries = weightEntries.where((e) => e.metric == 'body_fat').toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final startBodyFat = bodyFatEntries.isNotEmpty ? bodyFatEntries.first.value : null;
    final endBodyFat = bodyFatEntries.isNotEmpty ? bodyFatEntries.last.value : null;
    final bodyFatChange = (startBodyFat != null && endBodyFat != null) ? endBodyFat - startBodyFat : null;
    
    final muscleMassEntries = weightEntries.where((e) => e.metric == 'muscle_mass').toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final startMuscleMass = muscleMassEntries.isNotEmpty ? muscleMassEntries.first.value : null;
    final endMuscleMass = muscleMassEntries.isNotEmpty ? muscleMassEntries.last.value : null;
    final muscleMassChange = (startMuscleMass != null && endMuscleMass != null) ? endMuscleMass - startMuscleMass : null;
    
    // Obtenir les objectifs
    final objectives = await _db.getUserObjectives(utilisateurId);
    final totalObjectives = objectives.length;
    final completedObjectives = objectives.where((o) => o.estAtteint).length;
    final objectiveCompletionRate = totalObjectives > 0 ? (completedObjectives / totalObjectives) * 100 : 0.0;
    
    // Calculer la consistance
    final workoutDays = workoutEntries.map((e) => e.date.day).toSet().length;
    final totalDays = endDate.difference(startDate).inDays + 1;
    final consistencyRate = totalDays > 0 ? (workoutDays / totalDays) * 100 : 0.0;
    
    // Calculer les séries (streaks)
    final workoutDates = workoutEntries.map((e) => e.date).toSet().toList()..sort();
    final streaks = _calculateStreaks(workoutDates);
    final longestStreak = streaks.isNotEmpty ? streaks.reduce((a, b) => a > b ? a : b) : 0;
    final currentStreak = _calculateCurrentStreak(workoutDates, now);
    
    // Calculer la progression par exercice
    final exerciseProgress = await _calculateExerciseProgress(utilisateurId, startDate, endDate);
    
    // Calculer les tendances
    final weightTrends = _calculateWeightTrends(sortedWeightEntries);
    final workoutTrends = _calculateWorkoutTrends(workoutEntries);
    
    return ProgressStats(
      utilisateurId: utilisateurId,
      period: period,
      startDate: startDate,
      endDate: endDate,
      totalWorkouts: totalWorkouts,
      totalCaloriesBurned: totalCaloriesBurned,
      totalDuration: totalDuration,
      averageWorkoutDuration: averageWorkoutDuration,
      totalSets: totalSets,
      totalReps: totalReps,
      startWeight: startWeight,
      endWeight: endWeight,
      weightChange: weightChange,
      averageWeight: averageWeight,
      startBodyFat: startBodyFat,
      endBodyFat: endBodyFat,
      bodyFatChange: bodyFatChange,
      startMuscleMass: startMuscleMass,
      endMuscleMass: endMuscleMass,
      muscleMassChange: muscleMassChange,
      totalObjectives: totalObjectives,
      completedObjectives: completedObjectives,
      objectiveCompletionRate: objectiveCompletionRate,
      totalAchievements: 0, // À implémenter
      newAchievements: 0, // À implémenter
      workoutDays: workoutDays,
      consistencyRate: consistencyRate,
      longestStreak: longestStreak,
      currentStreak: currentStreak,
      exerciseProgress: exerciseProgress,
      weightTrends: weightTrends,
      workoutTrends: workoutTrends,
    );
  }

  // Enregistrer la progression d'une séance d'entraînement
  Future<void> recordWorkoutProgress(ExerciseSession session) async {
    final entries = <ProgressTracking>[];
    
    // Durée de la séance
    if (session.dateDebut != null) {
      entries.add(ProgressTracking(
        utilisateurId: session.utilisateurId,
        planId: session.planId,
        date: session.dateDebut!,
        type: 'workout',
        metric: 'duration',
        value: (session.dureeReelle ?? 0).toDouble(),
        unit: 'min',
        dateCreated: DateTime.now(),
      ));
    }
    
    // Calories brûlées
    if (session.dateDebut != null && session.caloriesBrulees != null) {
      entries.add(ProgressTracking(
        utilisateurId: session.utilisateurId,
        planId: session.planId,
        date: session.dateDebut!,
        type: 'workout',
        metric: 'calories',
        value: session.caloriesBrulees!.toDouble(),
        unit: 'kcal',
        dateCreated: DateTime.now(),
      ));
    }
    
    // Enregistrer toutes les entrées
    for (final entry in entries) {
      await addProgressEntry(entry);
    }
  }

  // Enregistrer une pesée
  Future<void> recordWeight(int utilisateurId, double weight, {
    double? bodyFat,
    double? muscleMass,
    String? notes,
  }) async {
    final entries = <ProgressTracking>[];
    
    // Poids
    entries.add(ProgressTracking(
      utilisateurId: utilisateurId,
      date: DateTime.now(),
      type: 'weight',
      metric: 'weight',
      value: weight,
      unit: 'kg',
      notes: notes,
      dateCreated: DateTime.now(),
    ));
    
    // Masse grasse (si fournie)
    if (bodyFat != null) {
      entries.add(ProgressTracking(
        utilisateurId: utilisateurId,
        date: DateTime.now(),
        type: 'weight',
        metric: 'body_fat',
        value: bodyFat,
        unit: '%',
        notes: notes,
        dateCreated: DateTime.now(),
      ));
    }
    
    // Masse musculaire (si fournie)
    if (muscleMass != null) {
      entries.add(ProgressTracking(
        utilisateurId: utilisateurId,
        date: DateTime.now(),
        type: 'weight',
        metric: 'muscle_mass',
        value: muscleMass,
        unit: 'kg',
        notes: notes,
        dateCreated: DateTime.now(),
      ));
    }
    
    // Enregistrer toutes les entrées
    for (final entry in entries) {
      await addProgressEntry(entry);
    }
  }

  // Méthodes privées pour les calculs
  List<int> _calculateStreaks(List<DateTime> workoutDates) {
    if (workoutDates.isEmpty) return [];
    
    final streaks = <int>[];
    int currentStreak = 1;
    
    for (int i = 1; i < workoutDates.length; i++) {
      final daysDiff = workoutDates[i].difference(workoutDates[i - 1]).inDays;
      if (daysDiff == 1) {
        currentStreak++;
      } else {
        streaks.add(currentStreak);
        currentStreak = 1;
      }
    }
    streaks.add(currentStreak);
    
    return streaks;
  }

  int _calculateCurrentStreak(List<DateTime> workoutDates, DateTime now) {
    if (workoutDates.isEmpty) return 0;
    
    final sortedDates = workoutDates.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime currentDate = now;
    
    for (final workoutDate in sortedDates) {
      final daysDiff = currentDate.difference(workoutDate).inDays;
      if (daysDiff <= 1) {
        streak++;
        currentDate = workoutDate;
      } else {
        break;
      }
    }
    
    return streak;
  }

  Future<Map<String, ExerciseProgress>> _calculateExerciseProgress(
    int utilisateurId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Cette méthode nécessiterait des données plus détaillées sur les exercices
    // Pour l'instant, retournons une map vide
    return <String, ExerciseProgress>{};
  }

  List<WeightTrend> _calculateWeightTrends(List<ProgressTracking> weightEntries) {
    return weightEntries.map((entry) => WeightTrend(
      date: entry.date,
      weight: entry.value,
    )).toList();
  }

  List<WorkoutTrend> _calculateWorkoutTrends(List<ProgressTracking> workoutEntries) {
    final trends = <WorkoutTrend>[];
    final groupedByDate = <DateTime, List<ProgressTracking>>{};
    
    // Grouper les entrées par date
    for (final entry in workoutEntries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(entry);
    }
    
    // Créer les tendances
    for (final entry in groupedByDate.entries) {
      final date = entry.key;
      final entries = entry.value;
      
      final duration = entries
          .where((e) => e.metric == 'duration')
          .fold(0.0, (sum, e) => sum + e.value);
      final calories = entries
          .where((e) => e.metric == 'calories')
          .fold(0.0, (sum, e) => sum + e.value);
      final exercises = entries
          .where((e) => e.metric == 'exercises')
          .fold(0, (sum, e) => sum + e.value.toInt());
      
      trends.add(WorkoutTrend(
        date: date,
        duration: duration,
        calories: calories,
        exercises: exercises > 0 ? exercises : 1, // Au moins 1 exercice par défaut
      ));
    }
    
    trends.sort((a, b) => a.date.compareTo(b.date));
    return trends;
  }

  // Obtenir les dernières entrées de progression
  Future<List<ProgressTracking>> getRecentProgress(int utilisateurId, {int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.query(
      'progress_tracking',
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
      orderBy: 'date DESC',
      limit: limit,
    );
    
    return rows.map((r) => ProgressTracking.fromMap(r)).toList();
  }

  // Supprimer une entrée de progression
  Future<int> deleteProgressEntry(int id) async {
    final db = await _db.database;
    return await db.delete(
      'progress_tracking',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mettre à jour une entrée de progression
  Future<int> updateProgressEntry(ProgressTracking entry) async {
    final db = await _db.database;
    return await db.update(
      'progress_tracking',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }
}
