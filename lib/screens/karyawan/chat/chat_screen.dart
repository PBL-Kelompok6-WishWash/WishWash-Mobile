import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/karyawan/chat/roomchat.dart';
import 'package:mobile/services/translation_service.dart';

class KaryawanChatScreen extends StatelessWidget {
  const KaryawanChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    const Color cyanColor = Color(0xFF42C6D4);

    return Container(
      color: const Color(0xFFBCEFF2),
      child: Column(
        children: [
          // --- HEADER & APPBAR ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Symmetrical spacing
                    Text(
                      TranslationService.currentLang == 'en' ? 'Message' : 'Pesan',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 48), // Symmetrical spacing
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- KONTEN HALAMAN (Sheet Putih Premium) ---
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
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: TranslationService.currentLang == 'en' ? 'Search chat...' : 'Cari pesan...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search, color: navyColor, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Admin / Pusat Bantuan Section Title
                  Row(
                    children: [
                      Text(
                        TranslationService.currentLang == 'en' ? 'Support Center' : 'Pusat Bantuan',
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
                          color: navyColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Admin Card (Tapped navigates to room chat)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoomChatScreenKaryawan(),
                        ),
                      );
                    },
                    child: _buildAdminCard(navyColor, cyanColor),
                  ),
                  const SizedBox(height: 28),

                  // Pelanggan Section Title
                  Row(
                    children: [
                      Text(
                        TranslationService.currentLang == 'en' ? 'Customers' : 'Pelanggan',
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
                          color: navyColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Customer Cards
                  _buildCustomerCard(
                    context: context,
                    name: 'Jibran Kagabuming',
                    statusTag: 'Active Order',
                    message: 'titidije, bos',
                    time: '11:11 am',
                    navyColor: navyColor,
                    unreadCount: 2,
                  ),
                  _buildCustomerCard(
                    context: context,
                    name: 'Sugeng Saklar',
                    statusTag: 'Regular',
                    message: 'sdh di dpan qq',
                    time: '11:11 am',
                    navyColor: navyColor,
                    unreadCount: 0,
                  ),
                  _buildCustomerCard(
                    context: context,
                    name: 'Dika Acikiwir',
                    statusTag: 'VIP Customer',
                    message: 'Y, ok',
                    time: '11:11 am',
                    navyColor: navyColor,
                    unreadCount: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cyanColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: cyanColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
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
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'wjar boi, atmint jg mnusia',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: navyColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.push_pin_rounded, color: navyColor, size: 22),
        ],
      ),
    );
  }

  Widget _buildCustomerCard({
    required BuildContext context,
    required String name,
    required String statusTag,
    required String message,
    required String time,
    required Color navyColor,
    required int unreadCount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RoomChatScreenKaryawan(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Custom beautiful Initials-based Avatar with online status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFEBF8FA),
                  child: Text(
                    name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0C4B8E),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50), // Active green indicator
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusTag,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF42C6D4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: unreadCount > 0 ? navyColor : Colors.grey.shade500,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF42C6D4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
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
