import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  // ******************************************************
  // 1. AUTHENTICATION & TOKEN MANAGEMENT (ฟังก์ชันเดิม)
  // ******************************************************

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

  // ******************************************************
  // 2. DASHBOARD DATA (ฟังก์ชันเดิม)
  // ******************************************************

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


  // ******************************************************
  // 3. COURSE PAGE DATA (ฟังก์ชันใหม่สำหรับหน้า Course)
  // ******************************************************

  // 1. ดึงรายการหมวดหมู่ทั้งหมด (เช่น Maths, Robotic)
  static Future<List<String>> getCourseCategories() async {
    final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/courses/categories'));

    final data = json.decode(res.body);
    if (res.statusCode == 200) {
      // Backend ส่ง {"categories": ["Maths", "Robotic", ...]}
      return List<String>.from(data['categories'] ?? []);
    } else {
      throw Exception(data['message'] ?? 'Failed to load categories');
    }
  }

  // 2. ดึงรายการคอร์สทั้งหมด (พร้อม Filter, Sort, Search)
  static Future<List<Map<String, dynamic>>> getCourses({
    String? category, // ใช้สำหรับ Filter: "Maths" หรือ "Robotic"
    String? sort,     // ใช้สำหรับ Sort: "popular" หรือ "new"
    String? search    // ใช้สำหรับ Search Bar
  }) async {

    // สร้าง Query Parameters
    final Map<String, dynamic> queryParams = {};
    if (category != null) queryParams['category'] = category;
    if (sort != null) queryParams['sort'] = sort;
    if (search != null) queryParams['search'] = search;

    // สร้าง URI ที่มี Query Params ติดไปด้วย
    final uri = Uri.parse('${AppConfig.baseUrl}/api/courses').replace(queryParameters: queryParams);
    final res = await http.get(uri);

    final data = json.decode(res.body);
    if (res.statusCode == 200) {
      // Backend ส่งรายการคอร์ส [ {title: 'Robo Kiddy', price: 20000, ...}, ... ]
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Failed to load courses');
    }
  }
}