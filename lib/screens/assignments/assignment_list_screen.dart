import 'package:flutter/material.dart';
import 'package:p_learn_app/models/assignment_model.dart';
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/services/notification_service.dart';
import 'package:p_learn_app/services/tasks_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:p_learn_app/services/background_service.dart';

import 'widgets/add_assignment_dialog.dart';
import 'widgets/assignment_empty_view.dart';
import 'widgets/assignment_error_view.dart';
import 'widgets/assignment_list_item.dart';
import 'widgets/edit_assignment_dialog.dart';

class AssignmentListScreen extends StatefulWidget {
  final Course course;

  const AssignmentListScreen({super.key, required this.course});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  late Future<List<Assignment>> _assignmentsFuture;
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = _loadAssignments();
  }

  Future<List<Assignment>> _loadAssignments() {
    return _taskService.getAllAssignments(widget.course.id.toString());
  }

  void _triggerManualCheck() {
    Workmanager().registerOneOffTask(
      "manualAssignmentCheck-${DateTime.now().millisecondsSinceEpoch}",
      assignmentCheckTask,
      inputData: <String, dynamic>{
        'isManual': true,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang chạy kiểm tra bài tập trong nền...'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addAssignment(
    String title,
    String description,
    DateTime deadline,
  ) async {
    try {
      final newAssignment = await _taskService.createAssignment(
        subjectId: widget.course.id.toString(),
        title: title,
        description: description,
        deadline: deadline,
      );

      if (!mounted) return;

      // Add to local list and schedule notification
      _assignmentsFuture = _assignmentsFuture.then((assignments) {
        assignments.add(newAssignment);
        return assignments;
      });

      _notificationService.scheduleInitialAssignmentNotification(newAssignment);

      setState(() {});

      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm bài tập thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: Không thể thêm bài tập.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editAssignment(
    Assignment assignment,
    String newTitle,
    String newDesc,
    DateTime newDeadline,
  ) async {
    final ok = await _taskService.updateAssignment(
      taskId: assignment.id.toString(),
      title: newTitle,
      description: newDesc,
      deadline: newDeadline,
      completed: assignment.completed, // Giữ nguyên trạng thái hoàn thành
    );

    if (!mounted) return;

    if (ok) {
      _assignmentsFuture = _loadAssignments();
      setState(() {});

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật bài tập thành công')),
      );
    }
  }

  Future<void> _updateAssignmentStatus(Assignment assignment, bool newStatus) async {
    // 1. Optimistic UI update
    setState(() {
      _assignmentsFuture = _assignmentsFuture.then((assignments) {
        final index = assignments.indexWhere((a) => a.id == assignment.id);
        if (index != -1) {
          assignments[index] = Assignment(
            id: assignment.id,
            title: assignment.title,
            description: assignment.description,
            dueDate: assignment.dueDate,
            completed: newStatus,
            subjectId: assignment.subjectId,
          );
        }
        return assignments;
      });
    });

    try {
      // 2. Send request to server
      final ok = await _taskService.updateAssignment(
        taskId: assignment.id.toString(),
        title: assignment.title,
        description: assignment.description,
        deadline: assignment.dueDate,
        completed: newStatus,
      );

      if (!mounted) return;

      if (ok) {
        // 3. Handle notifications and show success message
        if (newStatus) {
          _notificationService.cancelInitialAssignmentNotification(assignment);
        } else {
          _notificationService.scheduleInitialAssignmentNotification(assignment);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Đã hoàn thành bài tập' : 'Đã bỏ hoàn thành bài tập',
            ),
          ),
        );
      } else {
        // 4. Revert on failure
        throw Exception("Failed to update status on server");
      }
    } catch (e) {
      if (!mounted) return;
      // 4. Revert on failure and show error
      setState(() {
         _assignmentsFuture = _loadAssignments(); // Reload from server to be safe
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _deleteAssignment(Assignment assignment) async {
    final ok = await _taskService.deleteAssignment(assignment.id.toString());

    if (!mounted) return;

    if (ok) {
      _notificationService.cancelInitialAssignmentNotification(assignment);
      _assignmentsFuture = _loadAssignments();
      setState(() {});

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bài tập thành công')),
      );
    }
  }

  void _showAssignmentOptions(Assignment assignment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _showEditAssignmentDialog(assignment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(assignment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAssignmentDialog(
        onAddAssignment: (title, description, deadline) {
          _addAssignment(title, description, deadline);
        },
      ),
    );
  }

  void _showEditAssignmentDialog(Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => EditAssignmentDialog(
        assignment: assignment,
        onEditAssignment: (newTitle, newDesc, newDeadline) {
          _editAssignment(assignment, newTitle, newDesc, newDeadline);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn muốn xóa bài tập "${assignment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _deleteAssignment(assignment),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _triggerManualCheck,
            tooltip: 'Kiểm tra bài tập',
          ),
        ],
      ),
      body: FutureBuilder<List<Assignment>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          if (snapshot.hasError && snapshot.connectionState != ConnectionState.waiting) {
            return AssignmentErrorView(error: snapshot.error.toString());
          }
          
          final assignments = snapshot.data ?? [];

          if (assignments.isEmpty) {
            return const AssignmentEmptyView();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return AssignmentListItem(
                assignment: assignment,
                onLongPress: () => _showAssignmentOptions(assignment),
                onStatusChanged: (completed) {
                  if (completed != null) {
                    _updateAssignmentStatus(assignment, completed);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssignmentDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
