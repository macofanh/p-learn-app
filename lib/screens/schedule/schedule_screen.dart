
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/models/schedule_model.dart';
import 'package:p_learn_app/providers/course_provider.dart';
import 'package:p_learn_app/widgets/app_colors.dart';
import 'package:p_learn_app/screens/notification/notification_screen.dart';
import 'package:provider/provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  final Map<DateTime, GlobalKey> _dateKeys = {};

  List<ScheduleItem> _processCoursesIntoScheduleItems(List<Course> courses) {
    final List<ScheduleItem> items = [];
    final Map<int, int> apiToDartWeekday = {
      0: 7, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6,
    };

    for (final course in courses) {
      if (course.schedule.isEmpty) {
        continue;
      }
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
                // Handle time parsing errors
              }
            }
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      } catch (e) {
        // Handle date parsing errors
      }
    }
    return items;
  }

  Map<DateTime, List<ScheduleItem>> _groupScheduleByDate(
      List<ScheduleItem> schedule) {
    Map<DateTime, List<ScheduleItem>> grouped = {};
    for (var item in schedule) {
      DateTime date = DateTime(item.date.year, item.date.month, item.date.day);
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(item);
    }
    return grouped;
  }

  void _scrollToDate(DateTime date) {
    final key = _dateKeys[date];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch học', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, child) {
          if (provider.state == CourseState.loading || provider.state == CourseState.initial) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.state == CourseState.error) {
            return Center(child: Text('Lỗi: ${provider.errorMessage}'));
          }
          
          final scheduleItems = _processCoursesIntoScheduleItems(provider.courses);
          if (scheduleItems.isEmpty) {
            return const Center(child: Text('Không có lịch học.'));
          }

          final groupedSchedule = _groupScheduleByDate(scheduleItems);
          final sortedDates = groupedSchedule.keys.toList()..sort();

          _dateKeys.clear(); 
          for (var date in sortedDates) {
            _dateKeys.putIfAbsent(date, () => GlobalKey());
          }

          return Column(
            children: [
              _buildWeekView(groupedSchedule),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final items = groupedSchedule[date]!;
                    return Column(
                      key: _dateKeys[date], 
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0, top: 16.0),
                          child: Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'vi_VN').format(date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        ...items.map((item) => _buildScheduleCard(item, index)),
                        const SizedBox(height: 16.0),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeekView(Map<DateTime, List<ScheduleItem>> groupedSchedule) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final dateOnly = DateTime(day.year, day.month, day.day);
          final hasSchedule = groupedSchedule.keys.any((d) => d.isAtSameMomentAs(dateOnly));
          final isSelected = _selectedDate.day == day.day && _selectedDate.month == day.month && _selectedDate.year == day.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = day;
              });
              if (hasSchedule) {
                _scrollToDate(dateOnly);
              }
            },
            child: Column(
              children: [
                Text(
                  DateFormat('E', 'vi_VN').format(day).substring(0, 2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.red : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  DateFormat('d').format(day),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? Colors.red : Colors.black,
                  ),
                ),
                const SizedBox(height: 4.0),
                if (hasSchedule)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 6), 
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleItem item, int index) {
    final cardColor = AppColors.scheduleCardColors[index % AppColors.scheduleCardColors.length];
    final accentColor = AppColors.scheduleAccentColors[index % AppColors.scheduleAccentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border(left: BorderSide(color: accentColor, width: 5)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4.0),
                      Text(
                        item.room,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                        ),
                      ),
                    ],
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