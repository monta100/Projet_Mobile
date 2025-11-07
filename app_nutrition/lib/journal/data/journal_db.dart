import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


class JournalDb {
static const _dbName = 'journal_v1.db';
static const _dbVersion = 1;
static final JournalDb instance = JournalDb._();
JournalDb._();


Database? _db;


Future<Database> get database async => _db ??= await _init();


Future<Database> _init() async {
final dir = await getApplicationDocumentsDirectory();
final path = p.join(dir.path, _dbName);
return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
}


FutureOr<void> _onCreate(Database db, int version) async {
await db.execute('''
CREATE TABLE health_records (
id INTEGER PRIMARY KEY AUTOINCREMENT,
type TEXT NOT NULL,
dateTime INTEGER NOT NULL,
dataValues TEXT NOT NULL,
unit TEXT,
note TEXT,
createdAt INTEGER NOT NULL,
updatedAt INTEGER NOT NULL
);
''');


await db.execute('CREATE INDEX idx_records_datetime ON health_records(dateTime);');
await db.execute('CREATE INDEX idx_records_type ON health_records(type);');
}
}