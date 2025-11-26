import 'package:flutter/material.dart';
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/services/course_service.dart';

enum CourseState { initial, loading, loaded, error }

class CourseProvider with ChangeNotifier {
  final CourseService _courseService = CourseService();

  List<Course> _courses = [];
  CourseState _state = CourseState.initial;
  String _errorMessage = '';

  List<Course> get courses => _courses;
  CourseState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> fetchCourses() async {
    _state = CourseState.loading;
    notifyListeners();
    try {
      _courses = await _courseService.fetchCourses();
      _state = CourseState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = CourseState.error;
    }
    notifyListeners();
  }

  Future<bool> addCourse(Map<String, dynamic> courseData) async {
    try {
      final success = await _courseService.addCourse(courseData);
      if (success) {
        await fetchCourses(); // Re-fetch the list after adding
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
