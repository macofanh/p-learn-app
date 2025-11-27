import 'package:flutter/material.dart';

class AddAssignmentDialog extends StatefulWidget {
  final Function(String title, String description, DateTime deadline) onAddAssignment;

  const AddAssignmentDialog({
    super.key,
    required this.onAddAssignment,
  });

  @override
  State<AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<AddAssignmentDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _deadline;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Thêm bài tập mới"),
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
                initialDate: DateTime.now(),
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
            if (_deadline == null) return;

            widget.onAddAssignment(
              _titleController.text.trim(),
              _descController.text.trim(),
              _deadline!,
            );
          },
          child: const Text("Thêm"),
        ),
      ],
    );
  }
}
