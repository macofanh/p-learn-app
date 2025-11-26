import 'package:flutter/material.dart';
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/providers/course_provider.dart';
import 'package:p_learn_app/screens/assignments/assignment_list_screen.dart';
import 'package:p_learn_app/screens/courses/widgets/add_course_dialog.dart';
import 'package:p_learn_app/screens/courses/widgets/edit_course_dialog.dart';
import 'package:p_learn_app/screens/courses/widgets/course_list_item.dart';
import 'package:p_learn_app/services/course_service.dart';
import 'package:provider/provider.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final CourseService _courseService = CourseService();

  final List<IconData> _courseIcons = [
    Icons.phone_android,
    Icons.web,
    Icons.storage,
    Icons.memory,
    Icons.computer,
    Icons.code,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  Future<void> _addCourse(Map<String, dynamic> courseData) async {
    try {
      final success = await context.read<CourseProvider>().addCourse(courseData);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm môn học thành công')),
        );
      } else {
        throw Exception('Lỗi khi thêm môn học');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thêm thất bại: $e')),
      );
    }
  }

  Future<void> _editCourse(Course course, Map<String, dynamic> courseData) async {
    try {
      // Note: Edit/Delete are not in provider yet, using local service for now.
      // For a full provider pattern, these should be moved to the provider as well.
      final success = await _courseService.editCourse(course.id, courseData);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật môn học thành công')),
        );
        context.read<CourseProvider>().fetchCourses(); // Refresh list
      } else {
        throw Exception('Lỗi khi cập nhật môn học');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e')),
      );
    }
  }

  Future<void> _deleteCourse(Course course) async {
    try {
      final success = await _courseService.deleteCourse(course.id);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa môn học thành công')),
        );
        context.read<CourseProvider>().fetchCourses(); // Refresh list
      } else {
        throw Exception('Lỗi khi xóa môn học');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thất bại: $e')),
      );
    }
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCourseDialog(addCourse: _addCourse),
    );
  }

  void _showEditCourseDialog(Course course) {
    showDialog(
      context: context,
      builder: (context) => EditCourseDialog(
        course: course,
        editCourse: _editCourse,
      ),
    );
  }

  void _showDeleteConfirmDialog(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa môn học "${course.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteCourse(course);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCourseOptions(Course course) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _showEditCourseDialog(course);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(course);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Môn học',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<CourseProvider>().fetchCourses();
            },
          ),
        ],
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, child) {
          if (provider.state == CourseState.loading || provider.state == CourseState.initial) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          if (provider.state == CourseState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải dữ liệu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      provider.errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          final courses = provider.courses;
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có môn học nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút + để thêm môn học mới',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return _buildCourseList(courses);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCourseList(List<Course> courses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseListItem(
          course: course,
          icon: _courseIcons[index % _courseIcons.length],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssignmentListScreen(course: course),
              ),
            );
          },
          onLongPress: () => _showCourseOptions(course),
          onMorePressed: () => _showCourseOptions(course),
        );
      },
    );
  }
}