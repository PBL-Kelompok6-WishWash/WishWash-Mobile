import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
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

    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        final isEn = lang == 'en';
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2), // Soft Cyan Signature
          extendBody: true,
          body: Stack(
            children: [
              Column(
                children: [
                  // Header
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Text(
                            isEn ? 'Create New Order' : 'Buat Pesanan Baru',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Content Card
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
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'Select Service Category' : 'Pilih Kategori Layanan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: navyColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isEn 
                                    ? 'Choose the appropriate category to continue creating a new laundry order.' 
                                    : 'Pilih kategori yang sesuai untuk melanjutkan pembuatan pesanan laundry baru.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 28),

                              _buildOrderOption(
                                icon: Icons.local_laundry_service_outlined,
                                title: isEn ? 'Wash & Ironing' : 'Cuci & Setrika',
                                subtitle: isEn 
                                    ? 'Complete washing, drying, and ironing service' 
                                    : 'Layanan lengkap cuci bersih, kering, dan disetrika rapi',
                                color: cyanColor,
                                navyColor: navyColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const WashIroningScreen()),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildOrderOption(
                                icon: Icons.wash_outlined,
                                title: isEn ? 'Wash Only' : 'Cuci Saja',
                                subtitle: isEn 
                                    ? 'Washing and drying service without ironing' 
                                    : 'Layanan mencuci bersih dan mengeringkan tanpa disetrika',
                                color: const Color(0xFF5ACFD6),
                                navyColor: navyColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const WashOnlyScreen()),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildOrderOption(
                                icon: Icons.dry_cleaning_outlined, 
                                title: isEn ? 'Ironing Only' : 'Setrika Saja',
                                subtitle: isEn 
                                    ? 'Professional ironing and premium fragrance service' 
                                    : 'Layanan menyetrika rapi dan disemprot pewangi premium',
                                color: const Color(0xFF28A0A8),
                                navyColor: navyColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const IroningOnlyScreen()),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildOrderOption(
                                icon: Icons.checkroom_outlined, 
                                title: isEn ? 'Dry Clean' : 'Dry Clean',
                                subtitle: isEn 
                                    ? 'Premium dry cleaning for special garments' 
                                    : 'Layanan dry clean premium untuk pakaian khusus',
                                color: const Color(0xFF70D6E3),
                                navyColor: navyColor,
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
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color navyColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
