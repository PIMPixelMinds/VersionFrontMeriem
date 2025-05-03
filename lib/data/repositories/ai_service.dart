import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String apiKey = "AIzaSyB82Gg5oyIIQaPQ27Anf9ctOPumksPKtPc";
  static const String apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey";

  Future<List<String>> generateWords({String lang = 'en'}) async {
    try {
      final prompt = lang == 'fr'
          ? "Génère 6 mots courants en français. Retourne seulement une liste séparée par des espaces."
          : "Generate 6 common words in English. Return only a space-separated list.";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data["candidates"][0]["content"]["parts"][0]["text"] as String;
        final cleaned = rawText
            .replaceAll(RegExp(r'[^\w\sÀ-ÿ\-]'), '')
            .replaceAll('\n', ' ')
            .trim();
        final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        return words;
      } else {
        throw Exception("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Gemini API Error: $e");
      throw Exception("Failed to fetch words");
    }
  }
}