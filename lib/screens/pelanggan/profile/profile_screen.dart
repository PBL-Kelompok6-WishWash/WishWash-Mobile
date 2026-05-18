import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/home_screen.dart';
import 'package:mobile/screens/pelanggan/chat/chat_screen.dart';
import 'package:mobile/screens/pelanggan/home/alamat_screen.dart';
import 'dart:convert';

import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showNavbar;
  const ProfileScreen({super.key, this.showNavbar = true});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String namaLengkap = '';
  String noTelp = '';
  String email = '';
  String username = '';
  String alamatLengkap = '';
  String fotoPelanggan = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void reloadProfile() {
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
        username = user['username'] ?? '';
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
                child: _buildProfileImage(cyanColor),
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
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: navyColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email.isEmpty ? '-' : email,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: navyColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
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
              onPressed: () => _showEditProfileBottomSheet(navyColor, cyanColor),
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

  Widget _buildProfileImage(Color cyanColor) {
    if (fotoPelanggan.startsWith('http://') || fotoPelanggan.startsWith('https://')) {
      return Image.network(
        fotoPelanggan,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(cyanColor),
      );
    } else if (fotoPelanggan.startsWith('data:image')) {
      try {
        final base64Content = fotoPelanggan.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(cyanColor),
        );
      } catch (e) {
        return _buildDefaultAvatar(cyanColor);
      }
    } else if (fotoPelanggan.isNotEmpty) {
      return Image.asset(
        fotoPelanggan,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(cyanColor),
      );
    } else {
      return _buildDefaultAvatar(cyanColor);
    }
  }

  Widget _buildDefaultAvatar(Color cyanColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: cyanColor.withOpacity(0.12),
      ),
      child: Icon(Icons.person, size: 42, color: cyanColor),
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
          _buildMenuItem(
            Icons.location_on_outlined,
            'My Address',
            navyColor,
            cyanColor,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlamatScreen()),
              );
              setState(() {
                isLoading = true;
              });
              _fetchProfile(); // reload
            },
          ),
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

  Widget _buildMenuItem(IconData icon, String title, Color navyColor, Color cyanColor, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cyanColor.withOpacity(0.7), cyanColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cyanColor.withOpacity(0.4),
                        offset: const Offset(2, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: navyColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: navyColor.withOpacity(0.5), size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3F3), Color(0xFFFFEBEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.15),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showLogoutConfirmation,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7B7B), Colors.redAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.4),
                        offset: const Offset(2, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent.withOpacity(0.5), size: 14),
                ),
              ],
            ),
          ),
        ),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F3),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFE1E1), width: 4),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 36,
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
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade100, Colors.grey.shade300],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            const BoxShadow(
                              color: Colors.white,
                              offset: Offset(-2, -2),
                              blurRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.grey.shade400.withOpacity(0.5),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: Text(
                                'Batal',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF7B7B), Colors.redAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: Text(
                                'Keluar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

  void _showEditProfileBottomSheet(Color navyColor, Color cyanColor) {
    final nameController = TextEditingController(text: namaLengkap);
    final phoneController = TextEditingController(text: noTelp == '-' ? '' : noTelp);
    final usernameController = TextEditingController(text: username);
    final emailController = TextEditingController(text: email);
    final photoController = TextEditingController(text: fotoPelanggan);
    
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perbarui informasi pribadi Anda dengan mudah',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Inputs
                    _buildInputLabel('Nama Lengkap', navyColor),
                    _buildTextField(nameController, 'Masukkan nama lengkap', Icons.person_outline),
                    
                    _buildInputLabel('Nomor Telepon', navyColor),
                    _buildTextField(phoneController, 'Masukkan nomor telepon', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                    
                    _buildInputLabel('Username', navyColor),
                    _buildTextField(usernameController, 'Masukkan username', Icons.alternate_email_outlined),
                    
                    _buildInputLabel('Email', navyColor),
                    _buildTextField(emailController, 'Masukkan email', Icons.mail_outline, keyboardType: TextInputType.emailAddress),
                    
                    _buildInputLabel('URL Foto Profil (Opsional)', navyColor),
                    _buildTextField(photoController, 'Masukkan URL foto profil', Icons.image_outlined),
                    
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [cyanColor, const Color(0xFF00ACC1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cyanColor.withOpacity(0.4),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isSaving ? null : () async {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Nama lengkap tidak boleh kosong')),
                                );
                                return;
                              }
                              
                              setModalState(() {
                                isSaving = true;
                              });

                              final response = await PelangganService.updateProfile({
                                'nama': nameController.text.trim(),
                                'no_telp': phoneController.text.trim(),
                                'username': usernameController.text.trim(),
                                'email': emailController.text.trim(),
                                'foto_pelanggan': photoController.text.trim(),
                              });

                              if (mounted) {
                                if (response['success'] == true) {
                                  Navigator.pop(context); // Tutup bottom sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response['message']),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  setState(() {
                                    isLoading = true;
                                  });
                                  _fetchProfile(); // reload profile card
                                } else {
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response['message']),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Center(
                              child: isSaving
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'Simpan Perubahan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputLabel(String label, Color navyColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: navyColor.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0F2F53)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
