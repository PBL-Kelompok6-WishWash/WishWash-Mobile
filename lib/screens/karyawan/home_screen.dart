import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardKaryawan extends StatelessWidget {
  const DashboardKaryawan({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF123B6B);
    const Color tealColor = Color(0xFF1E9A9F);
    const Color lightTeal = Color(0xFF4FD1D9);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // --- HEADER PRIBADI ---
          _buildHeader(navyColor),
          const SizedBox(height: 30),

          // --- HERO INCOME CARD (PREMIUM) ---
          _buildIncomeCard(navyColor, tealColor, lightTeal),
          const SizedBox(height: 30),

          // --- GRID STATUS 2x2 ---
          Text(
            "Pantau Pesanan",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: navyColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusGrid(),
          const SizedBox(height: 30),

          // --- AKTIVITAS TERKINI ---
          Text(
            "Aktivitas Terkini",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: navyColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivities(navyColor, tealColor),

          const SizedBox(height: 100), // Spacing agar tidak tertutup Bottom Nav
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET HELPER
  // ==========================================

  Widget _buildHeader(Color navyColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: NetworkImage('https://storage.googleapis.com/a1aa/image/eI2cOqN07H4qL1lC9rIqYl32E2T9e8lF4vNf0t2I5kE.jpg'), // Contoh Avatar
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat datang,",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: navyColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  "Mahesa!",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildGlassIconButton(Icons.qr_code_scanner_rounded, navyColor),
            const SizedBox(width: 10),
            _buildGlassIconButton(Icons.notifications_none_rounded, navyColor),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassIconButton(IconData icon, Color color) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildIncomeCard(Color navyColor, Color tealColor, Color lightTeal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [navyColor, const Color(0xFF1A5A9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: navyColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background blobs for the card to give it a premium texture
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Total Pendapatan Hari Ini",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Rp 727.000,00",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: lightTeal, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "+12.5% dari kemarin",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: lightTeal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15, // slightly wider than tall
      children: [
        _buildGridCard("ORDER", "3", const Color(0xFFFFF3E0), const Color(0xFFFF9800), Icons.receipt_long_rounded),
        _buildGridCard("PROSES", "0", const Color(0xFFE3F2FD), const Color(0xFF2196F3), Icons.local_laundry_service_rounded),
        _buildGridCard("ANTAR", "0", const Color(0xFFF3E5F5), const Color(0xFF9C27B0), Icons.delivery_dining_rounded),
        _buildGridCard("SELESAI", "8", const Color(0xFFE8F5E9), const Color(0xFF4CAF50), Icons.check_circle_outline_rounded),
      ],
    );
  }

  Widget _buildGridCard(String title, String count, Color bgColor, Color iconColor, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Aesthetic background icon
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              icon,
              size: 80,
              color: bgColor.withOpacity(0.8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF123B6B),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(Color navyColor, Color tealColor) {
    final List<Map<String, dynamic>> recentOrders = [
      {"id": "TR001", "name": "Ica", "status": "PickUp", "color": Colors.orange},
      {"id": "TR002", "name": "Budi", "status": "Setrika", "color": Colors.blue},
      {"id": "TR003", "name": "Siti", "status": "Qris", "color": Colors.purple},
      {"id": "TR004", "name": "Andi", "status": "Selesai", "color": Colors.green},
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: recentOrders.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final order = recentOrders[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  order["id"],
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order["name"],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (order["color"] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order["status"],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: order["color"],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}