import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pim/core/constants/api_constants.dart';
import 'package:pim/data/repositories/shared_prefs_service.dart';

class HealthTrackerRepository {
  final SharedPrefsService _prefsService = SharedPrefsService();

  Future<String?> _getToken() async => await _prefsService.getAccessToken();

  Future<Map<String, String>> _buildHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> _getHeadersSync(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

Future<List<Map<String, dynamic>>> getActivities({required String lang}) async {
  final url = Uri.parse(ApiConstants.fetchActivitiesEndpoint);
  final response = await http.get(url, headers: await _buildHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> raw = json.decode(response.body);
    print("📡 Raw response body: $raw");
    
    final localized = raw.map<Map<String, dynamic>>((item) {
      final translations = item['translations'] ?? {};
      final selected = translations[lang] ?? translations['en'] ?? {};
      print("🌍 Using language code: $lang");
      return {
        'activity': selected['activity'] ?? '',
        'description': selected['description'] ?? '',
      };
    }).toList();

    print("✅ Activities for $lang: $localized");
    return localized;
  } else {
    throw Exception('Failed to load activities');
  }
}

  Future<int> getUpcomingAppointmentsCount() async {
    final url = Uri.parse(ApiConstants.countAppointmentsEndpoint);
    final response = await http.get(url, headers: await _buildHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return int.parse(data['message'].split(':')[1].split('|')[0].trim());
    } else {
      throw Exception('Failed to fetch appointments count');
    }
  }

  Future<List<dynamic>> getCompletedAppointments() async {
    final url = Uri.parse(ApiConstants.fetchCompletedAppointmentsEndpoint);
    final response = await http.get(url, headers: await _buildHeaders());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('appointment')) {
        return List<dynamic>.from(data['appointment']);
      } else {
        throw Exception('No completed appointments found');
      }
    } else {
      throw Exception('Failed to fetch completed appointments');
    }
  }

  Future<List<dynamic>> getQuestions() async {
    final url = Uri.parse(ApiConstants.questionsEndpoint);
    final response = await http.get(url, headers: await _buildHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<Map<String, dynamic>> checkQuestionnaireAvailability() async {
    final url = Uri.parse(ApiConstants.checkAvailabilityEndpoint);
    final response = await http.get(url, headers: await _buildHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> submitAnswers(Map<String, bool> answers) async {
    final url = Uri.parse(ApiConstants.answersEndpoint);

    final List<Map<String, dynamic>> formattedAnswers = answers.entries.map((entry) {
      return {
        'questionId': entry.key,
        'answer': entry.value ? 'Yes' : 'No',
      };
    }).toList();

    final response = await http.post(
      url,
      headers: await _buildHeaders(),
      body: json.encode({'answers': formattedAnswers}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit answers');
    }
  }

  Future<Map<String, dynamic>> getMedicationStats() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('User not authenticated');

      final url = Uri.parse(ApiConstants.getTodayRemindersEndpoint);
      final response = await http.get(url, headers: _getHeadersSync(token));

      if (response.statusCode == 200) {
        final List<dynamic> reminders = json.decode(response.body);

        int takenCount = 0;
        int pendingCount = 0;
        int skippedCount = 0;

        for (var reminder in reminders) {
          if (reminder['isCompleted'] == true) {
            takenCount++;
          } else if (reminder['isSkipped'] == true) {
            skippedCount++;
          } else {
            pendingCount++;
          }
        }

        final total = takenCount + pendingCount + skippedCount;
        return {
          'takenCount': takenCount,
          'pendingCount': pendingCount,
          'skippedCount': skippedCount,
          'total': total,
          'adherenceRate': total > 0 ? (takenCount / total) * 100 : 0,
          'pendingRate': total > 0 ? (pendingCount / total) * 100 : 0,
          'skippedRate': total > 0 ? (skippedCount / total) * 100 : 0,
        };
      } else {
        throw Exception('Failed to load medication stats');
      }
    } catch (e) {
      print('Error fetching medication stats: $e');
      return {
        'takenCount': 0,
        'pendingCount': 0,
        'skippedCount': 0,
        'total': 0,
        'adherenceRate': 0,
        'pendingRate': 0,
        'skippedRate': 0,
      };
    }
  }
}