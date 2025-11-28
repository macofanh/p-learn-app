import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'package:p_learn_app/services/course_service.dart';
import 'package:p_learn_app/services/tasks_service.dart';
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/models/assignment_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

const assignmentCheckTask = "assignmentCheckTask";

// Helper function to show notifications within the background task
Future<void> _showBackgroundNotification({
  required FlutterLocalNotificationsPlugin plugin,
  required int id,
  required String title,
  required String body,
  required String channelId,
  required String channelName,
  required String channelDescription,
}) async {
  final NotificationDetails platformDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  await plugin.show(
    id,
    title,
    body,
    platformDetails,
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize flutter_local_notifications for the background isolate
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    tz.initializeTimeZones(); // Initialize timezones for zonedSchedule
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);


    if (task == assignmentCheckTask) {
      try {
        await _showBackgroundNotification(
          plugin: flutterLocalNotificationsPlugin,
          id: 998, // Unique ID for debug notifications
          title: 'Background Task',
          body: 'Running assignment check...',
          channelId: 'debug_channel',
          channelName: 'Debug Channel',
          channelDescription: 'For debugging notifications',
        );

        final CourseService courseService = CourseService();
        final TaskService taskService = TaskService();

        final List<Course> courses = await courseService.fetchCourses();
        for (final course in courses) {
          final List<Assignment> assignments = await taskService.getAllAssignments(course.id.toString());
          for (final assignment in assignments) {
            if (!assignment.completed && assignment.dueDate.isAfter(DateTime.now())) {
              await _showBackgroundNotification(
                plugin: flutterLocalNotificationsPlugin,
                id: assignment.id, // Use assignment ID for unique reminder
                title: 'Đừng quên bài tập',
                body: 'Môn ${course.fullName}: Bài tập "${assignment.title}" sắp hết hạn vào ngày ${DateFormat('dd/MM/yyyy').format(assignment.dueDate)}.',
                channelId: 'assignment_channel_id',
                channelName: 'assignment_channel_name',
                channelDescription: 'Channel for assignment notifications',
              );
            }
          }
        }
      } catch (e, s) {
        await _showBackgroundNotification(
          plugin: flutterLocalNotificationsPlugin,
          id: 998, // Use the same ID for debug notifications
          title: 'Background Task Error',
          body: 'Error: ${e.toString()}\nStack: ${s.toString()}',
          channelId: 'debug_channel',
          channelName: 'Debug Channel',
          channelDescription: 'For debugging notifications',
        );
        return Future.error(e);
      }
    }
    return Future.value(true);
  });
}
