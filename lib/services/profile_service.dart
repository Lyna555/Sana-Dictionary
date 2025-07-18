import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/user_model.dart';

class ProfileService {
  static const String baseUrl = 'https://sana-dictionary-api.onrender.com/sana';
  static SanaUser? currentUser;

  static Future<SanaUser> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw 'المستخدم ليس مسجلا دخوله';

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userJson = data['user'] ?? data;
      currentUser = SanaUser.fromJson(userJson);
      return currentUser!;
    } else {
      throw 'فشل في جلب معلومات المستخدم';
    }
  }

  static Future<void> uploadProfilePhoto(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('$baseUrl/profile');

    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final mimeTypeData = mimeType.split('/');

    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('Server Response: $responseBody');

    if (response.statusCode != 200) {
      try {
        final json = jsonDecode(responseBody);
        throw Exception(json['message'] ?? 'Upload failed');
      } catch (_) {
        throw Exception('Upload failed: $responseBody');
      }
    }
  }

  static Future<void> changePassword(
      String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw 'المستخدم ليس مسجلا دخوله';

    final response = await http.put(
      Uri.parse('$baseUrl/profile/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw data['message'] ?? 'فشل في تغيير كلمة المرور';
    }
  }

  static Future<void> updateUser({
    required String username,
    required String email,
  }) async {
    if (currentUser == null) throw 'الرجاء تسجيل الدخول أولاً';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      currentUser = SanaUser.fromJson(jsonDecode(response.body));
    } else {
      throw jsonDecode(response.body)['message'] ?? 'فشل في تحديث المعلومات';
    }
  }

  static Future<void> deleteUser() async {
    if (currentUser == null) throw 'الرجاء تسجيل الدخول أولاً';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await prefs.remove('token');
      currentUser = null;
    } else {
      throw 'فشل في حذف الحساب';
    }
  }
}
