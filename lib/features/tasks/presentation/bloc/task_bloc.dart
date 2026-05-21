import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../services/sync_service.dart';
import '../../../../core/services/notification_service.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository;
  final SyncService _syncService;

  TaskBloc({
    required TaskRepository taskRepository,
    required SyncService syncService,
  }) : _taskRepository = taskRepository,
       _syncService = syncService,
       super(TaskInitial()) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<CreateTaskEvent>(_onCreateTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<UpdateTaskStatusEvent>(_onUpdateTaskStatus);
    on<SyncTasksEvent>(_onSyncTasks);
  }

  Future<void> _onLoadTasks(
    LoadTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final previousTasks = state is TaskLoaded
          ? (state as TaskLoaded).tasks
          : <Task>[];

      emit(TaskLoading(isRefreshing: event.forceRefresh, tasks: previousTasks));

      List<Task> tasks;
      if (event.forceRefresh) {
        tasks = await _taskRepository.refreshTasks(event.userId);
      } else {
        tasks = await _taskRepository.getTasks(event.userId);
      }

      final unsyncedCount = _taskRepository.getUnsyncedCount(event.userId);

      emit(TaskLoaded(tasks: tasks, unsyncedCount: unsyncedCount));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onCreateTask(
    CreateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final previousTasks = state is TaskLoaded
          ? (state as TaskLoaded).tasks
          : <Task>[];

      emit(TaskLoading(tasks: previousTasks));

      final createdTask = await _taskRepository.createTask(event.task);
      final updatedTasks = [createdTask, ...previousTasks];

      final unsyncedCount = _taskRepository.getUnsyncedCount(event.task.userId);

      emit(TaskLoaded(tasks: updatedTasks, unsyncedCount: unsyncedCount));

      NotificationService().showTaskCreatedNotification(event.task.title);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final previousTasks = state is TaskLoaded
          ? (state as TaskLoaded).tasks
          : <Task>[];

      emit(TaskLoading(tasks: previousTasks));

      final updatedTask = await _taskRepository.updateTask(event.task);
      final updatedTasks = previousTasks.map((task) {
        return task.id == updatedTask.id ? updatedTask : task;
      }).toList();

      final unsyncedCount = _taskRepository.getUnsyncedCount(event.task.userId);

      emit(TaskLoaded(tasks: updatedTasks, unsyncedCount: unsyncedCount));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final previousTasks = state is TaskLoaded
          ? (state as TaskLoaded).tasks
          : <Task>[];

      emit(TaskLoading(tasks: previousTasks));

      await _taskRepository.deleteTask(event.taskId);
      final updatedTasks = previousTasks
          .where((task) => task.id != event.taskId)
          .toList();

      emit(TaskLoaded(tasks: updatedTasks));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTaskStatus(
    UpdateTaskStatusEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final previousTasks = state is TaskLoaded
          ? (state as TaskLoaded).tasks
          : <Task>[];

      emit(TaskLoading(tasks: previousTasks));

      final taskToUpdate = previousTasks.firstWhere(
        (task) => task.id == event.taskId,
      );

      final updatedTask = taskToUpdate.copyWith(
        status: event.status,
        updatedAt: DateTime.now(),
      );

      final result = await _taskRepository.updateTask(updatedTask);
      final updatedTasks = previousTasks.map((task) {
        return task.id == result.id ? result : task;
      }).toList();

      final unsyncedCount = _taskRepository.getUnsyncedCount(
        taskToUpdate.userId,
      );

      emit(TaskLoaded(tasks: updatedTasks, unsyncedCount: unsyncedCount));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onSyncTasks(
    SyncTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final previousTasks = state is TaskLoaded
          ? (state as TaskLoaded).tasks
          : <Task>[];

      emit(
        TaskLoaded(
          tasks: previousTasks,
          isSyncing: true,
          unsyncedCount: _syncService.getUnsyncedCount(event.userId),
        ),
      );

      await _syncService.syncTasks(event.userId);
      final tasks = await _taskRepository.refreshTasks(event.userId);
      final unsyncedCount = _taskRepository.getUnsyncedCount(event.userId);

      emit(
        TaskLoaded(
          tasks: tasks,
          isSyncing: false,
          unsyncedCount: unsyncedCount,
        ),
      );
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }
}
