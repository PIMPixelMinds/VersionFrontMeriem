import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pim/core/constants/api_constants.dart';
import 'package:pim/data/model/appointment_mode.dart';
import 'shared_prefs_service.dart';

class AppointmentRepository {
  final SharedPrefsService _prefsService = SharedPrefsService();

  Future<String?> _getToken() async {
    return await _prefsService.getAccessToken();
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  void _ensureAuthenticated(String? token) {
    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }
  }

  void _checkResponse(http.Response response, {int expected = 201}) {
    if (response.statusCode != expected) {
      throw Exception(
        jsonDecode(response.body)["message"] ??
            "API Error ${response.statusCode}: ${response.body}",
      );
    }
  }

  Future<Appointment> addAppointment(Appointment appointment) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse(ApiConstants.addAppointmentEndpoint);

    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode({
        "fullName": appointment.fullName.trim(),
        "date": appointment.date.toLocal().toIso8601String(),
        "phone": appointment.phone,
        "status": appointment.status,
        "fcmToken": appointment.fcmToken,
      }),
    );

    _checkResponse(response);
    return Appointment.fromJson(jsonDecode(response.body));
  }

  Future<Appointment> updateAppointment(
    String name, {
    required String newFullName,
    required String newDate,
    required String newPhone,
  }) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse("${ApiConstants.updateAppointmentEndpoint}/$name");

    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode({
        "newFullName": newFullName,
        "newDate": newDate,
        "newPhone": newPhone,
      }),
    );

    _checkResponse(response, expected: 200);
    return Appointment.fromJson(jsonDecode(response.body));
  }

  Future<void> cancelAppointment(String name) async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse("${ApiConstants.cancelAppointmentEndpoint}/$name");

    final response = await http.put(
      url,
      headers: _headers(token),
    );

    _checkResponse(response, expected: 200);
  }

  Future<Map<String, dynamic>> displayAppointments() async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse(ApiConstants.displayAppointmentEndpoint);

    final response = await http.get(
      url,
      headers: _headers(token),
    );

    _checkResponse(response, expected: 200);
    return jsonDecode(response.body);
  }
}