import 'package:equatable/equatable.dart';
import '../../data/models/task.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {
  final bool isRefreshing;
  final List<Task> tasks;

  const TaskLoading({
    this.isRefreshing = false,
    this.tasks = const [],
  });

  @override
  List<Object?> get props => [isRefreshing, tasks];
}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final bool isSyncing;
  final int unsyncedCount;

  const TaskLoaded({
    required this.tasks,
    this.isSyncing = false,
    this.unsyncedCount = 0,
  });

  @override
  List<Object?> get props => [tasks, isSyncing, unsyncedCount];

  TaskLoaded copyWith({
    List<Task>? tasks,
    bool? isSyncing,
    int? unsyncedCount,
  }) {
    return TaskLoaded(
      tasks: tasks ?? this.tasks,
      isSyncing: isSyncing ?? this.isSyncing,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
    );
  }
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskOperationSuccess extends TaskState {
  final String message;
  final List<Task> tasks;

  const TaskOperationSuccess({
    required this.message,
    required this.tasks,
  });

  @override
  List<Object?> get props => [message, tasks];
}
