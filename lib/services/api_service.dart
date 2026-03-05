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

  static Future<Map<String, dynamic>?> syncUserToMongo({
    required String uid,
    required String email,
    required String name,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/users/sync');
      print("--- [API DEBUG] Syncing to: $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "firebaseUid": uid.trim(),
          "email": email,
          "name": name,
          "learnedToday": 0,
          "goalMinutes": 60,
        }),
      );

      print("--- [API DEBUG] Status: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        print("--- [API DEBUG] MongoDB Sync SUCCESS! Data: $decodedData");

        // ส่งข้อมูลทั้งหมดที่ได้จาก Server (รวมถึง role) กลับไป
        return decodedData;
      } else {
        print("--- [API DEBUG] FAILED: ${response.body}");
        return null;
      }
    } catch (e) {
      print("--- [API DEBUG] Connection Error: $e");
      return null;
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
  // ค้นหาฟังก์ชัน createBooking เดิมใน ApiService แล้วเปลี่ยนเป็นแบบนี้ครับ:
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/bookings'), // ยิงไปที่ Path ที่เราแก้ใน server.js
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data), // ส่งก้อน data ที่รับมาจาก Flutter ทั้งหมด
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final errorData = jsonDecode(res.body);
        throw Exception(errorData['error'] ?? 'Booking failed');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  static Future<Map<String, dynamic>> getMe() async {
    final token = await _getFirebaseToken();

    if (token == null) {
      throw Exception("Not logged in");
    }

    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Get profile failed");
    }
  }
  static Future<void> updateMe({
    String? name,
    String? phone,
    String? bio,
    int? goalMinutes,
  }) async {

    final token = await _getFirebaseToken();

    final res = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/api/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (goalMinutes != null) 'goalMinutes': goalMinutes,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Update failed");
    }
  }

  // ฟังก์ชันสำหรับส่งวันว่างใหม่ไปที่ MongoDB
  static Future<bool> saveAvailability(String instructorId, DateTime date, List<String> slots) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/availability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "instructorId": instructorId,
          "date": date.toIso8601String(),
          "slots": slots.map((s) => {"time": s, "isBooked": false}).toList(),
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error saving availability: $e");
      return false;
    }

  }

  static Future<List<dynamic>> getAvailability(String instructorId) async {
    try {
      // ดึงข้อมูลวันว่างโดยใช้ instructorId (เช่น 6996b219...)
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/availability/$instructorId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // คืนค่าเป็น List ของข้อมูลวันว่างที่มี slots อยู่ข้างใน
        return jsonDecode(response.body);
      } else {
        print("--- [API DEBUG] Load Failed: ${response.body}");
        return [];
      }
    } catch (e) {
      print("--- [API DEBUG] Connection Error: $e");
      return [];
    }
  }

// เพิ่มในไฟล์ lib/services/api_service.dart

  static Future<Map<String, dynamic>> saveTeacherAvailability(Map<String, dynamic> data) async {
    try {
      // กำหนด URL สำหรับบันทึกข้อมูล (ปรับเปลี่ยนตาม IP/Domain ของ Backend คุณ)
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/teacher-availability'), // ตรวจสอบ endpoint นี้กับ backend อีกครั้ง
        headers: {
          'Content-Type': 'application/json', // ต้องระบุว่าเป็น JSON เสมอ
        },
        body: jsonEncode(data), // แปลง Map เป็น JSON string ก่อนส่ง
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // หากบันทึกสำเร็จ (200 OK หรือ 201 Created)
        return jsonDecode(response.body);
      } else {
        // หากเกิด error จากฝั่ง Server
        throw Exception('Failed to save availability: ${response.body}');
      }
    } catch (e) {
      // กรณีที่เชื่อมต่อ Server ไม่ได้
      throw Exception('Error connecting to server: $e');
    }
  }
// ฟังก์ชันสำหรับดึงรายชื่อผู้สอนทั้งหมดจาก Database

  static Future<Map<String, dynamic>?> getInstructorByName(String name) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/instructors/search?name=$name'),
      );
      // ตรวจสอบทั้ง Status 200 และ Body ต้องไม่ว่าง
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      }
      return null; // ถ้าไม่เจอ (404) หรือ Error ให้ส่ง null กลับไป
    } catch (e) {
      print("Error getInstructorByName: $e");
      return null;
    }
  }

  // ฟังชัน อัพเดตสถานะการจองโดยการกดยืนยันจากครูแล้วค่อยไปจ่ายเงิน
  static Future<List<dynamic>> getTeacherBookings(String instructorId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/bookings/teacher/$instructorId');
    print("--- [Flutter Log] Requesting API: $url");

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      print("--- [Flutter Log] Received Data: $data"); // เช็คตรงนี้ว่ามี student_name ไหม
      return data;
    } else {
      print("--- [Flutter Log] Error Status: ${res.statusCode}");
      throw Exception("Failed to load bookings");
    }
  }

  static Future<void> updateBookingStatus(String bookingId, String status) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/api/bookings/$bookingId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 200) throw Exception("Failed to update status");
  }


}

