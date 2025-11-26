import 'package:flutter/material.dart';
import 'package:p_learn_app/services/group_service.dart';

class JoinGroupDialog extends StatefulWidget {
  final VoidCallback? onSuccess; // Thêm callback

  const JoinGroupDialog({super.key, this.onSuccess});

  @override
  State<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<JoinGroupDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleJoinGroup() async {
    if (_codeController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await GroupService().joinGroup(
        _codeController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã tham gia nhóm thành công!")),
        );
        // Reload danh sách
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
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Tham gia nhóm"),
      content: TextField(
        controller: _codeController,
        decoration: const InputDecoration(
          labelText: "Nhập Mã Nhóm (ví dụ: A1B2C3)",
          hintText: "Nhập mã 6 ký tự",
        ),
        textCapitalization: TextCapitalization.characters, // Tự động viết hoa
      ),
      actions: [
        TextButton(
          child: const Text("Hủy"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _isLoading ? null : _handleJoinGroup,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text("Tham gia", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}