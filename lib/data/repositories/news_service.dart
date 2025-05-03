//BECHA
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> fetchNews() async {
  final response = await http.get(Uri.parse('http://192.168.1.170:3000/news/latest'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load news');
  }
}