import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:p_learn_app/models/course_model.dart';
import 'package:p_learn_app/api/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseService {
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Người dùng chưa đăng nhập hoặc token đã hết hạn');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Course>> fetchCourses() async {
    final url = Uri.parse(Endpoints.getAllSubjects);
    final headers = await _getAuthHeaders();

    try {
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => Course.fromJson(item)).toList();
      } else {
        throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> addCourse(Map<String, dynamic> courseData) async {
    final url = Uri.parse(Endpoints.createSubject);
    final headers = await _getAuthHeaders();
    final body = jsonEncode(courseData);

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Failed to add course. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return false;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> editCourse(String courseId, Map<String, dynamic> courseData) async {
    final url = Uri.parse(Endpoints.updateSubject(courseId));
    final headers = await _getAuthHeaders();
    final body = jsonEncode(courseData);

    try {
      final response = await http.put(url, headers: headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    final url = Uri.parse(Endpoints.deleteSubject(courseId));
    final headers = await _getAuthHeaders();

    try {
      final response = await http.delete(url, headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}