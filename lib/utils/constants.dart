import 'dart:io';
import 'package:flutter/material.dart';

class Constants {
  // IP akan secara otomatis mendeteksi apakah menggunakan emulator (10.0.2.2) 
  // atau HP Fisik menggunakan IP PC/Laptop Anda (192.168.1.5).
  static String baseUrl = 'http://10.0.2.2:8080/api/v1';

  static Future<void> initBaseUrl() async {
    try {
      // 1. Coba hubungkan ke port 8080 emulator (10.0.2.2)
      final socket = await Socket.connect('10.0.2.2', 8080, timeout: const Duration(milliseconds: 500));
      socket.destroy();
      baseUrl = 'http://10.0.2.2:8080/api/v1';
      debugPrint("Koneksi berhasil ke Emulator: $baseUrl");
    } catch (_) {
      try {
        // 2. Coba hubungkan ke localhost/127.0.0.1 (aktif jika menjalankan adb reverse tcp:8080 tcp:8080)
        final socket = await Socket.connect('127.0.0.1', 8080, timeout: const Duration(milliseconds: 500));
        socket.destroy();
        baseUrl = 'http://127.0.0.1:8080/api/v1';
        debugPrint("Koneksi berhasil ke Localhost via ADB Reverse: $baseUrl");
      } catch (_) {
        // 3. Fallback ke IP Wi-Fi PC/Laptop
        baseUrl = 'http://172.16.160.231:8080/api/v1';
        debugPrint("Gagal konek ke emulator & localhost, fallback ke IP PC: $baseUrl");
      }
    }
  }

  // --- Color Palette WishWash ---
  static const Color colorLightIce = Color(0xFFD2FAFB);
  static const Color colorCyan = Color(0xFF5ACFD6);
  static const Color colorBlue = Color(0xFF189BFA);
  static const Color colorDarkBlue = Color(0xFF0C4B8E);
}