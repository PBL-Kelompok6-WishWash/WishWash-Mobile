import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/home_screen.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_admin.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_kurir.dart';
import 'package:mobile/screens/pelanggan/profile/profile_screen.dart';
import 'package:mobile/screens/pelanggan/orders/payment.dart';

class ChatScreen extends StatelessWidget {
  final bool showNavbar;
  const ChatScreen({super.key, this.showNavbar = true});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    const Color cyanColor = Color(0xFF42C6D4);

    return Scaffold(
      backgroundColor: const Color(0xFFBCEFF2),
      extendBody: true,
      body: Column(
        children: [
          // --- HEADER & APPBAR ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Message',
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- KONTEN HALAMAN (Sheet Putih) ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 100), // padding bawah untuk navbar & fab
                children: [
                  // Admin Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RoomChatScreen()),
                      );
                    },
                    child: _buildAdminCard(navyColor, cyanColor),
                  ),
                  const SizedBox(height: 24),
                  
                  // Courier Section Title
                  Row(
                    children: [
                      Text(
                        'Courier',
                        style: GoogleFonts.poppins(
                          color: navyColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: navyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Courier Cards
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentScreen()),
                      );
                    },
                    child: _buildCourierCard(
                      context: context,
                      name: 'Jibran Kagabuming',
                      platNomor: 'BP 1234 AB',
                      message: 'titidije, bos',
                      time: '11:11 am',
                      navyColor: navyColor,
                    ),
                  ),
                  _buildCourierCard(
                    context: context,
                    name: 'Sugeng Saklar',
                    platNomor: 'BP 5678 CD',
                    message: 'sdh di dpan qq',
                    time: '11:11 am',
                    navyColor: navyColor,
                  ),
                  _buildCourierCard(
                    context: context,
                    name: 'Dika Acikiwir',
                    platNomor: 'BP 9012 EF',
                    message: 'Y, ok',
                    time: '11:11 am',
                    navyColor: navyColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // FAB & BottomNavbar
      bottomNavigationBar: showNavbar ? BottomNavbar(
        currentIndex: 3, // Index 3 adalah untuk Chat/Message
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const PelangganHomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const ProfileScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
      ) : null,
    );
  }

  Widget _buildAdminCard(Color navyColor, Color cyanColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo image from assets
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cyanColor.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: cyanColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12), // Sesuaikan dengan radius container dikurangi border width
              child: Padding(
                padding: const EdgeInsets.all(6.0), // Padding agar tidak terpotong
                child: Image.asset(
                  'assets/images/brand/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      'W',
                      style: GoogleFonts.poppins(
                        color: cyanColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atmint Mahesa',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: navyColor,
                  ),
                ),
                Text(
                  'wjar boi, atmint jg mnusia',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: navyColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.push_pin_rounded,
            color: navyColor,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildCourierCard({
    required BuildContext context,
    required String name,
    required String platNomor,
    required String message,
    required String time,
    required Color navyColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomChatKurirScreen(
              courierName: name,
              platNomor: platNomor,
            ),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menggunakan CircleAvatar dengan icon sebagai placeholder foto profil
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade100,
            child: Icon(Icons.person, color: Colors.grey.shade400, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: navyColor,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: navyColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: navyColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
