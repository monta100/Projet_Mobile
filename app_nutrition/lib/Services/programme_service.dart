import 'package:sqflite/sqflite.dart';
import '../Entities/programme.dart';
import 'database_helper.dart';
import 'session_service.dart';

/// 🌿 Service de gestion des programmes d'entraînement.
/// Gère toutes les opérations CRUD et les statistiques sur les programmes.
class ProgrammeService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SessionService _sessionService = SessionService();

  /// ➕ Ajoute un nouveau programme dans la base.
  /// Retourne l'ID auto-généré.
  Future<int> insertProgramme(Programme programme) async {
    final db = await _dbHelper.database;
    final data = programme.toMap();
    // Associer l'utilisateur connecté si disponible
    try {
      final user = await _sessionService.getLoggedInUser();
      if (user?.id != null) {
        data['user_id'] = user!.id;
      }
    } catch (_) {}
    final nom = (data['nom'] as String?)?.trim() ?? '';
    final objectif = (data['objectif'] as String?)?.trim() ?? '';
    if (nom.isEmpty || objectif.isEmpty) {
      throw Exception('Nom et objectif requis');
    }
    final debut = DateTime.tryParse(data['date_debut'] as String? ?? '');
    final fin = DateTime.tryParse(data['date_fin'] as String? ?? '');
    if (debut == null || fin == null) {
      throw Exception('Dates invalides');
    }
    if (fin.isBefore(debut)) {
      throw Exception('La date de fin doit être après la date de début');
    }
    if (fin.difference(debut).inDays > 365) {
      throw Exception('Durée maximale 365 jours');
    }
    return await db.insert(
      Programme.tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🔍 Récupère tous les programmes enregistrés.
  Future<List<Programme>> getAllProgrammes() async {
    final db = await _dbHelper.database;
    final user = await _sessionService.getLoggedInUser();
    final data = user?.id != null
        ? await db.query(
            Programme.tableName,
            where: 'user_id = ? OR user_id IS NULL',
            whereArgs: [user!.id],
            orderBy: 'date_debut DESC',
          )
        : await db.query(Programme.tableName, orderBy: 'date_debut DESC');
    return data.map((e) => Programme.fromMap(e)).toList();
  }

  /// 🔍 Récupère un programme par son ID.
  Future<Programme?> getProgrammeById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      Programme.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? Programme.fromMap(result.first) : null;
  }

  /// ✏️ Met à jour un programme existant.
  Future<int> updateProgramme(Programme programme) async {
    if (programme.id == null) {
      throw Exception('❌ Impossible de mettre à jour un programme sans ID.');
    }
    final db = await _dbHelper.database;
    final data = programme.toMap();
    final nom = (data['nom'] as String?)?.trim() ?? '';
    final objectif = (data['objectif'] as String?)?.trim() ?? '';
    if (nom.isEmpty || objectif.isEmpty) {
      throw Exception('Nom et objectif requis');
    }
    final debut = DateTime.tryParse(data['date_debut'] as String? ?? '');
    final fin = DateTime.tryParse(data['date_fin'] as String? ?? '');
    if (debut == null || fin == null) {
      throw Exception('Dates invalides');
    }
    if (fin.isBefore(debut)) {
      throw Exception('La date de fin doit être après la date de début');
    }
    if (fin.difference(debut).inDays > 365) {
      throw Exception('Durée maximale 365 jours');
    }
    return await db.update(
      Programme.tableName,
      data,
      where: 'id = ?',
      whereArgs: [programme.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ❌ Supprime un programme.
  Future<int> deleteProgramme(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      Programme.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 📊 Compte le nombre total de programmes.
  Future<int> getProgrammeCount() async {
    final db = await _dbHelper.database;
    final user = await _sessionService.getLoggedInUser();
    final result = user?.id != null
        ? await db.rawQuery(
            'SELECT COUNT(*) AS total FROM programmes WHERE user_id = ? OR user_id IS NULL',
            [user!.id],
          )
        : await db.rawQuery('SELECT COUNT(*) AS total FROM programmes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 🔎 Recherche des programmes par objectif.
  Future<List<Programme>> searchByObjectif(String keyword) async {
    final db = await _dbHelper.database;
    final user = await _sessionService.getLoggedInUser();
    final data = await db.query(
      Programme.tableName,
      where: user?.id != null
          ? '(objectif LIKE ?) AND (user_id = ? OR user_id IS NULL)'
          : 'objectif LIKE ?',
      whereArgs: user?.id != null ? ['%$keyword%', user!.id] : ['%$keyword%'],
    );
    return data.map((e) => Programme.fromMap(e)).toList();
  }

  /// 📅 Récupère les programmes actifs à une date donnée.
  Future<List<Programme>> getActiveProgrammes(String currentDate) async {
    final db = await _dbHelper.database;
    final user = await _sessionService.getLoggedInUser();
    final result = user?.id != null
        ? await db.rawQuery(
            '''
      SELECT * FROM programmes 
      WHERE date_debut <= ? AND date_fin >= ? AND (user_id = ? OR user_id IS NULL)
      ORDER BY date_debut ASC
    ''',
            [currentDate, currentDate, user!.id],
          )
        : await db.rawQuery(
            '''
      SELECT * FROM programmes 
      WHERE date_debut <= ? AND date_fin >= ?
      ORDER BY date_debut ASC
    ''',
            [currentDate, currentDate],
          );
    return result.map((e) => Programme.fromMap(e)).toList();
  }
}
