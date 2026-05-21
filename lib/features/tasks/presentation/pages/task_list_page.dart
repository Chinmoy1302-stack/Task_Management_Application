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
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  String get _userId =>
      Get.find<AuthController>().firebaseUser.value?.uid ?? '';

  Future<void> _navigateTo(BuildContext context, String path) async {
    final bloc = context.read<TaskBloc>();
    final userId = _userId;
    await context.push(path);
    if (!mounted || userId.isEmpty) return;
    bloc.add(LoadTasksEvent(userId: userId));
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBuilder(
      connectivityBuilder: (
        BuildContext context,
        List<ConnectivityResult> connectivity,
        Widget child,
      ) {
        final bool isOffline =
            connectivity.isEmpty ||
            connectivity.every(
              (result) => result == ConnectivityResult.none,
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
              if (isOffline) _buildOfflineBanner(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateTo(context, '/tasks/create'),
            icon: const Icon(Icons.add),
            label: const Text('New task'),
          ),
        );
      },
      child: const SizedBox(),
    );
  }

  Widget _buildOfflineBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: AppColors.warning,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_off, color: AppColors.onWarning, size: 18),
                SizedBox(width: 8),
                Text(
                  'Offline — changes save locally',
                  style: TextStyle(
                    color: AppColors.onWarning,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isOffline) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.background,
          ],
        ),
      ),
      child: Row(
        children: [
          const AppLogo(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Tasks',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isOffline)
                  Text(
                    'Offline mode',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is! TaskLoaded) return const SizedBox();

              if (state.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }

              if (state.unsyncedCount > 0) {
                return IconButton(
                  tooltip: 'Sync ${state.unsyncedCount} pending tasks',
                  icon: Badge(
                    label: Text('${state.unsyncedCount}'),
                    child: Icon(Icons.sync, color: AppColors.primary),
                  ),
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
    final todoTasks =
        state.tasks.where((t) => t.status == TaskStatus.todo).toList();
    final inProgressTasks =
        state.tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final completedTasks =
        state.tasks.where((t) => t.status == TaskStatus.completed).toList();

    if (state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 80),
            const SizedBox(height: 20),
            Text(
              'No tasks yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap New task to get started',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final bloc = context.read<TaskBloc>();
        bloc.add(LoadTasksEvent(userId: userId, forceRefresh: true));
        await bloc.stream.firstWhere(
          (s) => s is TaskLoaded || s is TaskError,
        );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          if (state.unsyncedCount > 0) ...[
            _buildUnsyncedBanner(context, state),
            const SizedBox(height: 16),
          ],
          if (todoTasks.isNotEmpty) ...[
            _buildSectionHeader('To Do', todoTasks.length),
            ...todoTasks.map((task) => _buildTaskCard(context, task, userId)),
            const SizedBox(height: 20),
          ],
          if (inProgressTasks.isNotEmpty) ...[
            _buildSectionHeader('In Progress', inProgressTasks.length),
            ...inProgressTasks
                .map((task) => _buildTaskCard(context, task, userId)),
            const SizedBox(height: 20),
          ],
          if (completedTasks.isNotEmpty) ...[
            _buildSectionHeader('Completed', completedTasks.length),
            ...completedTasks
                .map((task) => _buildTaskCard(context, task, userId)),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildUnsyncedBanner(BuildContext context, TaskLoaded state) {
    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _userId.isEmpty
            ? null
            : () => context.read<TaskBloc>().add(SyncTasksEvent(_userId)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_upload_outlined, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${state.unsyncedCount} task(s) waiting to sync — tap to sync now',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.warning, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, String userId) {
    final isPending = !task.synced;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isPending)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: AppColors.warning,
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: () => _navigateTo(context, '/tasks/edit/${task.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () => _showDeleteDialog(context, task.id, _userId),
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
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
      underline: const SizedBox.shrink(),
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
