import '../../../../core/error/failures.dart';
import '../../../../core/services/db_helper.dart';
import '../../domain/entities/tracking.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../models/tracking_model.dart';

class TrackingRepositorySqliteImpl implements TrackingRepository {
  final DBHelper _dbHelper;
  static const String _table = 'tracking_logs';

  TrackingRepositorySqliteImpl({DBHelper? dbHelper}) : _dbHelper = dbHelper ?? DBHelper.instance;

  @override
  Future<void> saveTracking(Tracking tracking) async {
    try {
      final model = TrackingModel.fromEntity(tracking);
      await _dbHelper.insert(_table, model.toMap());
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to save tracking to SQLite: $e');
    }
  }

  @override
  Future<List<Tracking>> getAllTracking() async {
    try {
      final rows = await _dbHelper.queryAll(_table, orderBy: 'timestamp DESC');
      return rows.map((r) => TrackingModel.fromMap(r)).toList();
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to read tracking from SQLite: $e');
    }
  }

  @override
  Future<Tracking?> getTrackingById(String id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      return TrackingModel.fromMap(maps.first);
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to query tracking by id: $e');
    }
  }

  @override
  Future<void> deleteTracking(String id) async {
    try {
      await _dbHelper.delete(_table, 'id = ?', [id]);
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to delete tracking from SQLite: $e');
    }
  }
}
