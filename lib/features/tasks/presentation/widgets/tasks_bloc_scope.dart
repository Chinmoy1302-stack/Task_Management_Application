import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utill/toasts.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    final taskRepository = TaskRepository(database: objectBox);
    _taskBloc = TaskBloc(
      taskRepository: taskRepository,
      syncService: SyncService(taskRepository: taskRepository),
    );
    _loadTasksIfSignedIn();
    _authWorker = ever(
      Get.find<AuthController>().firebaseUser,
      (_) => _loadTasksIfSignedIn(),
    );
    _initConnectivityMonitoring();
  }

  Future<void> _initConnectivityMonitoring() async {
    _wasOffline = await _connectivityService.isOffline;

    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((results) {
      final isOffline = _connectivityService.isOfflineFromResults(results);

      if (_wasOffline && !isOffline) {
        _syncTasksIfSignedIn(showToast: true);
      }

      _wasOffline = isOffline;
    });
  }

  void _syncTasksIfSignedIn({bool showToast = false}) {
    final userId = Get.find<AuthController>().firebaseUser.value?.uid ?? '';
    if (userId.isEmpty) return;

    _taskBloc.add(SyncTasksEvent(userId));

    if (showToast) {
      AppToast.showSuccess('Back online — syncing tasks');
    }
  }

  void _loadTasksIfSignedIn() {
    final userId = Get.find<AuthController>().firebaseUser.value?.uid ?? '';
    if (userId.isNotEmpty) {
      _taskBloc.add(LoadTasksEvent(userId: userId));
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _authWorker?.dispose();
    _taskBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _taskBloc, child: widget.child);
  }
}
