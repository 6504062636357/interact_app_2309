import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';

class ApiService {
  static Future<String?> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    // ขอ token แบบ fresh ถ้าต้องการ: getIdToken(true)
    return await user?.getIdToken();
  }

  /// =========================
  /// SYNC USER (POST /api/users/sync)
  /// =========================
  static Future<Map<String, dynamic>> syncUser({String? name}) async {
    final token = await _getFirebaseToken();
    if (token == null) {
      throw Exception("No Firebase token (not logged in)");
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/api/users/sync');

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (name != null) "name": name,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Sync failed');
    }
  }

  /// =========================
  /// GET PROFILE (GET /api/users/me)
  /// =========================
  static Future<Map<String, dynamic>> getMe() async {
    final token = await _getFirebaseToken();
    if (token == null) {
      throw Exception("No Firebase token (not logged in)");
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/api/users/me');

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      // backend ของอ้อมอาจ return { user: {...} } หรือ return {...user...}
      if (data is Map && data.containsKey("user")) {
        return Map<String, dynamic>.from(data["user"]);
      }
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Get profile failed');
    }
  }

  /// =========================
  /// UPDATE PROFILE (PATCH /api/users/me) - เผื่อใช้ต่อ
  /// =========================
  static Future<Map<String, dynamic>> updateMe({
    String? name,
    String? phone,
    String? bio,
    int? goalMinutes,
    String? photoUrl,
  }) async {
    final token = await _getFirebaseToken();
    if (token == null) {
      throw Exception("No Firebase token (not logged in)");
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/api/users/me');

    final body = <String, dynamic>{};
    if (name != null) body["name"] = name;
    if (phone != null) body["phone"] = phone;
    if (bio != null) body["bio"] = bio;
    if (goalMinutes != null) body["goalMinutes"] = goalMinutes;
    if (photoUrl != null) body["photoUrl"] = photoUrl;

    final res = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      if (data is Map && data.containsKey("user")) {
        return Map<String, dynamic>.from(data["user"]);
      }
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Update profile failed');
    }
  }

  /// =========================
  /// GET COURSES (เดิมของอ้อม)
  /// =========================
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
}