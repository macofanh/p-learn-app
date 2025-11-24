import 'package:flutter/material.dart';
import 'package:p_learn_app/screens/tools/chatbot_screen.dart';
import 'package:p_learn_app/screens/tools/gpa_calculator_screen.dart';
import 'package:p_learn_app/screens/tools/pomodoro_screen.dart';
import 'package:p_learn_app/services/group_service.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Công cụ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolCard(
                context,
                icon: Icons.calculate_outlined,
                title: 'Tính điểm GPA',
                subtitle: 'Ước tính điểm trung bình học kỳ của bạn.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GpaCalculatorScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildToolCard(
                context,
                icon: Icons.hourglass_bottom_outlined,
                title: 'Đồng hồ Pomodoro',
                subtitle: 'Quản lý thời gian học tập hiệu quả.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PomodoroScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildToolCard(
                context,
                icon: Icons.group_outlined,
                title: 'Nhóm học tập',
                subtitle: 'Tạo hoặc tham gia nhóm học tập của bạn.',
                onTap: () {
                  _showGroupOptions(context);
                },
              ),
              const SizedBox(height: 16),

              _buildToolCard(
                context,
                icon: Icons.chat_bubble_outline,
                title: 'Chatbot hỗ trợ',
                subtitle: 'Trò chuyện với trợ lý ảo học tập.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatbotScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bc) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.red,
                ),
                title: const Text('Tạo nhóm mới'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateGroupDialog(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.group_add_outlined,
                  color: Colors.red,
                ),
                title: const Text('Tham gia nhóm'),
                onTap: () {
                  Navigator.pop(context);
                  _showJoinGroupDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Tạo nhóm học tập"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Tên nhóm"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Mô tả nhóm"),
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
              child: const Text("Tạo nhóm"),
              onPressed: () async {
                final res = await GroupService().createGroup(
                  nameController.text,
                  descController.text,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res["message"] ?? "Tạo nhóm thành công"),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showJoinGroupDialog(BuildContext context) {
    final groupIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Tham gia nhóm"),
          content: TextField(
            controller: groupIdController,
            decoration: const InputDecoration(labelText: "Nhập ID nhóm"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Tham gia"),
              onPressed: () async {
                final res = await GroupService().joinGroup(
                  groupIdController.text.trim(),
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res["message"] ?? "Đã tham gia nhóm")),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40.0, color: Colors.red),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                subtitle,
                style: TextStyle(fontSize: 15.0, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
