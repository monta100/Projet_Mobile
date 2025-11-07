import 'dart:convert';

enum HealthMetricType {
  bloodPressure, // systolic/diastolic (mmHg)
  glucose,       // mg/dL
  sleep,         // hours
  weight,        // kg
  heartRate,     // bpm
  custom;        // value + unit

  String get label {
    switch (this) {
      case HealthMetricType.bloodPressure:
        return 'Pression artérielle (mmHg)';
      case HealthMetricType.glucose:
        return 'Glycémie (mg/dL)';
      case HealthMetricType.sleep:
        return 'Sommeil (heures)';
      case HealthMetricType.weight:
        return 'Poids (kg)';
      case HealthMetricType.heartRate:
        return 'Fréquence cardiaque (bpm)';
      case HealthMetricType.custom:
        return 'Indicateur personnalisé';
    }
  }
}

class HealthRecord {
  final int? id;
  final HealthMetricType type;
  final DateTime dateTime;
  /// JSON-friendly payload, e.g. {"systolic":120,"diastolic":80} or {"value":92}
  final Map<String, num> values;
  final String? unit; // used for custom
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthRecord({
    this.id,
    required this.type,
    required this.dateTime,
    required this.values,
    this.unit,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  HealthRecord copyWith({
    int? id,
    HealthMetricType? type,
    DateTime? dateTime,
    Map<String, num>? values,
    String? unit,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      values: values ?? this.values,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static HealthMetricType typeFromString(String s) =>
      HealthMetricType.values.firstWhere((e) => e.toString().split('.').last == s);

  /// DB column uses 'dataValues' to avoid the SQLite reserved word 'values'
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.toString().split('.').last,
        'dateTime': dateTime.millisecondsSinceEpoch,
        'dataValues': jsonEncode(values),
        'unit': unit,
        'note': note,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory HealthRecord.fromMap(Map<String, dynamic> m) {
    // accept both keys for backward compatibility
    final dynamic raw = m['dataValues'] ?? m['values'] ?? '{}';
    Map<String, num> parsed;
    try {
      parsed = Map<String, num>.from(jsonDecode(raw as String));
    } catch (_) {
      parsed = <String, num>{};
    }

    return HealthRecord(
      id: m['id'] as int?,
      type: typeFromString(m['type'] as String),
      dateTime: DateTime.fromMillisecondsSinceEpoch(m['dateTime'] as int),
      values: parsed,
      unit: m['unit']?.toString(),
      note: m['note']?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (m['createdAt'] ?? DateTime.now().millisecondsSinceEpoch) as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (m['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch) as int,
      ),
    );
  }
}
