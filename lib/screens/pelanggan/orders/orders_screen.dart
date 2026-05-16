import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrdersScreen extends StatelessWidget {
  final bool showNavbar;
  const OrdersScreen({super.key, this.showNavbar = true});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0F2F53);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FBFC),
        elevation: 0,
        title: Text(
          'Pesanan Saya',
          style: GoogleFonts.poppins(
            color: navyColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Menghilangkan tombol back
      ),
      body: Center(
        child: Text(
          'Riwayat Pesanan akan tampil di sini',
          style: GoogleFonts.poppins(color: navyColor),
        ),
      ),
    );
  }
}
