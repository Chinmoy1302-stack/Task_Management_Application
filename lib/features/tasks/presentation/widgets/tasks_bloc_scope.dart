import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../main.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/task_repository.dart';
import '../../services/sync_service.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';

/// Provides a single [TaskBloc] for the tasks branch and reloads when auth is ready.
class TasksBlocScope extends StatefulWidget {
  final Widget child;

  const TasksBlocScope({super.key, required this.child});

  @override
  State<TasksBlocScope> createState() => _TasksBlocScopeState();
}

class _TasksBlocScopeState extends State<TasksBlocScope> {
  late final TaskBloc _taskBloc;
  Worker? _authWorker;

  @override
  void initState() {
    super.initState();
    _taskBloc = TaskBloc(
      taskRepository: TaskRepository(database: objectBox),
      syncService: SyncService(
        taskRepository: TaskRepository(database: objectBox),
      ),
    );
    _loadTasksIfSignedIn();
    _authWorker = ever(
      Get.find<AuthController>().firebaseUser,
      (_) => _loadTasksIfSignedIn(),
    );
  }

  void _loadTasksIfSignedIn() {
    final userId = Get.find<AuthController>().firebaseUser.value?.uid ?? '';
    if (userId.isNotEmpty) {
      _taskBloc.add(LoadTasksEvent(userId: userId));
    }
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    _taskBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _taskBloc, child: widget.child);
  }
}
