import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static Database? _db;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'community.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, _) {
      return db.execute('''
        CREATE TABLE calls(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          phone TEXT,
          date TEXT,
          time TEXT,
          wa_sent INTEGER DEFAULT 0
        )
      ''');
    });
    return _db!;
  }

  static Future<void> insert(String phone, String date, String time, bool waSent) async {
    final db = await _database;
    await db.insert('calls', {'phone': phone, 'date': date, 'time': time, 'wa_sent': waSent ? 1 : 0});
  }

  static Future<List<Map<String, dynamic>>> getLogs() async {
    final db = await _database;
    return db.query('calls', orderBy: 'id ASC');
  }

  static Future<void> clearLogs() async {
    final db = await _database;
    await db.delete('calls');
  }
}
