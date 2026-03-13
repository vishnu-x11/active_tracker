import 'package:flutter/material.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key,
    required this.isOnline,
    this.isSyncing = false,
    this.lastSync,
  });

  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    if (isSyncing) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Syncing...',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
    }

    if (!isOnline) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              'Offline',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_done,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            'Synced',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.green,
            ),
          ),
          if (lastSync != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${_getTimeAgo(lastSync!)})',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}