import 'package:flutter/material.dart';
import 'package:p_learn_app/screens/auth/login_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:p_learn_app/screens/auth/reset_password_screen.dart';
import 'package:p_learn_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'widgets/profile_action_tile.dart';
import 'widgets/profile_editable_info_tile.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                authService.logout();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveDisplayName() {
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã cập nhật tên hiển thị')));
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final studentCode = authService.currentUsername ?? 'Không có mã';

    final username = authService.currentUsername;
    String generatedName;

    if (username != null && username.length >= 3) {
      final lastThree = username.substring(username.length - 3);
      generatedName = "PTITer $lastThree";
    } else {
      generatedName = "PtiterUser";
    }

    final displayName = _displayNameController.text.isEmpty
        ? generatedName
        : _displayNameController.text;

    final emailDisplay = authService.currentEmail ?? "Chưa có email";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 15,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(
              displayName: displayName,
              studentCode: studentCode,
            ),

            const SizedBox(height: 16),

            // Thông tin cá nhân
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ProfileInfoTile(
                    icon: Icons.badge_outlined,
                    title: 'Mã sinh viên',
                    subtitle: studentCode,
                  ),
                  const Divider(height: 1, indent: 72),
                  ProfileEditableInfoTile(
                    icon: Icons.person_outline,
                    title: 'Tên hiển thị',
                    subtitle: displayName,
                    isEditing: _isEditing,
                    controller: _displayNameController,
                    onPressed: () {
                      if (_isEditing) {
                        _saveDisplayName();
                      } else {
                        setState(() {
                          _isEditing = true;
                          _displayNameController.text = displayName;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cài đặt
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ProfileInfoTile(
                    icon: Icons.email_outlined,
                    title: 'Email lấy mật khẩu',
                    subtitle: emailDisplay,
                  ),
                  const Divider(height: 1, indent: 72),
                  ProfileActionTile(
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordScreen(),
                        ),
                      );
                    },
                  ),
                  // const Divider(height: 1, indent: 72),
                  // ProfileActionTile(
                  //   icon: Icons.help_outline,
                  //   title: 'Trợ giúp',
                  //   onTap: () {},
                  // ),
                  // const Divider(height: 1, indent: 72),
                  // ProfileActionTile(
                  //   icon: Icons.notifications_active_outlined,
                  //   title: 'Kiểm tra thông báo',
                  //   onTap: () async {
                  //     final notificationService = NotificationService();
                  //     await notificationService.requestPermissions();
                  //     await notificationService.flutterLocalNotificationsPlugin
                  //         .show(
                  //       0,
                  //       'Thông báo kiểm tra',
                  //       'Đây là một thông báo thử nghiệm từ P-Learn.',
                  //       const NotificationDetails(
                  //         android: AndroidNotificationDetails(
                  //           'test_channel_id',
                  //           'Test Channel',
                  //           channelDescription:
                  //               'Channel for test notifications',
                  //           importance: Importance.max,
                  //           priority: Priority.high,
                  //         ),
                  //         iOS: DarwinNotificationDetails(),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nút đăng xuất
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context, authService),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}