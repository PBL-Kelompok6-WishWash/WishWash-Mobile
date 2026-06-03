import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/utils/constants.dart';

class PenilaianService {
  static String get baseUrl => '${Constants.baseUrl}/order';

  static Future<Map<String, dynamic>> rateOrder({
    required int orderId,
    required int bintang,
    int? bintangLayanan,
    int? bintangKurir,
    int? bintangKecepatan,
    String ulasan = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/$orderId/penilaian'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bintang': bintang,
        'bintang_layanan': bintangLayanan ?? bintang,
        'bintang_kurir': bintangKurir ?? bintang,
        'bintang_kecepatan': bintangKecepatan ?? bintang,
        'ulasan': ulasan,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Gagal mengirim ulasan');
    }
  }
}
