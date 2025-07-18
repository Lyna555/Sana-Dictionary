import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/text_model.dart';

class TextService {
  static const String baseUrl = 'https://sana-dictionary-api.onrender.com/sana';

  static Future<List<SanaText>> getAllTexts(String field) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw 'لم يتم تسجيل الدخول';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/levels/1/fields/$field/texts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SanaText.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول من جديد';
    } else {
      throw 'فشل في تحميل النصوص';
    }
  }
}
