class ProgressTracking {
  final String metric; // e.g., 'weight', 'body_fat', 'muscle_mass'
  final double value;
  final DateTime date;
  final String displayName; // localized/user-friendly name of the metric
  final String formattedValue; // e.g., "72.4 kg"
  final String? notes;

  ProgressTracking({
    required this.metric,
    required this.value,
    required this.date,
    required this.displayName,
    required this.formattedValue,
    this.notes,
  });
}
