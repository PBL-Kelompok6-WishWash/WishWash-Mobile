import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/utils/constants.dart';

class PromoService {
  static String get baseUrl => '${Constants.baseUrl}/promo';

  static Future<List<dynamic>> getPromos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Gagal mengambil data promo');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }
}
