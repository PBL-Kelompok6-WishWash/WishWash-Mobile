import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/background.dart'; 
import 'package:mobile/widgets/navbar_karyawan.dart';
import 'package:mobile/screens/karyawan/orders.dart';
import 'package:mobile/screens/karyawan/profile.dart';

class DashboardKaryawan extends StatelessWidget {
  const DashboardKaryawan({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi warna utama aplikasi WishWash
    const Color navyColor = Color(0xFF123B6B);
    const Color tealColor = Color(0xFF1E9A9F);
    const Color lightTeal = Color(0xFF4FD1D9);

    return LaundryLayout(
      // 1. Floating Action Button (FAB) untuk memunculkan menu
      fab: FloatingActionButton(
        onPressed: () => showKaryawanMenu(context), // Fungsi dari navbar_karyawan.dart
        backgroundColor: lightTeal,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      
      // 2. Custom Navbar Karyawan
      bottomNav: NavbarKaryawan(
        currentIndex: 0, // Halaman Home
        onTap: (index) {
          if (index == 1) { // Kalau yang diklik itu icon ke-1 (Orders)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OrderScreenKaryawan()),
            );
          } else if (index == 3) { // Kalau diklik icon ke-3 (Profile)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreenKaryawan()),
            );
          }
        },
      ),

      // 3. Konten Utama Dashboard
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Header: Sapaan Pengguna
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hi, Mahesa!",
                  style: GoogleFonts.poppins( // Menggunakan Poppins agar profesional
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_scanner, color: navyColor, size: 26),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded, color: navyColor, size: 26),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 25),

            // Card Total Pendapatan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Total Pendapatan Hari Ini",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: navyColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Rp 727.000,00",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: navyColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pesanan Terkini",
                      style: GoogleFonts.poppins(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold, 
                        color: navyColor
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Baris info pesanan terkini
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPillText("Ica"),
                        _buildPillText("Setrika"),
                        _buildPillText("Qris"),
                        _buildPillText("PickUp"),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Status Cards: Order, Proses, Antar, Selesai
            _buildStatusCard("ORDER", "3", const Color(0xFFE0F7FA), tealColor),
            const SizedBox(height: 16),
            _buildStatusCard("PROSES", "0", const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
            const SizedBox(height: 16),
            _buildStatusCard("ANTAR", "0", const Color(0xFFE3F2FD), const Color(0xFF4FA8FF)),
            const SizedBox(height: 16),
            _buildStatusCard("SELESAI", "8", const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
            const SizedBox(height: 100), // Ruang agar tidak tertutup navbar
          ],
        ),
      ),
    );
  }

  // --- Widget Helper ---

  Widget _buildPillText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12, 
        color: const Color(0xFF123B6B), 
        fontWeight: FontWeight.w600
      ),
    );
  }

  // Card status dengan perbaikan agar tidak overflow
  Widget _buildStatusCard(String title, String count, Color bgColor, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(width: 8, height: 110, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: const Color(0xFF123B6B)
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              "Check", 
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)
                            ),
                          ),
                        )
                      ],
                    ),
                    Text(
                      count,
                      style: GoogleFonts.poppins(
                        fontSize: 50, 
                        fontWeight: FontWeight.bold, 
                        color: accentColor.withOpacity(0.8)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}