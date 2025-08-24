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

    try {
      final urls = [
        '$baseUrl/levels/1/fields/$field/texts',
        '$baseUrl/levels/1/fields/both/texts'
      ];

      final responses = await Future.wait(
        urls.map((url) => http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )),
      );

      List<SanaText> allTexts = [];

      for (var response in responses) {
        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          allTexts.addAll(data.map((json) => SanaText.fromJson(json)));
        } else if (response.statusCode == 401) {
          throw 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول من جديد';
        } else {
          throw 'فشل في تحميل النصوص من ${response.request?.url}';
        }
      }

      return allTexts;
    } catch (e) {
      throw 'حدث خطأ أثناء تحميل النصوص: $e';
    }
  }
}
