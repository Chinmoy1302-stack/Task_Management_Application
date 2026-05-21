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
    
    debugPrint('Creating task - saving to ObjectBox with ID: ${pendingTask.id}');
    _database.saveTask(TaskEntity.fromTask(pendingTask));
    
    // Verify save
    final saved = _database.getTask(pendingTask.id);
    debugPrint('Task saved to ObjectBox: ${saved != null} (ID: ${saved?.firestoreId})');

    if (await _connectivity.isOffline) {
      debugPrint('Offline: task saved locally (${pendingTask.id})');
      return pendingTask;
    }

    try {
      debugPrint('Online: attempting to sync task to Firestore');
      final docRef = await _firestore
          .collection('tasks')
          .add(task.toFirestore())
          .timeout(_firestoreTimeout);

      debugPrint('Task synced to Firestore with ID: ${docRef.id}');
      final syncedTask = task.copyWith(id: docRef.id, synced: true);
      
      // Delete the local pending version
      debugPrint('Deleting local pending task: ${pendingTask.id}');
      _database.deleteTask(pendingTask.id);
      
      // Save the synced version
      debugPrint('Saving synced task with Firestore ID: ${docRef.id}');
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
      return _dedupeTasks(
        _database.getUserTasks(userId).map((entity) => entity.toTask()).toList(),
      );
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
      return _dedupeTasks(
        _database.getUserTasks(userId).map((entity) => entity.toTask()).toList(),
      );
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
    } finally {
      _cleanupDuplicateLocalTasks(userId);
    }
  }

  /// Removes stale local-only rows that already exist on the remote side.
  void _cleanupDuplicateLocalTasks(String userId) {
    final syncedTasks = _database
        .getUserTasks(userId)
        .where((entity) => entity.synced)
        .map((entity) => entity.toTask())
        .toList();

    for (final entity in _database.getUnsyncedTasks(userId)) {
      final task = entity.toTask();
      if (_isDuplicateOfRemote(task, syncedTasks)) {
        _database.deleteTask(task.id);
      }
    }
  }

  /// Refresh tasks from Firestore (pull latest changes)
  Future<List<Task>> refreshTasks(String userId) async {
    if (await _connectivity.isOffline) {
      return _dedupeTasks(
        _database.getUserTasks(userId).map((entity) => entity.toTask()).toList(),
      );
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
      return _dedupeTasks(
        _database.getUserTasks(userId).map((entity) => entity.toTask()).toList(),
      );
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
        .where((t) => !_isDuplicateOfRemote(t, remoteTasks))
        .toList();

    return _dedupeTasks([...remoteTasks, ...pendingLocal]);
  }

  /// Prevents duplicate rows when local pending tasks were already synced remotely.
  bool _isDuplicateOfRemote(Task local, List<Task> remoteTasks) {
    return remoteTasks.any(
      (remote) =>
          remote.userId == local.userId &&
          remote.title == local.title &&
          remote.description == local.description &&
          remote.createdAt.millisecondsSinceEpoch ==
              local.createdAt.millisecondsSinceEpoch,
    );
  }

  List<Task> _dedupeTasks(List<Task> tasks) {
    final seenIds = <String>{};
    final deduped = <Task>[];

    for (final task in tasks) {
      if (seenIds.add(task.id)) {
        deduped.add(task);
      }
    }

    deduped.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return deduped;
  }

  static String _localTaskId(String id) {
    if (id.isEmpty || id.startsWith('local_')) {
      return 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
    return id;
  }
}
