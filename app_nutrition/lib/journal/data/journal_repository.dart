import 'package:sqflite/sqflite.dart';
import '../models/health_record.dart';
import 'journal_db.dart';

class JournalRepository {
  Future<int> insert(HealthRecord r) async {
    final db = await JournalDb.instance.database;
    return db.insert('health_records', r.toMap());
  }

  Future<int> update(HealthRecord r) async {
    final db = await JournalDb.instance.database;
    return db.update('health_records', r.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?', whereArgs: [r.id]);
  }

  Future<int> delete(int id) async {
    final db = await JournalDb.instance.database;
    return db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HealthRecord>> fetchAll({
    HealthMetricType? type,
    DateTime? from,
    DateTime? to,
    String? noteQuery,
  }) async {
    final db = await JournalDb.instance.database;
    final where = <String>[];
    final args = <Object?>[];
    if (type != null) {
      where.add('type = ?');
      args.add(type.toString().split('.').last);
    }
    if (from != null) {
      where.add('dateTime >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('dateTime <= ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (noteQuery != null && noteQuery.trim().isNotEmpty) {
      where.add('note LIKE ?');
      args.add('%${noteQuery.trim()}%');
    }
    final rows = await db.query(
      'health_records',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'dateTime DESC',
    );
    return rows.map((e) => HealthRecord.fromMap(e)).toList();
  }

  Future<HealthRecord?> findById(int id) async {
    final db = await JournalDb.instance.database;
    final rows = await db.query('health_records', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return HealthRecord.fromMap(rows.first);
  }
}
