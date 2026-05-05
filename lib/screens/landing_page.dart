import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

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
              Colors.white,               // Putih di atas
              Constants.colorLightIce,    // Transisi ice blue di tengah
              Constants.colorCyan,        // Cyan di bawah
            ],
            stops: [0.3, 0.7, 1.0], // Mengatur titik persebaran gradasi
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2), // Mendorong logo agak ke tengah atas
                
                // --- BAGIAN LOGO ---
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                ),
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
                // Tombol Sign In (Cyan)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.colorCyan,
                      foregroundColor: Colors.white,
                      elevation: 0, // 💡 Matikan shadow agar flat sesuai desain
                      side: const BorderSide(color: Colors.white, width: 1.5), // 💡 BORDER PUTIH
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Jarak antar tombol
                
                // 2. Tombol Create Account (Putih dengan Border Navy)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Constants.colorDarkBlue,
                      elevation: 0, // 💡 Matikan shadow
                      side: const BorderSide(color: Constants.colorDarkBlue, width: 1.5), // 💡 BORDER NAVY
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}