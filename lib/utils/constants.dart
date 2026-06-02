import 'dart:io';
import 'package:flutter/material.dart';

class Constants {
  // IP akan secara otomatis mendeteksi apakah menggunakan emulator (10.0.2.2) 
  // atau HP Fisik menggunakan IP PC/Laptop Anda (192.168.1.5).
  static String baseUrl = 'http://192.168.1.10:8080/api/v1';

  static Future<void> initBaseUrl() async {
    try {
      // Coba hubungkan ke port 8080 emulator (10.0.2.2)
      final socket = await Socket.connect('192.168.1.10', 8080, timeout: const Duration(milliseconds: 500));
      socket.destroy();
      baseUrl = 'http://192.168.1.10:8080/api/v1';
      debugPrint("Koneksi berhasil ke Emulator: $baseUrl");
    } catch (_) {
      baseUrl = 'http://192.168.1.10:8080/api/v1';
      debugPrint("Gagal konek ke emulator, fallback ke IP PC/Laptop: $baseUrl");
    }
  }

  // --- Color Palette WishWash ---
  static const Color colorLightIce = Color(0xFFD2FAFB);
  static const Color colorCyan = Color(0xFF5ACFD6);
  static const Color colorBlue = Color(0xFF189BFA);
  static const Color colorDarkBlue = Color(0xFF0C4B8E);
}