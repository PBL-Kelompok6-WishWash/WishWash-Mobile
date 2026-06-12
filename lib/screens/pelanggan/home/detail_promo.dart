import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/utils/constants.dart';

class DetailPromoScreen extends StatelessWidget {
  final Map<String, dynamic> promoData;

  const DetailPromoScreen({super.key, required this.promoData});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    const Color bgLight = Color(0xFFF8FBFC);

    final String couponCode = promoData['kode_promo'] ?? '';
    final String title = promoData['nama_promo'] ?? 'Promo Spesial';
    final String description = promoData['deskripsi'] ?? '-';
    final String promoType = promoData['tipe_promo'] ?? 'Nominal';
    final String rawImage = promoData['gambar_promo'] ?? '';

    // Style determination matching home_screen.dart
    final String code = couponCode.toLowerCase();
    final String name = title.toLowerCase();
    final String type = promoType.toLowerCase();

    int styleIndex = 0;
    if (code.contains('deliv') || code.contains('ongkir') || code.contains('pickup') ||
        name.contains('deliv') || name.contains('ongkir') || name.contains('pickup')) {
      styleIndex = 1; // Pink, free delivery style
    } else if (type == 'persentase') {
      styleIndex = 0; // Cyan style
    } else if (type == 'nominal') {
      styleIndex = 2; // Green style
    } else {
      styleIndex = 3; // Orange style
    }

    final List<Map<String, dynamic>> promoStyles = [
      {
        'gradient': const LinearGradient(
          colors: [Color(0xFFE3F9FD), Color(0xFFBCEFF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'textColor': const Color(0xFF0C4B8E),
        'imagePath': 'assets/images/promos/diskon.png',
      },
      {
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFFDEEF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'textColor': const Color(0xFF880E4F),
        'imagePath': 'assets/images/promos/free_deliv.png',
      },
      {
        'gradient': const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'textColor': const Color(0xFF1B5E20),
        'imagePath': 'assets/images/promos/diskon.png',
      },
      {
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'textColor': const Color(0xFFE65100),
        'imagePath': 'assets/images/promos/free_deliv.png',
      },
    ];

    final style = promoStyles[styleIndex];
    final Gradient bannerGradient = style['gradient'] as Gradient;
    final Color bannerTextColor = style['textColor'] as Color;
    final String defaultImagePath = style['imagePath'] as String;

    // Format Discount
    String discountText = "";
    if (promoType.toLowerCase() == 'persentase') {
      final int percent = (promoData['nominal_potongan'] as num?)?.toInt() ?? 0;
      discountText = "$percent%";
    } else {
      final double nominal = (promoData['nominal_potongan'] as num?)?.toDouble() ?? 0.0;
      discountText = "Rp ${NumberFormat('#,###', 'id_ID').format(nominal)}";
    }

    // Format Min Order
    final double minOrderVal = (promoData['minimal_order'] as num?)?.toDouble() ?? 0.0;
    final String minOrderText = minOrderVal > 0 
        ? "Rp ${NumberFormat('#,###', 'id_ID').format(minOrderVal)}" 
        : "Tanpa Minimal Transaksi";

    // Format Max Discount
    final double maxPotonganVal = (promoData['maksimal_potongan'] as num?)?.toDouble() ?? 0.0;
    final String maxDiscountText = maxPotonganVal > 0 
        ? "Rp ${NumberFormat('#,###', 'id_ID').format(maxPotonganVal)}" 
        : "Tanpa Batas Potongan";

    // Format Validity Period (Safe & Bulletproof Parser)
    String formatPeriod() {
      final startStr = promoData['tgl_mulai']?.toString();
      final endStr = promoData['tgl_berakhir']?.toString();
      if (startStr == null || endStr == null || startStr.isEmpty || endStr.isEmpty) return "-";
      try {
        DateTime start = DateTime.parse(startStr);
        DateTime end = DateTime.parse(endStr);
        final formatter = DateFormat('dd MMM yyyy');
        return "${formatter.format(start)} - ${formatter.format(end)}";
      } catch (e) {
        try {
          String parseSimple(String iso) {
            final parts = iso.split('T')[0].split('-');
            final year = parts[0];
            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
            final month = months[int.parse(parts[1]) - 1];
            final day = parts[2];
            return "$day $month $year";
          }
          return "${parseSimple(startStr)} - ${parseSimple(endStr)}";
        } catch (_) {
          return "$startStr - $endStr";
        }
      }
    }

    Widget imageWidget;
    if (rawImage.isNotEmpty) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      final String url = rawImage.startsWith('http') ? rawImage : '$staticHost$rawImage';
      imageWidget = Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(defaultImagePath, fit: BoxFit.contain),
      );
    } else {
      imageWidget = Image.asset(defaultImagePath, fit: BoxFit.contain);
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Promo',
          style: GoogleFonts.poppins(
            color: navyColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient (Same as Home Page)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350 + statusBarHeight,
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- HEADER ARTWORK / HERO ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: bannerGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: bannerTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: bannerTextColor.withOpacity(0.75),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: bannerTextColor.withOpacity(0.12),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_offer_rounded,
                                      color: bannerTextColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      couponCode,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: bannerTextColor,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 110,
                            child: imageWidget,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- PROMO INFO CARD ---
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailTile(
                          icon: Icons.calendar_month_rounded,
                          title: "Masa Berlaku",
                          value: formatPeriod(),
                          iconColor: Colors.orange,
                        ),
                        const Divider(height: 24),
                        _buildDetailTile(
                          icon: Icons.local_offer_rounded,
                          title: "Potongan",
                          value: discountText,
                          iconColor: Colors.redAccent,
                        ),
                        const Divider(height: 24),
                        _buildDetailTile(
                          icon: Icons.shopping_bag_rounded,
                          title: "Minimal Transaksi",
                          value: minOrderText,
                          iconColor: Colors.blueAccent,
                        ),
                        const Divider(height: 24),
                        _buildDetailTile(
                          icon: Icons.monetization_on_rounded,
                          title: "Maksimal Potongan",
                          value: maxDiscountText,
                          iconColor: Colors.green,
                        ),
                        const Divider(height: 24),
                        _buildDetailTile(
                          icon: Icons.category_rounded,
                          title: "Tipe Promo",
                          value: promoType,
                          iconColor: Colors.purple,
                        ),
                        const Divider(height: 24),
                        _buildDetailTile(
                          icon: Icons.info_rounded,
                          title: "Keterangan",
                          value: description,
                          iconColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- USE BUTTON ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: couponCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0C4B8E), Color(0xFF00BCD4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0C4B8E).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF0C4B8E),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Berhasil Disalin!',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Kode "$couponCode" berhasil disalin ke clipboard.',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'SALIN KODE & GUNAKAN',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                iconColor.withOpacity(0.25),
                iconColor.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF0C4B8E),
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}