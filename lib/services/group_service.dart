import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p_learn_app/api/endpoints.dart';

class GroupService {
  
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // Key 'access_token' phải khớp với lúc bạn lưu khi đăng nhập
    final token = prefs.getString('access_token'); 

    if (token == null) {
      throw Exception('Người dùng chưa đăng nhập hoặc token đã hết hạn');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Lấy danh sách nhóm
  Future<List<dynamic>> fetchGroups() async {
    final url = Uri.parse(Endpoints.getAllGroups);
    final headers = await _getAuthHeaders();

    try {
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Lỗi tải danh sách nhóm: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  // 2. Tạo nhóm mới
  Future<bool> createGroup(String name, String description) async {
    final url = Uri.parse(Endpoints.createGroup);
    final headers = await _getAuthHeaders();
    final body = jsonEncode({
      "name": name,
      "description": description
    });

    try {
      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        // Cố gắng đọc thông báo lỗi từ server nếu có
        String errorMsg = 'Mã lỗi ${response.statusCode}';
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body['message'] != null) errorMsg = body['message'];
        } catch (_) {}
        
        throw Exception('Tạo nhóm thất bại: $errorMsg');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 3. Tham gia nhóm bằng Group Code
  Future<bool> joinGroup(String groupCode) async {
    final url = Uri.parse(Endpoints.joinGroup(groupCode));
    final headers = await _getAuthHeaders();

    try {
      final response = await http.post(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        String errorMsg = 'Mã lỗi ${response.statusCode}';
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body['message'] != null) errorMsg = body['message'];
        } catch (_) {}
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 4. Rời nhóm
  Future<bool> leaveGroup(String groupId) async {
    final url = Uri.parse(Endpoints.leaveGroup(groupId));
    final headers = await _getAuthHeaders();

    try {
      final response = await http.post(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 5. Xóa nhóm (Chỉ chủ nhóm)
  Future<bool> deleteGroup(String groupId) async {
    final url = Uri.parse(Endpoints.deleteGroup(groupId));
    final headers = await _getAuthHeaders();

    try {
      final response = await http.delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Không thể xóa nhóm (Lỗi ${response.statusCode})');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 6. Lấy chi tiết nhóm
  Future<Map<String, dynamic>?> getGroupDetails(String groupId) async {
    final url = Uri.parse(Endpoints.getGroupById(groupId));
    final headers = await _getAuthHeaders();

    try {
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return null;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}