import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../model/medication_models.dart';
import 'shared_prefs_service.dart';

class MedicationRepository {
   final SharedPrefsService _prefsService = SharedPrefsService();

  Future<String?> _getToken() async {
    return await _prefsService.getAccessToken();
  }


  Future<List<Medication>> getMedications() async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse(ApiConstants.getMedicationsEndpoint);

    final response = await http.get(url, headers: _headers(token));
    _checkResponse(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Medication.fromJson(item)).toList();
  }

  Future<List<MedicationReminder>> getTodayReminders() async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse(ApiConstants.getTodayRemindersEndpoint);

    final response = await http.get(url, headers: _headers(token));
    _checkResponse(response);

    final dynamic decoded = json.decode(response.body);
    final List<dynamic> data = decoded is List ? decoded : decoded['data'] ?? [];
    return data.map((e) => MedicationReminder.fromJson(e)).toList();
  }

  Future<List<MedicationReminder>> getRemindersForDate(DateTime date) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final dateString = date.toIso8601String().substring(0, 10);
    final url = Uri.parse('${ApiConstants.getRemindersForDateEndpoint}?date=$dateString');

    final response = await http.get(url, headers: _headers(token));
    _checkResponse(response);

    final dynamic decoded = json.decode(response.body);
    final List<dynamic> data = decoded is List ? decoded : decoded['data'] ?? [];
    return data.map((e) => MedicationReminder.fromJson(e)).toList();
  }

 Future<Medication> addMedication(Map<String, dynamic> medicationData, {File? imageFile}) async {
  final token = await _getToken();
  _ensureAuthenticated(token);

  if (imageFile != null) {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.addMedicationEndpoint),
    )..headers['Authorization'] = 'Bearer $token';

    // ✅ Proper handling of lists like timeOfDay
    medicationData.forEach((key, value) {
      if (value == null) return;

      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          request.fields['$key[$i]'] = value[i].toString();
        }
      } else {
        request.fields[key] = value.toString();
      }
    });

    request.files.add(await http.MultipartFile.fromPath(
      'medicationImage',
      imageFile.path,
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    _checkResponse(response, expected: 201);
    return Medication.fromJson(json.decode(response.body));
  } else {
    final response = await http.post(
      Uri.parse(ApiConstants.addMedicationEndpoint),
      headers: _headers(token),
      body: json.encode(medicationData),
    );
    _checkResponse(response, expected: 201);
    return Medication.fromJson(json.decode(response.body));
  }
}
Future<Medication> updateMedication(String id, Map<String, dynamic> data, {File? imageFile}) async {
  final token = await _getToken();
  _ensureAuthenticated(token);

  // Handle optional reminder deletion
  if (data.remove('deleteAllReminders') == true) {
    final deleteUrl = Uri.parse('${ApiConstants.updateMedicationEndpoint}/$id/delete-reminders');
    await http.post(deleteUrl, headers: _headers(token));
  }

  if (imageFile != null) {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('${ApiConstants.updateMedicationEndpoint}/$id'),
    )..headers['Authorization'] = 'Bearer $token';

    // ✅ Proper handling of lists (e.g., timeOfDay, specificDays)
    data.forEach((key, value) {
      if (value == null) return;

      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          request.fields['$key[$i]'] = value[i].toString();
        }
      } else {
        request.fields[key] = value.toString();
      }
    });

    // Add image
    request.files.add(await http.MultipartFile.fromPath('medicationImage', imageFile.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    _checkResponse(response);
    return Medication.fromJson(json.decode(response.body));
  } else {
    // JSON body (no file)
    final response = await http.patch(
      Uri.parse('${ApiConstants.updateMedicationEndpoint}/$id'),
      headers: _headers(token),
      body: json.encode(data),
    );

    _checkResponse(response);
    return Medication.fromJson(json.decode(response.body));
  }
}

  Future<bool> deleteMedication(String id) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final response = await http.delete(
      Uri.parse('${ApiConstants.deleteMedicationEndpoint}/$id'),
      headers: _headers(token),
    );
    _checkResponse(response);
    return true;
  }

  Future<Medication> getMedicationById(String id) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final response = await http.get(
      Uri.parse('${ApiConstants.getMedicationByIdEndpoint}/$id'),
      headers: _headers(token),
    );
    _checkResponse(response);
    return Medication.fromJson(json.decode(response.body));
  }

  Future<MedicationReminder> takeMedication(String id, TakeMedicationDto dto, {File? imageFile}) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse('${ApiConstants.takeMedicationEndpoint}/$id/take');

    if (imageFile != null) {
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['takenAt'] = dto.takenAt.toIso8601String();

      if (dto.quantityTaken != null) request.fields['quantityTaken'] = dto.quantityTaken.toString();
      if (dto.notes != null) request.fields['notes'] = dto.notes!;
      request.files.add(await http.MultipartFile.fromPath('medicationImage', imageFile.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _checkResponse(response);
      return MedicationReminder.fromJson(json.decode(response.body));
    } else {
      final response = await http.post(
        url,
        headers: _headers(token),
        body: json.encode(dto.toJson()),
      );
      _checkResponse(response);
      return MedicationReminder.fromJson(json.decode(response.body));
    }
  }

  Future<MedicationReminder> skipMedication(String id, DateTime date, String time) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse('${ApiConstants.skipMedicationEndpoint}/$id/skip');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({'scheduledDate': date.toIso8601String(), 'scheduledTime': time}),
    );
    _checkResponse(response);
    return MedicationReminder.fromJson(json.decode(response.body));
  }

  Future<List<MedicationHistory>> getMedicationHistory(String id, {DateTime? startDate, DateTime? endDate}) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final query = {
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };
    final uri = Uri.parse('${ApiConstants.getMedicationHistoryEndpoint}/$id/history').replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers(token));
    _checkResponse(response);
    final data = json.decode(response.body) as List;
    return data.map((e) => MedicationHistory.fromJson(e)).toList();
  }

  Future<List<StockHistory>> fetchStockHistory(String id) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse(ApiConstants.medicationStockHistoryEndpoint.replaceAll('{id}', id));
    final response = await http.get(url, headers: _headers(token));
    _checkResponse(response);
    final data = json.decode(response.body) as List;
    return data.map((e) => StockHistory.fromJson(e)).toList();
  }

  Future<void> updateStock({
    required String medicationId,
    required int quantity,
    int? lowStockThreshold,
    String? notes,
    String? token,
  }) async {
    token ??= await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse(ApiConstants.medicationUpdateStockEndpoint.replaceAll('{id}', medicationId));
    final body = json.encode({
      'quantity': quantity,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      if (notes != null) 'notes': notes,
    });
    final response = await http.patch(url, headers: _headers(token), body: body);
    _checkResponse(response);
  }

  Future<void> addStock({
    required String medicationId,
    required int quantity,
    String? notes,
    String? token,
  }) async {
    token ??= await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse(ApiConstants.medicationAddStockEndpoint.replaceAll('{id}', medicationId));
    final body = json.encode({
      'quantity': quantity,
      if (notes != null) 'notes': notes,
    });
    final response = await http.post(url, headers: _headers(token), body: body);
    _checkResponse(response);
  }

  Future<void> fixReminders(String token) async {
    final url = Uri.parse(ApiConstants.fixRemindersEndpoint);
    final response = await http.post(url, headers: _headers(token));
    _checkResponse(response);
  }

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  void _ensureAuthenticated(String? token) {
    if (token == null) throw Exception('User not authenticated');
  }

  void _checkResponse(http.Response response, {int expected = 200}) {
    if (response.statusCode != expected) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }
}
