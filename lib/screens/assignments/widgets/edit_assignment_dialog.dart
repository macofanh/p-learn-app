import 'package:flutter/material.dart';
import 'package:p_learn_app/models/assignment_model.dart';

class EditAssignmentDialog extends StatefulWidget {
  final Assignment assignment;
  final Function(String title, String description, DateTime deadline) onEditAssignment;

  const EditAssignmentDialog({
    super.key,
    required this.assignment,
    required this.onEditAssignment,
  });

  @override
  State<EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<EditAssignmentDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment.title);
    _descController = TextEditingController(text: widget.assignment.description);
    _deadline = widget.assignment.dueDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Chỉnh sửa bài tập"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Tiêu đề"),
          ),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "Mô tả"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _deadline!,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );

              if (selected != null) {
                setState(() => _deadline = selected);
              }
            },
            child: Text(_deadline == null
                ? "Chọn hạn nộp"
                : "Hạn: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onEditAssignment(
              _titleController.text.trim(),
              _descController.text.trim(),
              _deadline!,
            );
          },
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}
