import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/pelanggan/orders/payment.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0F2F53);
    const Color cyanColor = Color(0xFF42C6D4);

    return Scaffold(
      backgroundColor: const Color(0xFFBCEFF2),
      body: Column(
        children: [
          // --- HEADER & APPBAR ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Notification',
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer untuk menyeimbangkan posisi teks ke tengah
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
                color: Colors.white,
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
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
                children: [
                  _buildNotificationCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Your Order is Confirmed",
                    description: "please proceed with payment",
                    time: "Just now",
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentScreen()),
                      );
                    },
                  ),
                  _buildNotificationCard(
                    icon: Icons.shopping_bag_outlined,
                    title: "Order Processed",
                    description: "Pesanan #1234 sedang diproses oleh tim kami. Mohon tunggu ya!",
                    time: "10:30 AM",
                    iconBg: const Color(0xFFE3F9FD),
                    iconColor: cyanColor,
                  ),
                  _buildNotificationCard(
                    icon: Icons.local_offer_outlined,
                    title: "Exclusive Promo!",
                    description: "Dapatkan diskon 20% untuk pencucian pertama kamu hari ini.",
                    time: "08:15 AM",
                    iconBg: const Color(0xFFFDEEF6),
                    iconColor: const Color(0xFFE91E63),
                  ),
                  _buildNotificationCard(
                    icon: Icons.check_circle_outline_rounded,
                    title: "Delivery Success",
                    description: "Pakaian kamu sudah sampai di tujuan. Terima kasih sudah menggunakan WishWash!",
                    time: "Yesterday",
                    iconBg: const Color(0xFFE2F3E4),
                    iconColor: const Color(0xFF2E7D32),
                  ),
                  _buildNotificationCard(
                    icon: Icons.notifications_active_outlined,
                    title: "System Update",
                    description: "Kami baru saja memperbarui sistem untuk kenyamanan kamu.",
                    time: "2 days ago",
                    iconBg: const Color(0xFFF1E1FB),
                    iconColor: const Color(0xFF6A1B9A),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F2F53),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF0F2F53).withOpacity(0.6),
                    height: 1.4,
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