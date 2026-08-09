import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranslationService {
  /// API key loaded from .env
  static String get _apiKey => dotenv.env['GOOGLE_TRANSLATE_API_KEY'] ?? '';

  /// Translate a single text to target language
  static Future<String> translate({
    required String text,
    required String targetLang,
  }) async {
    final url = Uri.parse(
      "https://translation.googleapis.com/language/translate/v2?key=$_apiKey",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"q": text, "target": targetLang}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["data"]["translations"][0]["translatedText"];
      } else {
        return text; // fallback
      }
    } catch (e) {
      return text; // fallback
    }
  }

  /// Preload multiple translations (for menus, UI text)
  static Future<Map<String, String>> preloadTranslations(
    List<String> texts,
    String targetLang,
  ) async {
    Map<String, String> result = {};

    for (String text in texts) {
      result[text] = await translate(text: text, targetLang: targetLang);
    }

    return result;
  }

  /// Smart translate: auto English ↔ Sinhala based on device language
  static Future<String> smartTranslate(String text, String deviceLang) async {
    String targetLang = deviceLang == "si" ? "si" : "en";
    return await translate(text: text, targetLang: targetLang);
  }
}
