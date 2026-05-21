import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../features/tasks/data/models/task_entity.dart';
import '../../../objectbox.g.dart'; // Generated file

class ObjectBoxService {
  late final Store store;
  late final Box<TaskEntity> taskBox;

  ObjectBoxService._create(this.store) {
    taskBox = Box<TaskEntity>(store);
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBoxService> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, 'objectbox'));
    return ObjectBoxService._create(store);
  }

  // ==================== Task Operations ====================

  /// Save or update a task in local database
  void saveTask(TaskEntity task) {
    // Check if task with same firestoreId already exists
    if (task.firestoreId.isNotEmpty) {
      final existing = getTask(task.firestoreId);
      if (existing != null && existing.id != task.id) {
        // Update the task to use the existing entity's ID
        final updatedTask = TaskEntity(
          id: existing.id,
          firestoreId: task.firestoreId,
          title: task.title,
          description: task.description,
          status: task.status,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
          userId: task.userId,
          synced: task.synced,
        );
        taskBox.put(updatedTask);
        return;
      }
    }
    taskBox.put(task);
  }

  /// Get a task by Firestore ID
  TaskEntity? getTask(String firestoreId) {
    final query = taskBox
        .query(TaskEntity_.firestoreId.equals(firestoreId))
        .build();
    final task = query.findFirst();
    query.close();
    return task;
  }

  /// Get all tasks for a user
  List<TaskEntity> getUserTasks(String userId) {
    final query = taskBox
        .query(TaskEntity_.userId.equals(userId))
        .order(TaskEntity_.updatedAt, flags: Order.descending)
        .build();
    final tasks = query.find();
    query.close();
    return tasks;
  }

  /// Get unsynced tasks
  List<TaskEntity> getUnsyncedTasks(String userId) {
    final query = taskBox
        .query(
          TaskEntity_.userId
              .equals(userId)
              .and(TaskEntity_.synced.equals(false)),
        )
        .build();
    final tasks = query.find();
    query.close();
    return tasks;
  }

  /// Delete a task by Firestore ID
  void deleteTask(String firestoreId) {
    final query = taskBox
        .query(TaskEntity_.firestoreId.equals(firestoreId))
        .build();
    final task = query.findFirst();
    query.close();

    if (task != null) {
      taskBox.remove(task.id);
    }
  }

  /// Clear all tasks for a user
  void clearUserTasks(String userId) {
    final query = taskBox.query(TaskEntity_.userId.equals(userId)).build();
    final tasks = query.find();
    query.close();

    for (final task in tasks) {
      taskBox.remove(task.id);
    }
  }
}
