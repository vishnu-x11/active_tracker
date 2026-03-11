/// Resolves conflicts between local and remote data
/// Uses last-write-wins strategy based on timestamps
class ConflictResolver {
  /// Resolve conflict between local and remote data
  /// Returns the version that should be used
  static Map<String, dynamic> resolve({
    required Map<String, dynamic>? local,
    required Map<String, dynamic>? remote,
    String timestampField = 'updatedAt',
  }) {
    // If only one exists, use it
    if (local == null) return remote ?? {};
    if (remote == null) return local;

    try {
      // Get timestamps
      final localTimestamp = _getTimestamp(local, timestampField);
      final remoteTimestamp = _getTimestamp(remote, timestampField);

      // Compare timestamps
      if (localTimestamp == null && remoteTimestamp == null) {
        // No timestamps, use remote (arbitrary)
        print('⚠️ No timestamps found - using remote version');
        return remote;
      }

      if (localTimestamp == null) {
        print('⚠️ Local missing timestamp - using remote');
        return remote;
      }

      if (remoteTimestamp == null) {
        print('⚠️ Remote missing timestamp - using local');
        return local;
      }

      // Compare timestamps
      if (remoteTimestamp.isAfter(localTimestamp)) {
        print('✅ Remote is newer - using remote version');
        return remote;
      } else if (localTimestamp.isAfter(remoteTimestamp)) {
        print('✅ Local is newer - using local version');
        return local;
      } else {
        // Same timestamp, use remote (arbitrary tiebreaker)
        print('⚠️ Same timestamp - using remote (tiebreaker)');
        return remote;
      }
    } catch (e) {
      print('❌ Error resolving conflict: $e - using remote');
      return remote;
    }
  }

  /// Extract timestamp from data object
  static DateTime? _getTimestamp(
      Map<String, dynamic> data,
      String timestampField,
      ) {
    try {
      final value = data[timestampField];

      if (value == null) return null;

      if (value is DateTime) return value;

      if (value is int) {
        // Unix timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      if (value is String) {
        // ISO 8601 string
        return DateTime.parse(value);
      }

      return null;
    } catch (e) {
      print('⚠️ Error parsing timestamp: $e');
      return null;
    }
  }

  /// Check if data has conflicts
  static bool hasConflict({
    required Map<String, dynamic>? local,
    required Map<String, dynamic>? remote,
    List<String> ignoreFields = const [],
  }) {
    if (local == null || remote == null) return false;

    try {
      // Compare all fields except ignored ones
      final localKeys = local.keys.where((k) => !ignoreFields.contains(k));
      final remoteKeys = remote.keys.where((k) => !ignoreFields.contains(k));

      // Check if different keys
      if (localKeys.toSet() != remoteKeys.toSet()) return true;

      // Check if different values
      for (final key in localKeys) {
        if (local[key] != remote[key]) return true;
      }

      return false;
    } catch (e) {
      print('⚠️ Error checking conflict: $e');
      return true; // Assume conflict on error
    }
  }

  /// Get conflict report
  static Map<String, dynamic> getConflictReport({
    required Map<String, dynamic>? local,
    required Map<String, dynamic>? remote,
  }) {
    return {
      'has_conflict': hasConflict(local: local, remote: remote),
      'local_version': local,
      'remote_version': remote,
      'local_timestamp': _getTimestamp(local ?? {}, 'updatedAt'),
      'remote_timestamp': _getTimestamp(remote ?? {}, 'updatedAt'),
      'resolved_version': resolve(local: local, remote: remote),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Merge two versions (for optional use)
  /// Combines fields with conflict resolution per field
  static Map<String, dynamic> merge({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
    String timestampField = 'updatedAt',
  }) {
    try {
      final merged = <String, dynamic>{};
      final allKeys = {...local.keys, ...remote.keys};

      for (final key in allKeys) {
        final localValue = local[key];
        final remoteValue = remote[key];

        // Use conflict resolution for each field
        if (localValue != null && remoteValue != null) {
          // Field exists in both - use newer
          final localTs = _getTimestamp(
            {key: localValue, timestampField: local[timestampField]},
            timestampField,
          );
          final remoteTs = _getTimestamp(
            {key: remoteValue, timestampField: remote[timestampField]},
            timestampField,
          );

          if (remoteTs != null &&
              localTs != null &&
              remoteTs.isAfter(localTs)) {
            merged[key] = remoteValue;
          } else {
            merged[key] = localValue;
          }
        } else if (remoteValue != null) {
          // Only in remote
          merged[key] = remoteValue;
        } else {
          // Only in local or in both
          merged[key] = localValue;
        }
      }

      return merged;
    } catch (e) {
      print('❌ Error merging versions: $e');
      return remote; // Use remote on error
    }
  }
}