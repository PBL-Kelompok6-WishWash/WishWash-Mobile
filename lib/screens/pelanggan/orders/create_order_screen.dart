import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateOrderScreen extends StatelessWidget {
  const CreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cyanColor = Color(0xFF42C6D4);
    const Color navyColor = Color(0xFF0F2F53);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buat Pesanan Baru',
          style: GoogleFonts.poppins(
            color: navyColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOrderOption(
              icon: Icons.local_laundry_service,
              title: 'Cuci Kiloan',
              subtitle: 'Cuci dan setrika pakaian harian',
              color: cyanColor,
              onTap: () {
                // Navigasi ke form cuci kiloan
              },
            ),
            const SizedBox(height: 16),
            _buildOrderOption(
              icon: Icons.dry_cleaning,
              title: 'Setrika Saja',
              subtitle: 'Hanya jasa setrika pakaian',
              color: const Color(0xFF5ACFD6),
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildOrderOption(
              icon: Icons.roller_shades_closed, 
              title: 'Cuci Sepatu',
              subtitle: 'Perawatan cuci sepatu premium',
              color: const Color(0xFF28A0A8),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F2F53),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
