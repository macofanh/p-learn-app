import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p_learn_app/models/assignment_model.dart';

class EditAssignmentDialog extends StatefulWidget {
  const EditAssignmentDialog({
    super.key,
    required this.assignment,
    required this.onEditAssignment,
  });

  final Assignment assignment;
  final Future<void> Function(
    Assignment assignment,
    String newTitle,
    DateTime newDueDate,
  ) onEditAssignment;

  @override
  State<EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<EditAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment.title);
    _selectedDueDate = widget.assignment.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedDueDate != null) {
      setState(() => _isLoading = true);
      
      try {
        await widget.onEditAssignment(
          widget.assignment,
          _titleController.text,
          _selectedDueDate!,
        );
        // Dialog sẽ được đóng từ parent screen
      } catch (e) {
        // Nếu có lỗi, reset loading state
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa bài tập'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề bài tập',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _isLoading ? null : _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Hạn nộp',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDueDate == null
                      ? 'Chọn ngày'
                      : DateFormat('dd/MM/yyyy').format(_selectedDueDate!),
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}