import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class PaymentScreenNew extends StatelessWidget {
  const PaymentScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    const Color bgGrey = Color(0xFFF8FBFC);

    return Scaffold(
      backgroundColor: bgGrey,
      body: Stack(
        children: [
          // Background Gradient at the top (Seperti orders_screen)
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
            bottom: false,
            child: Column(
              children: [
                // --- HEADER & APPBAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Payment',
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
                const SizedBox(height: 10),

                // --- KONTEN HALAMAN ---
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    children: [
                      // QRIS Section
                      _buildSectionTitle('QRIS', navyColor),
                      const SizedBox(height: 20),
                      
                      // QR Code Box
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Image.network(
                            'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=WISHWASH_PAYMENT_1232',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.qr_code_2_rounded,
                              size: 150,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Download QRIS Button
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () => _downloadQRIS(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8F5E9), // Light Green
                            foregroundColor: const Color(0xFF2E7D32), // Dark Green
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Download QRIS',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Receipt Section
                      _buildSectionTitle('Receipt', navyColor),
                      const SizedBox(height: 20),
                      
                      // Receipt Card
                      _buildReceiptCard(navyColor),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color navyColor) {
    return Row(
      children: [
        Text(
          title,
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
            color: navyColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadQRIS(BuildContext context) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading QRIS...')),
        );
      }

      final url = Uri.parse('https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=WISHWASH_PAYMENT_1232');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: "QRIS_WISHWASH_1232",
        );

        if (context.mounted) {
          if (result != null && result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('QRIS successfully saved to Gallery!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save QRIS. You might need to allow storage permission.')),
            );
          }
        }
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildReceiptCard(Color navyColor) {
    final Color greyTextColor = navyColor.withOpacity(0.6);
    final Color dividerColor = navyColor.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Order & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #1232',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: navyColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Unpaid',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '16 April 2026',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: greyTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Detail Customer info
          _buildReceiptInfoRow('Customer', 'Mark Lee', greyTextColor, navyColor),
          _buildReceiptInfoRow('Pick Up Method', 'Delivery', greyTextColor, navyColor),
          _buildReceiptInfoRow('Delivered to', 'Jalan Kesana Kesini', greyTextColor, navyColor),
          _buildReceiptInfoRow('Payment Method', 'QRIS', greyTextColor, navyColor),
          
          Divider(color: dividerColor, height: 24, thickness: 1),

          // Service Details
          Text(
            'Service Details',
            style: GoogleFonts.poppins(fontSize: 11, color: greyTextColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Wash Only (By Weight)',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: navyColor),
          ),
          Text(
            'Daily Wear',
            style: GoogleFonts.poppins(fontSize: 11, color: greyTextColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('4 Kg x Rp 8.000', style: GoogleFonts.poppins(fontSize: 12, color: navyColor, fontWeight: FontWeight.w600)),
              Text('Rp 32.000', style: GoogleFonts.poppins(fontSize: 12, color: navyColor, fontWeight: FontWeight.w600)),
            ],
          ),
          
          Divider(color: dividerColor, height: 24, thickness: 1),

          // Sub Totals
          _buildPriceRow('Sub Total', 'Rp 32.000', navyColor, false),
          const SizedBox(height: 4),
          _buildPriceRow('Delivery Fee', 'Rp 8.000', navyColor, false),
          
          Divider(color: dividerColor, height: 24, thickness: 1),

          // Paid Total
          _buildPriceRow('Paid', 'Rp 40.000', navyColor, true),
          
          const SizedBox(height: 24),

          // Barcode
          Center(
            child: Column(
              children: [
                Image.network(
                  'https://barcode.tec-it.com/barcode.ashx?data=ORDER1232&code=Code128&multiplebarcodes=false&translate-esc=on',
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.view_week_rounded,
                    size: 60,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '*Show this receipt when picking up your order',
                  style: GoogleFonts.poppins(fontSize: 9, color: greyTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptInfoRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: labelColor, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, Color color, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
