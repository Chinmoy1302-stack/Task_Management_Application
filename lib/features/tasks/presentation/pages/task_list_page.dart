import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:flutter_offline/flutter_offline.dart';
import '../../data/models/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utill/toasts.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  String get _userId =>
      Get.find<AuthController>().firebaseUser.value?.uid ?? '';

  void _reloadTasks(BuildContext context) {
    final userId = _userId;
    if (userId.isNotEmpty) {
      context.read<TaskBloc>().add(LoadTasksEvent(userId: userId));
    }
  }

  Future<void> _navigateTo(BuildContext context, String path) async {
    await context.push(path);
    if (mounted) {
      _reloadTasks(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBuilder(
        connectivityBuilder:
            (
              BuildContext context,
              List<ConnectivityResult> connectivity,
              Widget child,
            ) {
              final bool isOffline = connectivity.contains(
                ConnectivityResult.none,
              );

              return Scaffold(
                backgroundColor: AppColors.background,
                body: Stack(
                  children: [
                    SafeArea(
                      child: Column(
                        children: [
                          _buildHeader(context, isOffline),
                          Expanded(
                            child: BlocBuilder<TaskBloc, TaskState>(
                              builder: (context, state) {
                                if (state is TaskLoading) {
                                  return _buildLoading(context, state.tasks);
                                } else if (state is TaskLoaded) {
                                  return _buildTaskList(context, state, _userId);
                                } else if (state is TaskError) {
                                  return _buildError(state.message);
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOffline)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: AppColors.warning,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                color: AppColors.onWarning,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'You are offline',
                                style: TextStyle(
                                  color: AppColors.onWarning,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => _navigateTo(context, '/tasks/create'),
                  child: const Icon(Icons.add),
                ),
              );
            },
        child: const SizedBox(),
      );
  }

  Widget _buildHeader(BuildContext context, bool isOffline) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Tasks',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TaskLoaded && state.unsyncedCount > 0) {
                return IconButton(
                  icon: Icon(Icons.sync, color: AppColors.textPrimary),
                  onPressed: _userId.isEmpty
                      ? null
                      : () {
                          context
                              .read<TaskBloc>()
                              .add(SyncTasksEvent(_userId));
                        },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return _buildTaskList(context, TaskLoaded(tasks: tasks), '');
  }

  Widget _buildTaskList(
    BuildContext context,
    TaskLoaded state,
    String userId,
  ) {
    final todoTasks = state.tasks
        .where((t) => t.status == TaskStatus.todo)
        .toList();
    final inProgressTasks = state.tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .toList();
    final completedTasks = state.tasks
        .where((t) => t.status == TaskStatus.completed)
        .toList();
    if (state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TaskBloc>().add(
          LoadTasksEvent(userId: userId, forceRefresh: true),
        );
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          if (todoTasks.isNotEmpty) ...[
            _buildSectionHeader('To Do'),
            ...todoTasks.map(
              (task) => _buildTaskCard(context, task, userId),
            ),
            const SizedBox(height: 24),
          ],
          if (inProgressTasks.isNotEmpty) ...[
            _buildSectionHeader('In Progress'),
            ...inProgressTasks.map(
              (task) => _buildTaskCard(context, task, userId),
            ),
            const SizedBox(height: 24),
          ],
          if (completedTasks.isNotEmpty) ...[
            _buildSectionHeader('Completed'),
            ...completedTasks.map(
              (task) => _buildTaskCard(context, task, userId),
            ),
            const SizedBox(height: 24),
          ],
          if (state.unsyncedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${state.unsyncedCount} tasks not synced',
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    String userId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusDropdown(context, task, userId),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.primary, size: 20),
                onPressed: () => _navigateTo(context, '/tasks/edit/${task.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                onPressed: () {
                  _showDeleteDialog(context, task.id, _userId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(
    BuildContext context,
    Task task,
    String userId,
  ) {
    return DropdownButton<TaskStatus>(
      value: task.status,
      dropdownColor: AppColors.surface,
      iconEnabledColor: AppColors.textPrimary,
      style: TextStyle(color: AppColors.textPrimary),
      underline: Container(height: 0),
      items: TaskStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(
            status.displayName,
            style: TextStyle(color: AppColors.textPrimary),
          ),
        );
      }).toList(),
      onChanged: (status) {
        if (status != null) {
          context.read<TaskBloc>().add(
            UpdateTaskStatusEvent(taskId: task.id, status: status),
          );
          AppToast.showSuccess('Task status updated');
        }
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String taskId, String userId) {
    final taskBloc = context.read<TaskBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              taskBloc.add(DeleteTaskEvent(taskId));
              AppToast.showSuccess('Task deleted');
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
