import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

Future<List<dynamic>> getMyCourses(String token) async {
  final response = await http.get(
    Uri.parse('${AppConfig.baseUrl}/api/users/my-courses'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load courses');
  }
}