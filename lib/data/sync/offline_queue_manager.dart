import 'package:sqflite/sqflite.dart';
import 'package:active_tracker/data/local/sqlite_manager.dart';

/// Represents a queued sync operation
class QueuedOperation {
  final int? id;
  final String userId;
  final String operationType; // 'create', 'update', 'delete'
  final String tableName;
  final String entityId;
  final String data; // JSON string
  final int retryCount;
  final int createdAt;
  final int? lastRetryAt;

  QueuedOperation({
    this.id,
    required this.userId,
    required this.operationType,
    required this.tableName,
    required this.entityId,
    required this.data,
    this.retryCount = 0,
    required this.createdAt,
    this.lastRetryAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'operationType': operationType,
      'tableName': tableName,
      'entityId': entityId,
      'data': data,
      'retryCount': retryCount,
      'createdAt': createdAt,
      'lastRetryAt': lastRetryAt,
    };
  }

  factory QueuedOperation.fromMap(Map<String, dynamic> map) {
    return QueuedOperation(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      operationType: map['operationType'] as String,
      tableName: map['tableName'] as String,
      entityId: map['entityId'] as String,
      data: map['data'] as String,
      retryCount: map['retryCount'] as int? ?? 0,
      createdAt: map['createdAt'] as int,
      lastRetryAt: map['lastRetryAt'] as int?,
    );
  }

  @override
  String toString() {
    return 'QueuedOperation($operationType $tableName $entityId, retry: $retryCount)';
  }
}

/// Manages offline operations queue
class OfflineQueueManager {
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();

  factory OfflineQueueManager() {
    return _instance;
  }

  OfflineQueueManager._internal();

  Database get _db => SqliteManager.getInstance();

  static const String _tableName = 'sync_queue';
  static const int maxRetries = 3;

  /// Initialize queue table if not exists
  Future<void> init() async {
    try {
      await _db.execute(
        '''CREATE TABLE IF NOT EXISTS $_tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          operationType TEXT NOT NULL,
          tableName TEXT NOT NULL,
          entityId TEXT NOT NULL,
          data TEXT NOT NULL,
          retryCount INTEGER DEFAULT 0,
          createdAt INTEGER NOT NULL,
          lastRetryAt INTEGER
        )''',
      );
      print('✅ Offline queue table initialized');
    } catch (e) {
      print('❌ Error initializing queue: $e');
    }
  }

  /// Add operation to queue
  Future<int> addOperation({
    required String userId,
    required String operationType,
    required String tableName,
    required String entityId,
    required String data,
  }) async {
    try {
      final operation = QueuedOperation(
        userId: userId,
        operationType: operationType,
        tableName: tableName,
        entityId: entityId,
        data: data,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final id = await _db.insert(_tableName, operation.toMap());
      print('✅ Operation queued: $operationType $tableName');
      return id;
    } catch (e) {
      print('❌ Error adding operation to queue: $e');
      rethrow;
    }
  }

  /// Get all pending operations
  Future<List<QueuedOperation>> getPendingOperations({
    String? userId,
  }) async {
    try {
      final result = await _db.query(
        _tableName,
        where: userId != null ? 'userId = ?' : null,
        whereArgs: userId != null ? [userId] : null,
        orderBy: 'createdAt ASC',
      );

      return result.map((map) => QueuedOperation.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting pending operations: $e');
      return [];
    }
  }

  /// Get operations for specific table
  Future<List<QueuedOperation>> getOperationsForTable({
    required String tableName,
    String? userId,
  }) async {
    try {
      final result = await _db.query(
        _tableName,
        where: userId != null
            ? 'tableName = ? AND userId = ?'
            : 'tableName = ?',
        whereArgs: userId != null ? [tableName, userId] : [tableName],
        orderBy: 'createdAt ASC',
      );

      return result.map((map) => QueuedOperation.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting operations for table: $e');
      return [];
    }
  }

  /// Mark operation as processed (delete from queue)
  Future<void> removeOperation(int operationId) async {
    try {
      await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [operationId],
      );
      print('✅ Operation removed from queue');
    } catch (e) {
      print('❌ Error removing operation: $e');
      rethrow;
    }
  }

  /// Increment retry count
  Future<void> incrementRetryCount(int operationId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.rawUpdate(
        'UPDATE $_tableName SET retryCount = retryCount + 1, lastRetryAt = ? WHERE id = ?',
        [now, operationId],
      );
      print('✅ Retry count incremented');
    } catch (e) {
      print('❌ Error incrementing retry count: $e');
      rethrow;
    }
  }

  /// Get operations that can be retried
  Future<List<QueuedOperation>> getRetryableOperations() async {
    try {
      final result = await _db.query(
        _tableName,
        where: 'retryCount < ?',
        whereArgs: [maxRetries],
        orderBy: 'createdAt ASC',
      );

      return result.map((map) => QueuedOperation.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting retryable operations: $e');
      return [];
    }
  }

  /// Clear queue
  Future<void> clearQueue({String? userId}) async {
    try {
      await _db.delete(
        _tableName,
        where: userId != null ? 'userId = ?' : null,
        whereArgs: userId != null ? [userId] : null,
      );
      print('✅ Queue cleared');
    } catch (e) {
      print('❌ Error clearing queue: $e');
      rethrow;
    }
  }

  /// Get queue stats
  Future<Map<String, dynamic>> getQueueStats({String? userId}) async {
    try {
      final total = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName${userId != null ? ' WHERE userId = ?' : ''}',
        userId != null ? [userId] : [],
      );

      final byType = await _db.rawQuery(
        'SELECT operationType, COUNT(*) as count FROM $_tableName${userId != null ? ' WHERE userId = ?' : ''} GROUP BY operationType',
        userId != null ? [userId] : [],
      );

      final failed = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE retryCount >= ?${userId != null ? ' AND userId = ?' : ''}',
        userId != null ? [maxRetries, userId] : [maxRetries],
      );

      return {
        'total': (total.first['count'] as int?) ?? 0,
        'by_type': byType,
        'failed': (failed.first['count'] as int?) ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting queue stats: $e');
      return {};
    }
  }
}