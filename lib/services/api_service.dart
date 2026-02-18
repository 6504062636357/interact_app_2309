import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../model/class_schedule.model.dart';

class ApiService {
  // ******************************************************
  // 1. AUTHENTICATION & TOKEN MANAGEMENT
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
  // 2. DASHBOARD DATA
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
  // 3. COURSE PAGE DATA (พร้อมระบบ Filter ครบวงจร)
  // ******************************************************

  // ดึงรายการหมวดหมู่ทั้งหมด
  static Future<List<String>> getCourseCategories() async {
    final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/courses/categories'));
    final data = json.decode(res.body);
    if (res.statusCode == 200) {
      return List<String>.from(data['categories'] ?? []);
    } else {
      throw Exception(data['message'] ?? 'Failed to load categories');
    }
  }

  // ดึงรายการคอร์ส พร้อมรองรับ Search, Category, Sort, Price Range, และ Duration
  static Future<List<Map<String, dynamic>>> getCourses({
    String? category,
    String? sort,
    String? search,
    double? minPrice,
    double? maxPrice,
    int? durationMin,
    int? durationMax,
  }) async {
    // สร้าง Query Parameters เป็น Map<String, String>
    final Map<String, String> queryParams = {};

    if (category != null && category != 'All') queryParams['category'] = category;
    if (sort != null && sort != 'All') queryParams['sort'] = sort.toLowerCase();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    // เพิ่มการกรองราคา (ส่งไปเป็น String เพื่อต่อ URL)
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

    // เพิ่มการกรองชั่วโมงเรียน
    if (durationMin != null) queryParams['durationMin'] = durationMin.toString();
    if (durationMax != null) queryParams['durationMax'] = durationMax.toString();

    // สร้าง URI สมบูรณ์ (เช่น .../api/courses?category=Robotic&minPrice=15000&maxPrice=20000)
    final uri = Uri.parse('${AppConfig.baseUrl}/api/courses').replace(queryParameters: queryParams);

    final res = await http.get(uri);
    final data = json.decode(res.body);

    if (res.statusCode == 200) {
      // คาดหวังว่า Backend จะส่ง List ของคอร์สกลับมาโดยตรง
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Failed to load courses');
    }
  }
  static Future<List<ClassSchedule>> getClassSchedulesByCourse(String courseId) async {
    final token = await getToken();

    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/class-schedules?courseId=$courseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return List<ClassSchedule>.from(
        data.map((e) => ClassSchedule.fromJson(e)),
      );
    } else {
      throw Exception(data['message'] ?? 'Failed to load schedules');
    }
  }
  static Future<void> createBooking({
    required String courseId,
    required String scheduleId,
  }) async {
    final token = await getToken();

    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'courseId': courseId,
        'scheduleId': scheduleId,
      }),
    );

    if (res.statusCode != 201) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Booking failed');
    }
  }


}