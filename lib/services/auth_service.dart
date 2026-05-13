import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Gunakan 10.0.2.2 untuk memanggil localhost komputer dari emulator Android
  // Sesuaikan port 8080 dan URL endpoint dengan route Golang-mu nanti
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; 

  // Fungsi Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', responseData['token']);
        await prefs.setInt('id_role', responseData['id_role']);
        
        // 💡 SIMPAN NAMA ASLI DI SINI (Sesuai role yang dikirim Golang)
        if (responseData['display_name'] != null) {
          await prefs.setString('display_name', responseData['display_name']);
        }

        return {
          'success': true,
          'id_role': responseData['id_role'],
          'display_name': responseData['display_name'], // Kirim ke UI jika perlu
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Terjadi kesalahan saat login',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  // Fungsi Register
  static Future<Map<String, dynamic>> register(
      String username, 
      String email, 
      String password, 
      String namaLengkap, 
      String noTelp,      
      int roleId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'nama_lengkap': namaLengkap, 
          'no_telp': noTelp,           
          'id_role': roleId, 
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'],
          'username': responseData['username'], 
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Gagal melakukan registrasi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  // Fungsi untuk Logout (Menghapus token)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('id_role');
    await prefs.remove('display_name');
  }
}