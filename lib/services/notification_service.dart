import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:p_learn_app/models/schedule_model.dart';
import 'package:p_learn_app/models/assignment_model.dart';
import 'package:intl/intl.dart';


class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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

    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleNotification(ScheduleItem item) async {
    try {
      final timeParts = item.time.split(' - ')[0].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final classTime = DateTime(item.date.year, item.date.month, item.date.day, hour, minute);

      final notificationTime = classTime.subtract(const Duration(minutes: 30));

      if (notificationTime.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          item.id.hashCode,
          'Lịch học sắp tới',
          'Môn: ${item.subject} lúc ${item.time} tại ${item.room}',
          tz.TZDateTime.from(notificationTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              channelDescription: 'channel_description',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    } catch (e) {
    }
  }

  // Schedules the initial 1-minute notification
  Future<void> scheduleInitialAssignmentNotification(Assignment assignment) async {
    if (assignment.completed || assignment.dueDate.isBefore(DateTime.now())) {
      return;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      assignment.id + 1000000, // Use a unique ID for the initial notification
      'Bài tập mới',
      'Bạn có bài tập "${assignment.title}" vừa được tạo.',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'assignment_channel_id',
          'assignment_channel_name',
          channelDescription: 'Channel for assignment notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Shows a reminder notification, to be called from the background task
  Future<void> showAssignmentReminderNotification(Assignment assignment) async {
    await flutterLocalNotificationsPlugin.show(
      assignment.id, // Use the base assignment ID
      'Đừng quên bài tập',
      'Bài tập "${assignment.title}" sắp hết hạn vào ngày ${DateFormat('dd/MM/yyyy').format(assignment.dueDate)}.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'assignment_channel_id',
          'assignment_channel_name',
          channelDescription: 'Channel for assignment notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }


  Future<void> cancelInitialAssignmentNotification(Assignment assignment) async {
    await flutterLocalNotificationsPlugin.cancel(assignment.id + 1000000);
  }

  Future<void> scheduleAllNotifications(List<ScheduleItem> schedule) async {
    for (var item in schedule) {
      await scheduleNotification(item);
    }
  }

    Future<void> showDebugNotification({required String title, required String body}) async {

      try {

        const NotificationDetails platformDetails = NotificationDetails(

          android: AndroidNotificationDetails(

            'debug_channel',

            'Debug Channel',

            channelDescription: 'For debugging notifications',

            importance: Importance.max,

            priority: Priority.high,

          ),

          iOS: DarwinNotificationDetails(),

        );

  

        await flutterLocalNotificationsPlugin.show(

          998, // Unique ID for debug notifications

          title,

          body,

          platformDetails,

        );

      } catch (e) {

        //

      }

    }

  

    Future<void> showNowTestNotification() async {

  

      try {

        const NotificationDetails platformDetails = NotificationDetails(

          android: AndroidNotificationDetails(

            'channel_id',

            'channel_name',

            channelDescription: 'channel_description',

            importance: Importance.max,

            priority: Priority.high,

            ticker: 'ticker',

          ),

          iOS: DarwinNotificationDetails(

            presentAlert: true,

            presentBadge: true,

            presentSound: true,

          ),

        );

  

        await flutterLocalNotificationsPlugin.show(

          999,

          'Thông báo Test 🚨', 

          'Nếu bạn thấy thông báo này, nghĩa là nó hoạt động!', 

          platformDetails,

          payload: 'test_payload',

        );

      } catch (e) {

        //

      }

    }

  }

  