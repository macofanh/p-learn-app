import 'package:flutter/material.dart';
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/models/schedule_model.dart';
import 'package:p_learn_app/providers/course_provider.dart';
import 'package:p_learn_app/screens/main_navigation/main_tab_screen.dart';
import 'package:p_learn_app/widgets/home_banners.dart';
import 'package:p_learn_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/date_header.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/schedule_card.dart';
import 'widgets/schedule_empty_view.dart';
import 'widgets/schedule_error_view.dart';
import 'widgets/schedule_loading_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);
    // Data is now loaded by the provider, which is fetched when the app starts or on refresh.
  }

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
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUsername ?? 'Không có mã SV';
    final uId = userId.substring(userId.length - 3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(userId: userId, uId: uId),
      body: Consumer<CourseProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchCourses(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                Center(child: DateHeader(date: DateTime.now())),
                const SizedBox(height: 24),
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildContent(provider),
                const HomeBanners(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Lịch học hôm nay',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
      ],
    );
  }

  Widget _buildContent(CourseProvider provider) {
    if (provider.state == CourseState.loading || provider.state == CourseState.initial) {
      return const ScheduleLoadingView();
    }

    if (provider.state == CourseState.error) {
      return ScheduleErrorView(
        errorMessage: 'Không thể tải lịch học. Vui lòng thử lại.',
        onRetry: () => provider.fetchCourses(),
      );
    }

    final allSchedules = _processCoursesIntoScheduleItems(provider.courses);
    final now = DateTime.now();
    final todaySchedules = allSchedules.where((item) {
      return item.date.year == now.year &&
          item.date.month == now.month &&
          item.date.day == now.day;
    }).toList();

    // Schedule notifications based on today's schedule
    NotificationService().scheduleAllNotifications(todaySchedules);

    if (todaySchedules.isEmpty) {
      return const ScheduleEmptyView();
    }

    const int itemsToShowLimit = 2;
    final itemsToShow = todaySchedules.take(itemsToShowLimit).toList();

    return Column(
      children: [
        ...itemsToShow.map((item) => ScheduleCard(item: item)).toList(),
        if (todaySchedules.length > itemsToShowLimit)
          Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to the full schedule screen
                    // This assumes MainTabScreen is accessible and can switch tabs.
                    // A more robust solution might use a shared BottomNavigationBar state.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainTabScreen(initialIndex: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Xem thêm',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}