import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/home_screen.dart';
import 'package:mobile/screens/pelanggan/chat/chat_screen.dart';

import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showNavbar;
  const ProfileScreen({super.key, this.showNavbar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String namaLengkap = '';
  String noTelp = '';
  String email = '';
  String alamatLengkap = '';
  String fotoPelanggan = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final response = await PelangganService.getProfile();
    if (response['success'] == true) {
      final data = response['data'];
      final pelanggan = data['pelanggan'] ?? {};
      final user = pelanggan['User'] ?? {};

      setState(() {
        namaLengkap = pelanggan['nama_lengkap'] ?? 'User';
        noTelp = pelanggan['no_telp'] ?? '-';
        email = user['email'] ?? '';
        alamatLengkap = data['alamat_lengkap'] ?? 'Alamat belum diatur';
        fotoPelanggan = pelanggan['foto_pelanggan'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal memuat profil')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0F2F53);
    const Color cyanColor = Color(0xFF42C6D4);
    const Color bgGrey = Color(0xFFF8FBFC);

    return Scaffold(
      backgroundColor: bgGrey,
      extendBody: true,
      body: Stack(
        children: [
          // Background Gradient at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBCEFF2), Color(0xFFF8FBFC)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // --- HEADER & APPBAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // Ganti tombol back dengan spasi agar teks tetap di tengah
                      Text(
                        'Profile',
                        style: GoogleFonts.poppins(
                          color: navyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                ),
                
                // --- KONTEN HALAMAN ---
                Expanded(
                  child: isLoading 
                    ? const Center(child: CircularProgressIndicator(color: cyanColor))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // padding bawah untuk navbar & fab
                        children: [
                          // Profile Card
                          _buildProfileCard(navyColor, cyanColor),
                          const SizedBox(height: 24),
                          
                          // Menu List Card
                          _buildMenuListCard(navyColor, cyanColor),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      // FAB & BottomNavbar
      bottomNavigationBar: widget.showNavbar ? BottomNavbar(
        currentIndex: 4, // Index 4 adalah untuk Profile
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, a1, a2) => const PelangganHomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, a1, a2) => const ChatScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
      ) : null,
    );
  }

  Widget _buildProfileCard(Color navyColor, Color cyanColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: fotoPelanggan.isNotEmpty
                  ? Image.network(
                      fotoPelanggan,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaLengkap,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: navyColor),
                        const SizedBox(width: 6),
                        Text(
                          noTelp.isEmpty ? '-' : noTelp,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: navyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: navyColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alamatLengkap,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: navyColor,
                              fontWeight: FontWeight.w500,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAF9FA),
                foregroundColor: navyColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuListCard(Color navyColor, Color cyanColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.lock_outline_rounded, 'Change Password', navyColor, cyanColor),
          _buildMenuItem(Icons.language_rounded, 'Preferences & Language', navyColor, cyanColor),
          _buildMenuItem(Icons.receipt_long_rounded, 'Order History', navyColor, cyanColor),
          _buildMenuItem(Icons.credit_card_rounded, 'Payment History', navyColor, cyanColor),
          _buildMenuItem(Icons.help_outline_rounded, 'FAQ', navyColor, cyanColor),
          _buildLogoutItem(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color navyColor, Color cyanColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cyanColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: navyColor,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: navyColor, size: 16),
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLogoutItem() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          'Log Out',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 16),
        onTap: _showLogoutConfirmation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded, // Ikon tangan melambai (lucu)
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Konfirmasi Keluar',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F2F53),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Apakah Anda yakin ingin keluar dari akun Anda? Sesi Anda saat ini akan diakhiri.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.grey.shade100,
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // Tutup dialog
                          await AuthService.logout();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Keluar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
