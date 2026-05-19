import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wash_ironing.dart';
import 'wash_only.dart';
import 'ironing_only.dart';
import 'dry_clean.dart';
class CreateOrderScreen extends StatelessWidget {
  const CreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cyanColor = Color(0xFF42C6D4);
    const Color navyColor = Color(0xFF0C4B8E);

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
              title: 'Wash & Ironing',
              subtitle: 'Complete washing and ironing service',
              color: cyanColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WashIroningScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOrderOption(
              icon: Icons.wash,
              title: 'Wash Only',
              subtitle: 'Washing service without ironing',
              color: const Color(0xFF5ACFD6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WashOnlyScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOrderOption(
              icon: Icons.dry_cleaning, 
              title: 'Ironing Only',
              subtitle: 'Professional ironing service',
              color: const Color(0xFF28A0A8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IroningOnlyScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOrderOption(
              icon: Icons.checkroom, 
              title: 'Dry Clean',
              subtitle: 'Premium dry cleaning service',
              color: const Color(0xFF70D6E3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DryCleanScreen()),
                );
              },
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
                          color: const Color(0xFF0C4B8E),
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
