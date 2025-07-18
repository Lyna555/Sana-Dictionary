import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://sana-dictionary-api.onrender.com/sana';

  static Future<String> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
  }

  static Future<SanaUser> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return SanaUser.fromJson(jsonDecode(response.body));
    } else {
      throw 'فشل في جلب معلومات المستخدم';
    }
  }

  static Future<void> saveDeviceId(String token, String deviceId) async {
    final url = Uri.parse('$baseUrl/profile/device');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'device_id': deviceId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save device ID');
    }
  }
}
