import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/endpoints.dart';

class AuthService with ChangeNotifier {
  String? _username;
  String? _email;
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUsername => _username;
  String? get currentEmail => _email;

  Future<Map<String, dynamic>> login(String username, String password) async {
  try {
    final url = Uri.parse(Endpoints.login);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    print("RAW RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      final String accessToken = responseData['accessToken'];
      final String serverUsername = responseData['user']['username'];
      final String serverEmail = responseData['user']['email'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('username', serverUsername);
      await prefs.setString('email', serverEmail);

      _isLoggedIn = true;
      _username = serverUsername;
      _email = serverEmail;

      notifyListeners();
      return {'success': true, 'message': 'Đăng nhập thành công'};
    } else {
      return {
        'success': false,
        'message': 'Sai tài khoản hoặc mật khẩu'
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
  }
}

  Future<bool> register(String username, String email, String password) async {
    try {
      final url = Uri.parse(Endpoints.register);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String> resetPassword(String email, String newPassword) async {
    final url = Uri.parse(Endpoints.resetPassword);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },

        body: jsonEncode({'email': email, 'new_password': newPassword}),
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return responseBody.toString();
      } else if (response.statusCode == 422) {
        String errorMessage = 'Dữ liệu không hợp lệ';
        if (responseBody is Map && responseBody.containsKey('detail')) {
          errorMessage = responseBody['detail'];
        }
        throw Exception(errorMessage);
      } else {
        throw Exception('Lỗi máy chủ: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối. ${e.toString()}');
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('username');
    await prefs.remove('email');

    _isLoggedIn = false;
    _username = null;
    _email = null;

    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      _isLoggedIn = true;
      _username = prefs.getString('username');
      _email = prefs.getString('email');
    } else {
      _isLoggedIn = false;
    }
    notifyListeners();
  }
}
