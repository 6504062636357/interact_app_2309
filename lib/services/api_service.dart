import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../model/class_schedule.model.dart';

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

  // 🔥 ฟังก์ชันนี้ต้องมี parameter ครบ
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
