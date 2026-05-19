import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import '../widgets/bubble_background.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Kita tidak pakai backgroundColor biasa, melainkan Container dengan Gradient
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white, // Putih di atas
              Constants.colorLightIce, // Transisi ice blue di tengah
              Constants.colorCyan, // Cyan di bawah
            ],
            stops: [0.3, 0.7, 1.0], // Mengatur titik persebaran gradasi
          ),
        ),
        child: Stack(
          children: [
            const BubbleBackground(), // Animasi gelembung sabun terbang
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30.0,
                            vertical: 40.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Spacer(flex: 2), // Mendorong logo agak ke tengah atas
                              // --- BAGIAN LOGO ---
                              Image.asset('assets/images/brand/logo.png', height: 100),
                              const SizedBox(height: 6),
                              const Text(
                                'Wish Wash',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Constants.colorDarkBlue,
                                ),
                              ),

                              const Spacer(flex: 3), // Mendorong teks dan tombol ke bawah
                              // --- BAGIAN TEKS PROMO ---
                              SizedBox(
                                width: double.infinity, // Memaksa area teks melebar penuh
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // Membuat seluruh elemen di dalamnya rata kiri
                                  children: [
                                    const Text(
                                      'Your Laundry, refreshed',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900, // Bold (w700)
                                        color: Constants.colorDarkBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Save time, stay fresh with Wish Wash.\nYou’ll wish you washed here',
                                      textAlign: TextAlign.left, // Teks multi-baris juga rata kiri
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700, // ni adalah ukuran untuk Semi-Bold
                                        color: Constants.colorDarkBlue,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),

                              // --- BAGIAN TOMBOL ---
                              // Tombol Sign In (Cyan Gradient, Border Putih)
                              Container(
                                width: double.infinity,
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF80DEEA), Color(0xFF00BCD4)], // Cyan terang ke dalam
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14), // Sedikit lebih kecil dari Container
                                    splashColor: Colors.white.withOpacity(0.4), // Efek riak saat diklik
                                    highlightColor: Colors.black.withOpacity(0.1), // Efek gelap saat ditahan
                                    child: const Center(
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16), // Jarak antar tombol
                              // 2. Tombol Create Account (Putih/Ice Gradient, Border Navy)
                              Container(
                                width: double.infinity,
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFF0F8FF)], // Putih ke biru es sangat pudar
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Constants.colorDarkBlue, width: 1.5),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    splashColor: Constants.colorDarkBlue.withOpacity(0.15), // Efek riak navy saat diklik
                                    highlightColor: Colors.black.withOpacity(0.05), // Efek gelap saat ditahan
                                    child: const Center(
                                      child: Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Constants.colorDarkBlue,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ), // end SafeArea
          ], // end Stack children
        ), // end Stack
      ), // end Container
    ); // end Scaffold
  }
}
