import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../model/class_schedule.model.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ApiService {

  static Future<String?> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  // Sync user + ดึง role
  static Future<Map<String, dynamic>> syncUser() async {
    final token = await _getFirebaseToken();

    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Sync failed');
    }
  }
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> syncUserToMongo({
    required String uid,
    required String email,
    required String name,
  }) async {
    try {
      print("--- [API DEBUG] กำลังส่ง POST ไปที่: ${AppConfig.baseUrl}/api/users/sync");

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/users/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "firebaseUid": uid,
          "email": email,
          "name": name,
          "learnedToday": 0,
          "goalMinutes": 60,
        }),
      );

      print("--- [API DEBUG] Server Response Status: ${response.statusCode}");
      print("--- [API DEBUG] Server Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("--- [API DEBUG] MongoDB Sync SUCCESS! ---");
      } else {
        print("--- [API DEBUG] MongoDB Sync FAILED! (ตรวจสอบเส้นทาง API หรือโค้ด Node.js) ---");
      }
    } catch (e) {
      print("--- [API DEBUG] Connection Error: $e (ตรวจสอบว่า Server รันอยู่หรือไม่ หรือ IP ถูกต้องไหม) ---");
    }
  }
  static Future<Map<String, dynamic>> getDashboard() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid; // ดึง UID จาก Firebase

    if (uid == null) throw Exception('No user logged in');

    // ตรวจสอบ AppConfig.baseUrl ว่าไม่ใช่ localhost ถ้าคุณรันบนมือถือจริงหรือ Emulator
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/dashboard?uid=$uid'),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to fetch dashboard: ${res.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getCourses({
    String? category,
    String? sort,
    String? search,
    double? minPrice,
    double? maxPrice,
  }) async {

    final Map<String, String> queryParams = {};

    if (category != null) queryParams['category'] = category;
    if (sort != null) queryParams['sort'] = sort;
    if (search != null) queryParams['search'] = search;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

    final uri = Uri.parse('${AppConfig.baseUrl}/api/courses')
        .replace(queryParameters: queryParams);

    final res = await http.get(uri);

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load courses');
    }
  }
  static Future<List<ClassSchedule>> getClassSchedulesByCourse(String courseId) async {
    // 1. เปลี่ยนมาดึง Token จาก Firebase แทนการดึงจาก SharedPreferences
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    if (token == null) throw Exception('User not authenticated');

    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/class-schedules?courseId=$courseId'),
      headers: {
        'Content-Type': 'application/json',
        // 2. ส่ง Firebase ID Token ไปใน Header
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => ClassSchedule.fromJson(e)).toList();
    } else {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Failed to load schedules');
    }
  }
  static Future<void> createBooking({
    required String courseId,
    required String scheduleId,
  }) async {
    // ดึง UID จาก Firebase ปัจจุบัน
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) throw Exception('Please login before booking');

    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebaseUid': uid, // ส่ง UID นี้ไปแทนที่จะส่งเลข ID สุ่มๆ
        'courseId': courseId,
        'scheduleId': scheduleId,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Booking failed');
    }
  }


}
