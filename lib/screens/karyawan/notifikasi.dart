import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/pelanggan/orders/payment.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
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
                  // NOTIFIKASI 1: ORDER BARU (Cocok untuk Kasir)
                  _buildNotificationCard(
                    icon: Icons.add_shopping_cart_rounded,
                    title: "Order Baru Masuk!",
                    description: "Ada pesanan baru #WW-8821. Yuk, segera cek dan proses pesanannya di sistem.",
                    time: "Just now",
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFF9800),
                  ),
                  
                  // NOTIFIKASI 2: CHAT MASUK DARI PELANGGAN
                  _buildNotificationCard(
                    icon: Icons.chat_outlined,
                    title: "Pesan Baru Masuk",
                    description: "Pelanggan (Budi): 'Mbak, tolong baju putihnya dipisah ya...'",
                    time: "10:30 AM",
                    iconBg: const Color(0xFFE3F9FD),
                    iconColor: cyanColor,
                  ),

                  // NOTIFIKASI 3: TUGAS PICKUP (Cocok untuk Kurir)
                  _buildNotificationCard(
                    icon: Icons.local_shipping_outlined,
                    title: "Tugas Pickup Baru",
                    description: "Jemput cucian di Jl. Sudirman No. 45 (a.n. Siska). Segera meluncur ya!",
                    time: "08:15 AM",
                    iconBg: const Color(0xFFFDEEF6),
                    iconColor: const Color(0xFFE91E63),
                  ),

                  // NOTIFIKASI 4: TUGAS DELIVERY (Cocok untuk Kurir)
                  _buildNotificationCard(
                    icon: Icons.inventory_2_outlined,
                    title: "Cucian Siap Antar",
                    description: "Pesanan #WW-8800 sudah selesai dipacking dan siap dikirim ke pelanggan.",
                    time: "Yesterday",
                    iconBg: const Color(0xFFE2F3E4),
                    iconColor: const Color(0xFF2E7D32),
                  ),

                  // NOTIFIKASI 5: PEMBAYARAN MASUK (Cocok untuk Kasir)
                  _buildNotificationCard(
                    icon: Icons.payments_outlined,
                    title: "Pembayaran Diterima",
                    description: "Saldo masuk Rp 75.000 via QRIS untuk tagihan pesanan #WW-8799.",
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
                    color: const Color(0xFF0C4B8E).withOpacity(0.6),
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