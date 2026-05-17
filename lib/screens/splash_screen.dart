import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // 1. Controller untuk background cyan (Jatuh memantul lalu mengembang)
  late AnimationController _bgController;
  late Animation<double> _bgDrop;
  late Animation<double> _bgScale;

  // 2. Controller untuk logo & garis putih fade in
  late AnimationController _logoController;
  late Animation<double> _logoFade;

  // 3. Controller untuk ditarik ke atas
  late AnimationController _exitController;
  late Animation<double> _logoMoveUp;

  @override
  void initState() {
    super.initState();

    // Setup Animasi 1: Bola Cyan Jatuh & Mengembang
    // Durasi diperlambat jadi 2.5 detik
    _bgController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2500)
    );
    // Interval 0.0 - 0.4: Jatuh memantul
    _bgDrop = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: const Interval(0.0, 0.4, curve: Curves.bounceOut))
    );
    // Interval 0.6 - 1.0: Mengembang seisi layar
    _bgScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: const Interval(0.6, 1.0, curve: Curves.easeInExpo))
    );

    // Setup Animasi 2: Fade In Logo & Garis
    _logoController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1200) // Fade perlahan
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut)
    );

    // Setup Animasi 3: Tarik Layar ke Atas
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800) // Tarikan sangat lambat & mulus
    );
    _logoMoveUp = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic)
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Layar putih menahan sejenak
    
    // 1. Bola jatuh & melebar
    await _bgController.forward();                           
    
    // 2. Fade in logo & garis
    await _logoController.forward();                         
    
    // Jeda sejenak untuk dinikmati sebelum ditarik
    await Future.delayed(const Duration(milliseconds: 1200)); 
    
    // 3. Pindah ke Landing Page dengan tarikan ke atas
    if (mounted) {
      _exitController.forward(); // Jalankan animasi logo naik ke atas
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LandingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0); // Dari bawah
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1800), // Sangat lambat dan elegan
        ),
      );
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double maxBgSize = size.height * 2.5; // Cukup besar menutupi layar

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgController, _logoController, _exitController]),
        builder: (context, child) {
          
          // --- KALKULASI POSISI BACKGROUND BOLA CYAN ---
          final double baseSize = 80.0; 
          final double startY = -150.0; // Di luar layar atas
          final double targetY = (size.height / 2) - (baseSize / 2); // Tepat di tengah
          
          // Posisi Y saat jatuh memantul
          final double currentBgDropY = startY + ((targetY - startY) * _bgDrop.value);
          
          // Ukuran bola saat melebar
          final double currentBgSize = baseSize + (maxBgSize * _bgScale.value);
          // Offset agar bola tetap berada di tengah saat melebar
          final double expandOffset = (currentBgSize - baseSize) / 2;

          // --- KALKULASI POSISI LOGO SAAT DITARIK ---
          final double centerLogoY = (size.height / 2) - 60;
          // Target ditarik jauh melewati atas layar
          final double topLogoY = centerLogoY - size.height; 
          final double currentLogoY = centerLogoY - ((centerLogoY - topLogoY) * _logoMoveUp.value);

          return Stack(
            children: [
              // 1. Bola Cyan Jatuh & Melebar
              Positioned(
                top: currentBgDropY - expandOffset,
                left: (size.width / 2) - (baseSize / 2) - expandOffset,
                child: Container(
                  width: currentBgSize,
                  height: currentBgSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,          // Putih di atas (Kesan glossy)
                        Color(0xFFE0F7FA),     // Light Ice di tengah
                        Color(0xFF00BCD4),     // Cyan pekat di bawah
                      ],
                      stops: const [0.2, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Garis Putih (Nempel di bawah logo, fade in)
              if (_logoFade.value > 0)
                Positioned(
                  top: currentLogoY + 60, // Nempel di titik tengah lingkaran putih
                  left: (size.width / 2) - 1,
                  child: Opacity(
                    opacity: _logoFade.value,
                    child: Container(
                      width: 2.0,
                      height: size.height / 2, // Sepanjang sisa layar ke bawah
                      color: Colors.white,
                    ),
                  ),
                ),

              // 3. Lingkaran Putih Logo (Fade in)
              if (_logoFade.value > 0)
                Positioned(
                  top: currentLogoY,
                  left: (size.width / 2) - 60,
                  child: Opacity(
                    opacity: _logoFade.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Colors.white, 
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/brand/logo.png', // Logo cyan W
                          width: 60,
                          height: 60,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback jika gambar gagal dimuat
                            return const Text("W", style: TextStyle(fontSize: 50, color: Color(0xFF4DD0E1), fontWeight: FontWeight.bold));
                          },
                        ),
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