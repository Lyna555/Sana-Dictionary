import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';

class WordService {
  static const String baseUrl = 'https://sana-dictionary-api.onrender.com/sana';

  static Future<List<SanaWord>> getTextWords(int textId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw 'لم يتم تسجيل الدخول';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/levels/1/fields/lettres/texts/$textId/words'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SanaWord.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول من جديد';
    } else {
      throw 'فشل في تحميل الكلمات';
    }
  }
}
