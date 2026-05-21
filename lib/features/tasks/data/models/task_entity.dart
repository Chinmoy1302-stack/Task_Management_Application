import 'package:objectbox/objectbox.dart';
import 'task.dart';

@Entity()
class TaskEntity {
  @Id()
  int id;

  @Unique()
  String firestoreId;

  String title;
  String description;
  String status; // 'todo', 'in_progress', 'completed'
  int createdAt;
  int updatedAt;
  String userId;
  bool synced;

  TaskEntity({
    this.id = 0,
    required this.firestoreId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.synced,
  });

  // Convert from Task model to TaskEntity
  factory TaskEntity.fromTask(Task task) {
    return TaskEntity(
      firestoreId: task.id,
      title: task.title,
      description: task.description,
      status: task.status.toValue(),
      createdAt: task.createdAt.millisecondsSinceEpoch,
      updatedAt: task.updatedAt.millisecondsSinceEpoch,
      userId: task.userId,
      synced: task.synced,
    );
  }

  // Convert from TaskEntity to Task model
  Task toTask() {
    return Task(
      id: firestoreId,
      title: title,
      description: description,
      status: TaskStatus.fromValue(status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      userId: userId,
      synced: synced,
    );
  }

  TaskEntity copyWith({
    int? id,
    String? firestoreId,
    String? title,
    String? description,
    String? status,
    int? createdAt,
    int? updatedAt,
    String? userId,
    bool? synced,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      synced: synced ?? this.synced,
    );
  }
}
