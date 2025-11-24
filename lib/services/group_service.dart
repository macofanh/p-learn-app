import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/endpoints.dart';

class GroupService {

  /// Tạo nhóm
  Future<Map<String, dynamic>> createGroup(String name, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      final response = await http.post(
        Uri.parse(Endpoints.createGroup),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Tham gia nhóm (chỉ cần ID nhóm)
  Future<Map<String, dynamic>> joinGroup(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      final response = await http.post(
        Uri.parse(Endpoints.joinGroup(groupId)),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
