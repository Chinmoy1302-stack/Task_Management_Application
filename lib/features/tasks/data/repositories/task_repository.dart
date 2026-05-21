import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/models/task_entity.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/objectbox_service.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final ObjectBoxService _database;
  final ConnectivityService _connectivity;

  static const Duration _firestoreTimeout = Duration(seconds: 8);

  TaskRepository({
    FirebaseFirestore? firestore,
    required ObjectBoxService database,
    ConnectivityService? connectivity,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database,
        _connectivity = connectivity ?? ConnectivityService();

  // ==================== Firestore Operations ====================

  /// Create a task — saves locally first so offline creation always works.
  Future<Task> createTask(Task task) async {
    final pendingTask = task.copyWith(
      id: _localTaskId(task.id),
      synced: false,
    );
    _database.saveTask(TaskEntity.fromTask(pendingTask));

    if (await _connectivity.isOffline) {
      debugPrint('Offline: task saved locally (${pendingTask.id})');
      return pendingTask;
    }

    try {
      final docRef = await _firestore
          .collection('tasks')
          .add(task.toFirestore())
          .timeout(_firestoreTimeout);

      final syncedTask = task.copyWith(id: docRef.id, synced: true);
      _database.deleteTask(pendingTask.id);
      _database.saveTask(TaskEntity.fromTask(syncedTask));
      return syncedTask;
    } catch (e) {
      debugPrint('Error creating task in Firestore: $e');
      return pendingTask;
    }
  }

  /// Get all tasks for a user from Firestore (local DB when offline).
  Future<List<Task>> getTasks(String userId) async {
    if (await _connectivity.isOffline) {
      final localTasks = _database.getUserTasks(userId);
      return localTasks.map((entity) => entity.toTask()).toList();
    }

    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

      // Update local database with latest data
      for (final task in tasks) {
        _database.saveTask(TaskEntity.fromTask(task));
      }

      return _mergeWithUnsynced(tasks, userId);
    } catch (e) {
      debugPrint('Error fetching tasks from Firestore: $e');
      // Fallback to local database
      final localTasks = _database.getUserTasks(userId);
      return localTasks.map((entity) => entity.toTask()).toList();
    }
  }

  /// Update a task — queues locally when offline or task is still local-only.
  Future<Task> updateTask(Task task) async {
    final localTask = task.copyWith(synced: false);
    _database.saveTask(TaskEntity.fromTask(localTask));

    final isLocalOnly = task.id.isEmpty || task.id.startsWith('local_');
    if (await _connectivity.isOffline || isLocalOnly) {
      debugPrint('Offline/local update saved (${localTask.id})');
      return localTask;
    }

    try {
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore())
          .timeout(_firestoreTimeout);

      final updatedTask = task.copyWith(synced: true);
      _database.saveTask(TaskEntity.fromTask(updatedTask));
      return updatedTask;
    } catch (e) {
      debugPrint('Error updating task in Firestore: $e');
      return localTask;
    }
  }

  /// Delete a task from Firestore
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      _database.deleteTask(taskId);
    } catch (e) {
      debugPrint('Error deleting task from Firestore: $e');
      // Mark for deletion locally (optional: could add a deleted flag)
      _database.deleteTask(taskId);
    }
  }

  // ==================== Sync Operations ====================

  /// Sync unsynced tasks to Firestore
  Future<int> syncTasks(String userId) async {
    try {
      final unsyncedTasks = _database.getUnsyncedTasks(userId);
      int syncedCount = 0;

      for (final entity in unsyncedTasks) {
        final task = entity.toTask();
        final oldLocalId = task.id;

        try {
          if (task.id.isEmpty || task.id.startsWith('local_')) {
            // New task - create in Firestore
            final docRef = await _firestore
                .collection('tasks')
                .add(task.toFirestore());

            final syncedTask = task.copyWith(
              id: docRef.id,
              synced: true,
            );
            if (oldLocalId.startsWith('local_')) {
              _database.deleteTask(oldLocalId);
            }
            _database.saveTask(TaskEntity.fromTask(syncedTask));
          } else {
            // Existing task - update in Firestore
            await _firestore
                .collection('tasks')
                .doc(task.id)
                .update(task.toFirestore());

            final syncedTask = task.copyWith(synced: true);
            _database.saveTask(TaskEntity.fromTask(syncedTask));
          }
          syncedCount++;
        } catch (e) {
          debugPrint('Error syncing task ${task.id}: $e');
        }
      }

      return syncedCount;
    } catch (e) {
      debugPrint('Error during sync: $e');
      return 0;
    }
  }

  /// Refresh tasks from Firestore (pull latest changes)
  Future<List<Task>> refreshTasks(String userId) async {
    if (await _connectivity.isOffline) {
      final localTasks = _database.getUserTasks(userId);
      return localTasks.map((entity) => entity.toTask()).toList();
    }

    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

      // Update local database
      for (final task in tasks) {
        _database.saveTask(TaskEntity.fromTask(task));
      }

      return _mergeWithUnsynced(tasks, userId);
    } catch (e) {
      debugPrint('Error refreshing tasks: $e');
      // Fallback to local
      final localTasks = _database.getUserTasks(userId);
      return localTasks.map((entity) => entity.toTask()).toList();
    }
  }

  // ==================== Local Operations ====================

  /// Get tasks from local database only
  List<Task> getLocalTasks(String userId) {
    final localTasks = _database.getUserTasks(userId);
    return localTasks.map((entity) => entity.toTask()).toList();
  }

  /// Get unsynced tasks count
  int getUnsyncedCount(String userId) {
    return _database.getUnsyncedTasks(userId).length;
  }

  /// Merges remote tasks with unsynced local-only tasks so offline work stays visible.
  List<Task> _mergeWithUnsynced(List<Task> remoteTasks, String userId) {
    final remoteIds = remoteTasks.map((t) => t.id).toSet();
    final pendingLocal = _database
        .getUnsyncedTasks(userId)
        .map((e) => e.toTask())
        .where((t) => !remoteIds.contains(t.id))
        .toList();

    final merged = [...remoteTasks, ...pendingLocal];
    merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }

  static String _localTaskId(String id) {
    if (id.isEmpty || id.startsWith('local_')) {
      return 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
    return id;
  }
}
