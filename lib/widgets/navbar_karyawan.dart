import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/auth/register_screen.dart';

class NavbarKaryawan extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarKaryawan({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color tealColor = Color(0xFF1E9A9F);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, "Home", 0, tealColor),
            _buildNavItem(Icons.assignment_rounded, "Orders", 1, tealColor),
            const SizedBox(width: 40), // Ruang buat FAB
            _buildNavItem(Icons.forum_rounded, "Message", 2, tealColor),
            _buildNavItem(Icons.person_rounded, "Profile", 3, tealColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color activeColor) {
    final bool isActive = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? activeColor : Colors.grey, size: 24),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isActive ? activeColor : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Fungsi Pop-up Menu Karyawan (Speed Dial Style) ---
void showKaryawanMenu(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Dismiss",
    barrierColor: Colors.black.withOpacity(0.4), // Efek gelap transparan
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100), // Di atas tombol +
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Menu Tambah Pesanan
                _buildMenuRow(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  label: "Tambah Pesanan",
                  onTap: () {
                    Navigator.pop(context);
                    print("Ke halaman Tambah Pesanan");
                  },
                ),
                const SizedBox(height: 20),
                // 2. Menu Tambah Akun
                _buildMenuRow(
                  context,
                  icon: Icons.person_add_alt_1_outlined,
                  label: "Tambah Akun",
                  onTap: () {
                    Navigator.pop(context); // Tutup pop-up menu dulu
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
    // Animasi muncul dari bawah
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(0, 0.5), end: const Offset(0, 0))
            .animate(anim1),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

// Widget Helper buat Baris Menu (Icon + Label di samping)
Widget _buildMenuRow(BuildContext context,
    {required IconData icon,
    required String label,
    required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label di Samping
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF123B6B),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Tombol Lingkaran Teal
        Container(
          width: 55,
          height: 55,
          decoration: const BoxDecoration(
            color: Color(0xFF4FD1D9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ],
    ),
  );
}