import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Tambahkan SingleTickerProviderStateMixin untuk menyalakan mesin waktu (Vsync) animasi
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // 4 Aktor Animasi kita
  late Animation<double> _cyanScale;
  late Animation<double> _logoDrop;
  late Animation<double> _whiteSweep;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    
    // Total durasi animasi: 3.5 detik
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Fase 1 (Detik 0.0 - 0.9): Titik Cyan membesar menutupi layar
    _cyanScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25, curve: Curves.easeInOut)),
    );

    // Fase 2 (Detik 1.2 - 2.1): Efek Yoyo Jatuh (Logo + Garis)
    // easeOutBack memberikan efek pantulan kecil di akhir jatuhnya!
    _logoDrop = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.60, curve: Curves.easeOutBack)),
    );

    // Fase 3 (Detik 2.2 - 2.9): Sapuan putih dari bawah ke atas
    _whiteSweep = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.85, curve: Curves.easeInOut)),
    );

    // Fase 4 (Detik 2.9 - 3.5): Teks "Wish Wash" muncul
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.85, 1.0, curve: Curves.easeIn)),
    );

    // Nyalakan mesin animasi, dan pindah halaman jika sudah selesai
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          // Pindah ke Landing Page dengan transisi Fade yang mulus
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const LandingPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Wajib dibunuh agar tidak bocor memori (memory leak)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Titik pusat Y tempat logo akan berhenti
    final targetY = screenHeight * 0.45; 

    return Scaffold(
      backgroundColor: Colors.white,
      // AnimatedBuilder akan me-render ulang layar setiap kali nilai _controller berubah (60 FPS)
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          
          // Kalkulasi posisi logo jatuh. Mulai dari -100 (luar layar) ke targetY
          double logoY = -100.0 + (_logoDrop.value * (targetY + 100.0));
          // Kalkulasi panjang garis putih. Sama dengan posisi logo agar terlihat menyatu
          double lineHeight = logoY > 0 ? logoY : 0.0;

          return Stack(
            children: [
              // Layer 1: Cyan scale expansion
              Center(
                child: Transform.scale(
                  scale: _cyanScale.value * 30, 
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Constants.colorCyan,
                    ),
                  ),
                ),
              ),

              // Layer 2: White sweep from bottom (erasing cyan)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: screenHeight * _whiteSweep.value,
                child: Container(color: Colors.white),
              ),

              // Layer 3: Trailing white line
              Positioned(
                top: 0,
                left: (screenWidth / 2) - 1.5, 
                width: 3, 
                height: lineHeight,
                child: Container(color: Colors.white),
              ),

              // Layer 4: Dropping logo
              Positioned(
                top: logoY - 45, 
                left: (screenWidth / 2) - 45,
                child: Opacity(
                  opacity: _logoDrop.value > 0.05 ? 1.0 : 0.0, 
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset('assets/images/brand/logo.png', height: 45),
                    ),
                  ),
                ),
              ),

              // Layer 5: Text fade in
              Positioned(
                top: targetY + 60, 
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _textFade.value,
                  child: const Text(
                    'Wish Wash',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Constants.colorDarkBlue,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}