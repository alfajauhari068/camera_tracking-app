import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Simple SQLite helper for tracking logs.
class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tracking_logs.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, fileName);
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } catch (e) {
      // rethrow with clear message
      throw Exception('Failed to open database: $e');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracking_logs(
        id TEXT PRIMARY KEY,
        imagePath TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        accuracy REAL,
        timestamp TEXT,
        type TEXT,
        reportCategory TEXT,
        reportNote TEXT
      )
    ''');
  }

  Future<void> insert(String table, Map<String, dynamic> values) async {
    try {
      final db = await database;
      await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw Exception('Failed to insert into $table: $e');
    }
  }

  Future<List<Map<String, dynamic>>> queryAll(String table, {String? orderBy}) async {
    try {
      final db = await database;
      return await db.query(table, orderBy: orderBy);
    } catch (e) {
      throw Exception('Failed to query $table: $e');
    }
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw Exception('Failed to delete from $table: $e');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
