import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddAssignmentDialog extends StatefulWidget {
  const AddAssignmentDialog({
    super.key,
    required this.onAddAssignment,
  });

  final Future<void> Function(String title, DateTime dueDate) onAddAssignment;

  @override
  State<AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<AddAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _selectedDueDate;
  bool _isLoading = false;

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
        await widget.onAddAssignment(
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
    } else if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hạn nộp')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm bài tập mới'),
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
              : const Text('Thêm', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}