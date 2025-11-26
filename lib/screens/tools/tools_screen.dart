import 'package:flutter/material.dart';
import 'package:p_learn_app/screens/group/study_group_screen.dart';
import 'package:p_learn_app/screens/tools/chatbot_screen.dart';
import 'package:p_learn_app/screens/tools/gpa_calculator_screen.dart';
import 'package:p_learn_app/screens/tools/pomodoro_screen.dart';
import 'package:p_learn_app/screens/tools/tool_card.dart';

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
              ToolCard(
                icon: Icons.calculate_outlined,
                title: 'Tính điểm GPA',
                subtitle: 'Ước tính điểm trung bình học kỳ của bạn.',
                onTap: () => _navigateTo(context, const GpaCalculatorScreen()),
              ),
              const SizedBox(height: 16),
              ToolCard(
                icon: Icons.hourglass_bottom_outlined,
                title: 'Đồng hồ Pomodoro',
                subtitle: 'Quản lý thời gian học tập hiệu quả.',
                onTap: () => _navigateTo(context, const PomodoroScreen()),
              ),
              const SizedBox(height: 16),
              ToolCard(
                icon: Icons.group_outlined,
                title: 'Nhóm học tập',
                subtitle: 'Tạo hoặc tham gia nhóm học tập của bạn.',
                onTap: () => _navigateTo(context, const StudyGroupScreen()),
              ),
              const SizedBox(height: 16),
              ToolCard(
                icon: Icons.chat_bubble_outline,
                title: 'Chatbot hỗ trợ',
                subtitle: 'Trò chuyện với trợ lý ảo học tập.',
                onTap: () => _navigateTo(context, const ChatbotScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function để code gọn hơn
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}