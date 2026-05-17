import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/background.dart'; 
import 'package:mobile/widgets/navbar_karyawan.dart';
import 'package:mobile/screens/karyawan/home_screen.dart';
import 'package:mobile/screens/karyawan/orders.dart';

class ProfileScreenKaryawan extends StatefulWidget {
  const ProfileScreenKaryawan({super.key});

  @override
  State<ProfileScreenKaryawan> createState() => _ProfileScreenKaryawanState();
}

class _ProfileScreenKaryawanState extends State<ProfileScreenKaryawan> {
  // Controller buat handle input teks
  final TextEditingController _nameController = TextEditingController(text: "Mahesa");
  final TextEditingController _phoneController = TextEditingController(text: "081234567890");

  final Color navyColor = const Color(0xFF123B6B);
  final Color tealColor = const Color(0xFF1E9A9F);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // --- BAGIAN FOTO PROFIL ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: tealColor, width: 4),
                      image: const DecorationImage(
                        image: NetworkImage('https://via.placeholder.com/150'), // Ganti sama file foto asli nanti
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Logika buat ganti foto di sini
                        print("Edit Foto diklik");
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: navyColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- INPUT EDIT NAMA ---
            _buildEditField(
              label: "Nama Lengkap",
              controller: _nameController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            // --- INPUT EDIT NO TELP ---
            _buildEditField(
              label: "Nomor Telepon",
              controller: _phoneController,
              icon: Icons.phone_android_outlined,
              isPhone: true,
            ),
            
            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Logika simpan perubahan
                  print("Data Disimpan: ${_nameController.text}, ${_phoneController.text}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: Text(
                  "Simpan Perubahan",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- TOMBOL LOGOUT ---
            TextButton(
              onPressed: () {
                // Logika Logout
              },
              child: Text(
                "Keluar Akun",
                style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
  }

  // Widget Helper buat Input Field
  Widget _buildEditField({required String label, required TextEditingController controller, required IconData icon, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: navyColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: navyColor),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: tealColor),
              suffixIcon: const Icon(Icons.edit, size: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}