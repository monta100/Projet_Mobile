class Exercice {
  static const String tableName = 'exercices';

  final int? id;
  final String nom;
  final String description;
  final int repetitions;
  final String imagePath;
  final String videoPath;
  final int programmeId; // 🔗 lien avec Programme

  Exercice({
    this.id,
    required this.nom,
    required this.description,
    required this.repetitions,
    required this.imagePath,
    required this.videoPath,
    required this.programmeId,
  });

  Exercice copyWith({
    int? id,
    String? nom,
    String? description,
    int? repetitions,
    String? imagePath,
    String? videoPath,
    int? programmeId,
  }) {
    return Exercice(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      repetitions: repetitions ?? this.repetitions,
      imagePath: imagePath ?? this.imagePath,
      videoPath: videoPath ?? this.videoPath,
      programmeId: programmeId ?? this.programmeId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'description': description,
        'repetitions': repetitions,
        'image_path': imagePath,
        'video_path': videoPath,
        'programme_id': programmeId,
      };

  factory Exercice.fromMap(Map<String, dynamic> map) => Exercice(
        id: map['id'] as int?,
        nom: map['nom'] as String,
        description: map['description'] as String,
        repetitions: (map['repetitions'] as num).toInt(),
        imagePath: map['image_path'] as String,
        videoPath: map['video_path'] as String,
        programmeId: map['programme_id'] as int,
      );
}
