import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p_learn_app/models/assignment_model.dart';
import 'package:p_learn_app/api/endpoints.dart';

class TaskService {
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Người dùng chưa đăng nhập hoặc token đã hết hạn");
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Assignment>> getAllAssignments(String subjectId) async {
    final url = Uri.parse(Endpoints.getAllTasks(subjectId));
    final headers = await _getAuthHeaders();

    try {
      final response =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(utf8.decode(response.bodyBytes));

        return jsonList.map((e) => Assignment.fromJson(e)).toList();
      } else {
        throw Exception("Lỗi tải danh sách bài tập: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Không thể kết nối đến máy chủ: $e");
    }
  }

  Future<Assignment> createAssignment({
    required String subjectId,
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    final url = Uri.parse(Endpoints.createTask(subjectId));
    final headers = await _getAuthHeaders();

    final body = jsonEncode({
      "title": title,
      "description": description,
      "deadline": deadline.toIso8601String(),
      "completed": false,
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return Assignment.fromJson(json);
      } else {
        String message = "Lỗi tạo bài tập: ${response.statusCode}";

        try {
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          if (json["message"] != null) {
            message = json["message"];
          }
        } catch (_) {}

        throw Exception(message);
      }
    } catch (e) {
      throw Exception("Không thể tạo bài tập: $e");
    }
  }

  Future<bool> updateAssignment({
    required String taskId,
    String? title,
    String? description,
    DateTime? deadline,
    bool? completed,
  }) async {
    final url = Uri.parse(Endpoints.updateTask(taskId));
    final headers = await _getAuthHeaders();

    final body = jsonEncode({
      "title": title,
      "description": description,
      "deadline": deadline?.toIso8601String(),
      "completed": completed,
    });

    try {
      final response = await http
          .put(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Không thể cập nhật bài tập (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối khi cập nhật: $e");
    }
  }

  Future<bool> deleteAssignment(String taskId) async {
    final url = Uri.parse(Endpoints.deleteTask(taskId));
    final headers = await _getAuthHeaders();

    try {
      final response =
          await http.delete(url, headers: headers).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception("Không thể xóa bài tập: $e");
    }
  }
}
