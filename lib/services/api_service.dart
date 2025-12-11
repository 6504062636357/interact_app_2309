import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Signup failed');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/dashboard'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load dashboard');
    }
  }

}
