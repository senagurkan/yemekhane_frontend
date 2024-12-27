import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
static const String baseUrl = "http://192.168.1.101/yemekhane_api";

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Sunucu hatası: ${response.statusCode}');
    }
  }
}
