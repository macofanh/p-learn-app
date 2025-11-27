import 'package:flutter/material.dart';
import 'package:p_learn_app/models/assignment_model.dart';
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/services/tasks_service.dart';

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

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = _loadAssignments();
  }

  Future<List<Assignment>> _loadAssignments() {
    return _taskService.getAllTasks(widget.course.id.toString());
  }

  Future<void> _addAssignment(
    String title,
    String description,
    DateTime deadline,
  ) async {
    final success = await _taskService.createTask(
      subjectId: widget.course.id.toString(),
      title: title,
      description: description,
      deadline: deadline,
    );

    if (!mounted) return;

    if (success) {
      // ⭐ Update future trước
      _assignmentsFuture = _loadAssignments();

      // ⭐ Gọi setState rỗng để rebuild
      setState(() {});

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm bài tập thành công')),
      );
    }
  }

  Future<void> _editAssignment(
    Assignment assignment,
    String newTitle,
    String newDesc,
    DateTime newDeadline,
  ) async {
    final ok = await _taskService.updateTask(
      taskId: assignment.id.toString(),
      title: newTitle,
      description: newDesc,
      deadline: newDeadline,
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

  Future<void> _deleteAssignment(Assignment assignment) async {
    final ok = await _taskService.deleteTask(assignment.id.toString());

    if (!mounted) return;

    if (ok) {
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
      ),
      body: FutureBuilder<List<Assignment>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          if (snapshot.hasError) {
            return AssignmentErrorView(error: snapshot.error.toString());
          }

          final assignments = snapshot.data ?? [];

          if (assignments.isEmpty) {
            return const AssignmentEmptyView();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) => AssignmentListItem(
              assignment: assignments[index],
              onLongPress: () => _showAssignmentOptions(assignments[index]),
            ),
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
