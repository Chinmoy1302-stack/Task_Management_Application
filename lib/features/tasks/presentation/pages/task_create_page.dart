import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../data/models/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utill/toasts.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TaskCreatePage extends StatefulWidget {
  const TaskCreatePage({super.key});

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskStatus _status = TaskStatus.todo;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final userId = Get.find<AuthController>().firebaseUser.value?.uid ?? '';
    if (userId.isEmpty) {
      AppToast.showError('Please sign in to create tasks');
      return;
    }

    final task = Task(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
    );

    setState(() => _isSubmitting = true);

    final bloc = context.read<TaskBloc>();
    final countBefore = bloc.state is TaskLoaded
        ? (bloc.state as TaskLoaded).tasks.length
        : 0;

    try {
      final stateFuture = bloc.stream
          .where((s) => s is TaskLoaded || s is TaskError)
          .first
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => bloc.state,
          );

      bloc.add(CreateTaskEvent(task));
      final state = await stateFuture;

      if (!context.mounted) return;

      if (state is TaskError) {
        AppToast.showError('Failed to create task', description: state.message);
        return;
      }

      if (state is! TaskLoaded) {
        AppToast.showError('Failed to create task', description: 'Timed out');
        return;
      }

      if (state.tasks.length <= countBefore &&
          !state.tasks.any((t) => t.title == task.title)) {
        AppToast.showError('Failed to create task');
        return;
      }

      final isOfflineTask = state.tasks.any(
        (t) => t.title == task.title && !t.synced,
      );
      AppToast.showSuccess(
        isOfflineTask ? 'Task saved offline' : 'Task created',
      );
      context.pop();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: _isSubmitting ? null : () => context.pop(),
        ),
        title: const Text(
          'Create Task',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskStatus>(
                  value: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  dropdownColor: AppColors.surface,
                  style: TextStyle(color: AppColors.textPrimary),
                  items: TaskStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _status = value ?? TaskStatus.todo;
                          });
                        },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submit(context),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Create Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
