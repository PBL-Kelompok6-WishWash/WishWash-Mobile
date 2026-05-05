import 'package:flutter/material.dart';

class Constants {
  // Karena kamu ngetes pakai emulator Android, localhost Go berubah jadi 10.0.2.2
  // Kalau kamu ngetes di web atau iOS, tetap pakai localhost atau 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  // --- Color Palette WishWash ---
  static const Color colorLightIce = Color(0xFFD2FAFB);
  static const Color colorCyan = Color(0xFF5ACFD6);
  static const Color colorBlue = Color(0xFF189BFA);
  static const Color colorDarkBlue = Color(0xFF0C4B8E);
}