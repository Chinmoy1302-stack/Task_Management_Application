import 'package:equatable/equatable.dart';
import '../../data/models/task.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasksEvent extends TaskEvent {
  final String userId;
  final bool forceRefresh;

  const LoadTasksEvent({
    required this.userId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [userId, forceRefresh];
}

class CreateTaskEvent extends TaskEvent {
  final Task task;

  const CreateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTaskEvent extends TaskEvent {
  final Task task;

  const UpdateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;

  const DeleteTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class UpdateTaskStatusEvent extends TaskEvent {
  final String taskId;
  final TaskStatus status;

  const UpdateTaskStatusEvent({
    required this.taskId,
    required this.status,
  });

  @override
  List<Object?> get props => [taskId, status];
}

class SyncTasksEvent extends TaskEvent {
  final String userId;

  const SyncTasksEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
