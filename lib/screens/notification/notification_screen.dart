import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/models/schedule_model.dart';
import 'package:p_learn_app/providers/course_provider.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  
  List<ScheduleItem> _processCoursesIntoScheduleItems(List<Course> courses) {
    final List<ScheduleItem> items = [];
    final Map<int, int> apiToDartWeekday = {
      0: 7, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6,
    };

    for (final course in courses) {
      if (course.schedule.isEmpty) continue;
      try {
        DateTime courseStartDate = DateTime.parse(course.startDate);
        DateTime courseEndDate = DateTime.parse(course.endDate);
        DateTime currentDate = courseStartDate;

        while (currentDate.isBefore(courseEndDate) ||
            currentDate.isAtSameMomentAs(courseEndDate)) {
          for (final rule in course.schedule) {
            int? dartWeekday = apiToDartWeekday[rule.dayOfWeek];
            if (dartWeekday != null && currentDate.weekday == dartWeekday) {
              try {
                final startTime = rule.startTime.substring(0, 5);
                final endTime = rule.endTime.substring(0, 5);
                final timeString = '$startTime - $endTime';
                items.add(
                  ScheduleItem(
                    id: '${course.id}-${currentDate.toIso8601String()}',
                    subject: course.fullName,
                    room: rule.room,
                    date: currentDate,
                    time: timeString,
                  ),
                );
              } catch (e) {
                // Time parsing error
              }
            }
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      } catch (e) {
        // Date parsing error
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, child) {
          if (provider.state == CourseState.loading || provider.state == CourseState.initial) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.state == CourseState.error) {
            return Center(child: Text('Lỗi: ${provider.errorMessage}'));
          }
          
          final allScheduleItems = _processCoursesIntoScheduleItems(provider.courses);
          if (allScheduleItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final upcomingNotifications = allScheduleItems.where((item) {
            try {
              final timeParts = item.time.split(' - ')[0].split(':');
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              final classTime = DateTime(item.date.year, item.date.month, item.date.day, hour, minute);

              final difference = classTime.difference(now);
              return difference.isNegative == false && difference.inMinutes <= 30;
            } catch (e) {
              return false;
            }
          }).toList();

          if (upcomingNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có lịch học nào trong 30 phút tới',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: upcomingNotifications.length,
            itemBuilder: (context, index) {
              final item = upcomingNotifications[index];
              return _buildNotificationCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red[100],
              child: const Icon(Icons.notifications_active, color: Colors.red),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch học sắp tới',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Môn: ${item.subject} lúc ${item.time} tại ${item.room}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    DateFormat('dd MMMM yyyy', 'vi_VN').format(item.date),
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}