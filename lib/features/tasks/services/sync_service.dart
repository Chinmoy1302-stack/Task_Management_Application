import 'package:flutter/foundation.dart';
import '../data/repositories/task_repository.dart';

class SyncService {
  final TaskRepository _taskRepository;
  bool _isSyncing = false;

  SyncService({required TaskRepository taskRepository})
      : _taskRepository = taskRepository;

  bool get isSyncing => _isSyncing;

  /// Sync unsynced tasks to Firestore
  /// Returns the number of tasks synced
  Future<int> syncTasks(String userId) async {
    if (_isSyncing) {
      debugPrint('Sync already in progress');
      return 0;
    }

    _isSyncing = true;
    try {
      final syncedCount = await _taskRepository.syncTasks(userId);
      debugPrint('Synced $syncedCount tasks');
      return syncedCount;
    } catch (e) {
      debugPrint('Sync error: $e');
      return 0;
    } finally {
      _isSyncing = false;
    }
  }

  /// Refresh tasks from Firestore
  Future<void> refreshTasks(String userId) async {
    try {
      await _taskRepository.refreshTasks(userId);
      debugPrint('Tasks refreshed from Firestore');
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  /// Get count of unsynced tasks
  int getUnsyncedCount(String userId) {
    return _taskRepository.getUnsyncedCount(userId);
  }
}
