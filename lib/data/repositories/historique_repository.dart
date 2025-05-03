import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_constants.dart';
import 'shared_prefs_service.dart';
import '../../view/body/firebase_historique_api.dart';

String formatDate(String createdAt) {
  DateTime date = DateTime.parse(createdAt);
  return DateFormat('dd MMM yyyy HH:mm').format(date);
}

class HistoryRepository {
  final SharedPrefsService _prefsService = SharedPrefsService();
  final GlobalKey globalKey;

  HistoryRepository(this.globalKey);

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

  void _checkResponse(http.Response response, {int expected = 200}) {
    if (response.statusCode != expected) {
      throw Exception(
        jsonDecode(response.body)["message"] ?? "Erreur ${response.statusCode}",
      );
    }
  }

  Future<void> captureAndUploadScreenshot({
    required String userText,
    required List<String> bodyPartNames,
    required List<int> bodyPartIndexes,
  }) async {
    final token = await _getToken();
    _ensureAuthenticated(token);

    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);

      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/screenshot.png';
      File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      final fcmToken = await FirebaseHistoriqueApi().getFcmToken();

      final url = Uri.parse(ApiConstants.saveHistoriqueEndpoint);
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['userText'] = userText
        ..fields['bodyPartName'] = bodyPartNames.join(', ')
        ..fields['bodyPartIndex'] = bodyPartIndexes.join(', ')
        ..fields['fcmToken'] = fcmToken ?? ''
        ..files.add(await http.MultipartFile.fromPath(
          'screenshot',
          filePath,
          contentType: MediaType('image', 'png'),
        ));

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          jsonDecode(responseBody)['message'] ?? "Erreur d'envoi",
        );
      }

      print("✅ Capture envoyée avec succès !");
    } catch (e) {
      print("❌ Erreur capture : $e");
      throw Exception("Erreur lors de la capture et de l'upload : $e");
    }
  }

  Future<List<dynamic>> getHistorique() async {
    final token = await _getToken();
    _ensureAuthenticated(token);

    final response = await http.get(
      Uri.parse(ApiConstants.getHistoriqueEndpoint),
      headers: _headers(token),
    );
    _checkResponse(response);
    return json.decode(response.body);
  }

  Future<List<dynamic>> getGroupedHistorique() async {
    final token = await _getToken();
    _ensureAuthenticated(token);

    final response = await http.get(
      Uri.parse(ApiConstants.getGroupedHistoriqueEndpoint),
      headers: _headers(token),
    );
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getHistoriqueByDate(
      DateTime startDate, [
        DateTime? endDate,
      ]) async {
    final token = await _getToken();
    _ensureAuthenticated(token);

    final String start = DateFormat('yyyy-MM-dd').format(startDate);
    final String url = endDate != null
        ? '${ApiConstants.getHistoriqueByDateEndpoint}?start=$start&end=${DateFormat('yyyy-MM-dd').format(endDate)}'
        : '${ApiConstants.getHistoriqueByDateEndpoint}?start=$start';

    final response = await http.get(Uri.parse(url), headers: _headers(token));
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<void> sendPainStatusUpdate(
    String historiqueId,
    bool stillHurting,
  ) async {
    final token = await _getToken();
    _ensureAuthenticated(token);

    final response = await http.patch(
      Uri.parse(ApiConstants.checkPainHistoriqueEndpoint),
      headers: _headers(token),
      body: jsonEncode({
        'historiqueId': historiqueId,
        'stillHurting': stillHurting,
      }),
    );
    _checkResponse(response);
    print("✅ Douleur mise à jour");
  }

  Future<List<dynamic>> getHistoriqueNeedsPainCheck() async {
    final token = await _getToken();
    _ensureAuthenticated(token);

    final response = await http.get(
      Uri.parse(ApiConstants.getHistoriqueNeedsPainCheckEndpoint),
      headers: _headers(token),
    );
    _checkResponse(response);
    return jsonDecode(response.body);
  }
}