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

class TaskEditPage extends StatefulWidget {
  final String taskId;

  const TaskEditPage({super.key, required this.taskId});

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskStatus _status = TaskStatus.todo;
  Task? _currentTask;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate() && _currentTask != null) {
      final updatedTask = _currentTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
        updatedAt: DateTime.now(),
      );

      context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
      AppToast.showSuccess('Task updated');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoaded) {
          _currentTask = state.tasks.firstWhere(
            (task) => task.id == widget.taskId,
            orElse: () => Task(
              id: widget.taskId,
              title: '',
              description: '',
              status: TaskStatus.todo,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              userId: Get.find<AuthController>().firebaseUser.value?.uid ?? '',
            ),
          );

          if (_titleController.text.isEmpty && _currentTask!.title.isNotEmpty) {
            _titleController.text = _currentTask!.title;
            _descriptionController.text = _currentTask!.description;
            _status = _currentTask!.status;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Edit Task',
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
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                      style: TextStyle(color: AppColors.textPrimary),
                      maxLines: 5,
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
                      onChanged: (value) {
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
                        onPressed: () => _submit(context),
                        child: const Text(
                          'Update Task',
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
      },
    );
  }
}
