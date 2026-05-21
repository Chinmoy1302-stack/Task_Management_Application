import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/models/task_entity.dart';
import '../../../../core/services/objectbox_service.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final ObjectBoxService _database;

  TaskRepository({
    FirebaseFirestore? firestore,
    required ObjectBoxService database,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database;

  // ==================== Firestore Operations ====================

  /// Create a new task in Firestore
  Future<Task> createTask(Task task) async {
    try {
      final docRef = await _firestore.collection('tasks').add(task.toFirestore());
      final createdTask = task.copyWith(id: docRef.id, synced: true);
      
      // Also save to local database
      _database.saveTask(TaskEntity.fromTask(createdTask));
      
      return createdTask;
    } catch (e) {
      debugPrint('Error creating task in Firestore: $e');
      final localTask = task.copyWith(
        id: _localTaskId(task.id),
        synced: false,
      );
      _database.saveTask(TaskEntity.fromTask(localTask));
      return localTask;
    }
  }

  /// Get all tasks for a user from Firestore
  Future<List<Task>> getTasks(String userId) async {
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
      
      return tasks;
    } catch (e) {
      debugPrint('Error fetching tasks from Firestore: $e');
      // Fallback to local database
      final localTasks = _database.getUserTasks(userId);
      return localTasks.map((entity) => entity.toTask()).toList();
    }
  }

  /// Update a task in Firestore
  Future<Task> updateTask(Task task) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore());
      
      final updatedTask = task.copyWith(synced: true);
      _database.saveTask(TaskEntity.fromTask(updatedTask));
      
      return updatedTask;
    } catch (e) {
      debugPrint('Error updating task in Firestore: $e');
      // Save locally with synced=false
      final localTask = task.copyWith(synced: false);
      _database.saveTask(TaskEntity.fromTask(localTask));
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
      
      return tasks;
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

  static String _localTaskId(String id) {
    if (id.isEmpty || id.startsWith('local_')) {
      return 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
    return id;
  }
}
