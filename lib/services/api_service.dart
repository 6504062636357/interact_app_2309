import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';

class ApiService {

  // =============================
  // GET FIREBASE TOKEN
  // =============================
  static Future<String?> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  // =============================
  // SYNC USER
  // =============================
 static Future<Map<String, dynamic>> syncUser() async {
  final token = await _getFirebaseToken();

  print("🔥 SYNC TOKEN: $token");

  final res = await http.post(
    Uri.parse('${AppConfig.baseUrl}/api/users/sync'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print("🔥 SYNC STATUS: ${res.statusCode}");
  print("🔥 SYNC BODY: ${res.body}");

  return jsonDecode(res.body);
}

  // =============================
  // GET PROFILE
  // =============================
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

  // =============================
  // UPDATE PROFILE
  // =============================
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

  // =============================
  // GET COURSES
  // =============================
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

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data);
  } else {
    throw Exception("Failed to load courses");
  }
}
}