import 'package:flutter/material.dart';
import 'package:p_learn_app/services/group_service.dart';

class CreateGroupDialog extends StatefulWidget {
  final VoidCallback? onSuccess; // Thêm callback này

  const CreateGroupDialog({super.key, this.onSuccess});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleCreateGroup() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await GroupService().createGroup(
        _nameController.text,
        _descController.text,
      );

      if (mounted) {
        Navigator.pop(context); // Đóng dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tạo nhóm thành công!")),
        );
        // Gọi callback để màn hình danh sách load lại dữ liệu
        widget.onSuccess?.call(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Lỗi: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Tạo nhóm học tập"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Tên nhóm"),
            enabled: !_isLoading,
          ),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "Mô tả nhóm"),
            enabled: !_isLoading,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text("Hủy"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _isLoading ? null : _handleCreateGroup,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text("Tạo nhóm", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}