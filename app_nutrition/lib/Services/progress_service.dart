import 'dart:async';

import '../Entites/progress_tracking.dart';

/// Minimal in-memory progress service stub to unblock builds.
class ProgressService {
  static final Map<int, List<ProgressTracking>> _store = {};

  Future<List<ProgressTracking>> getUserProgress(
    int userId, {
    required String type,
  }) async {
    // Return the latest entries for the requested type, newest first
    final list = (_store[userId] ?? []).where((e) => e.metric == type).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Future.value(list);
  }

  Future<void> recordWeight(
    int userId,
    double weight, {
    double? bodyFat,
    double? muscleMass,
    String? notes,
  }) async {
    final entries = _store.putIfAbsent(userId, () => <ProgressTracking>[]);
    entries.insert(
      0,
      ProgressTracking(
        metric: 'weight',
        value: weight,
        date: DateTime.now(),
        displayName: 'Poids',
        formattedValue: '${weight.toStringAsFixed(1)} kg',
        notes: notes,
      ),
    );

    if (bodyFat != null) {
      entries.insert(
        0,
        ProgressTracking(
          metric: 'body_fat',
          value: bodyFat,
          date: DateTime.now(),
          displayName: 'Masse grasse',
          formattedValue: '${bodyFat.toStringAsFixed(1)} %',
          notes: notes,
        ),
      );
    }

    if (muscleMass != null) {
      entries.insert(
        0,
        ProgressTracking(
          metric: 'muscle_mass',
          value: muscleMass,
          date: DateTime.now(),
          displayName: 'Masse musculaire',
          formattedValue: '${muscleMass.toStringAsFixed(1)} kg',
          notes: notes,
        ),
      );
    }

    return Future.value();
  }
}
