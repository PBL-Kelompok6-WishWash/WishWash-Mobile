import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DetailPromoScreen extends StatelessWidget {
  // Terima data dinamis dari database/API lewat constructor
  final Map<String, dynamic> promoData;

  const DetailPromoScreen({super.key, required this.promoData});

  @override
  Widget build(BuildContext context) {
    // Penyesuaian Color Palette persis seperti di gambar baru
    const Color navyColor = Color(0xFF14457C);
    const Color cyanAccent = Color(0xFF6EDDDF); // Warna cyan di background banner
    const Color bannerPinkBg = Color(0xFFFBE4EB); // Pink background banner
    const Color bannerTextMagenta = Color(0xFF88194A); // Teks Free Pickup
    const Color promoBoxBg = Color(0xFFDBF8F8); // Cyan muda kotak promo
    const Color promoBoxAccent = Color(0xFF4FC6C9); // Cyan teks & border kotak promo

    // Parsing data dari database promo
    String couponCode = promoData['coupon_code'] ?? 'FREEPICKUP';
    String description = promoData['description'] ?? 'Layanan antar jemput gratis tanpa biaya sepeser pun untuk area operasional terpilih';
    String paymentMethod = promoData['payment_method'] ?? 'QRIS, Cash';
    String promoId = promoData['promo_id'] ?? 'PR002';
    
    // Format Diskon berdasarkan jenisnya
    String discountText = "";
    if (promoData['discount_type'] == 'percentage') {
      discountText = "${promoData['discount_value'] ?? '100'}%";
    } else {
      discountText = "Rp ${NumberFormat('#,###', 'id_ID').format(promoData['discount_value'] ?? 0)}";
    }

    // Format mata uang untuk min order
    String minOrder = promoData['min_order_value'] != null
        ? "Rp ${NumberFormat('#,###', 'id_ID').format(promoData['min_order_value'])}"
        : "Rp 50.000";

    // Format Tanggal (start_date & end_date)
    String formatPeriod() {
      if (promoData['start_date'] == null || promoData['end_date'] == null) return "19 Mei 2026 - 26 Mei 2026";
      try {
        DateTime start = DateTime.parse(promoData['start_date']);
        DateTime end = DateTime.parse(promoData['end_date']);
        var formatter = DateFormat('dd MMM yyyy', 'id_ID');
        return "${formatter.format(start)} - ${formatter.format(end)}";
      } catch (e) {
        return "${promoData['start_date']} - ${promoData['end_date']}";
      }
    }

    return Scaffold(
      backgroundColor: Colors.white, // Ubah ke putih persis gambar
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER BANNER 3D ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Cyan di belakang banner
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment. topCenter, // Mulai dari sisi atas
                    end: Alignment.bottomCenter, // Berakhir di sisi bawah
                    colors: [
                      cyanAccent, // Warna cyan tua di sisi kiri
                      Colors.white, // Warna putih di sisi kanan, menyatu dengan background
                    ],
                  ),
                ),
                ),
                // Banner Pink Utama
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 120),
                    decoration: BoxDecoration(
                      color: bannerPinkBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Free Pickup Available",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: bannerTextMagenta,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Get your laundry picked up for free in\nselected areas. Fast and convenient.",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: bannerTextMagenta,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Ilustrasi Skuter 3D (Pastikan kamu udah masukin gambarnya ke folder assets!)
                Positioned(
                  right: -5,
                  bottom: -15,
                  child: Image.asset(
                    'assets/images/promos/free_deliv.png', // Ganti path ini sesuai dengan folder asset kamu ya Dev!
                    width: 170,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- INFORMASI KETENTUAN (Tersusun Vertikal) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem("Masa Berlaku", formatPeriod(), navyColor),
                  _buildDetailItem("Minimal Transaksi", minOrder, navyColor),
                  _buildDetailItem("Pembayaran", paymentMethod, navyColor),
                  _buildDetailItem("S&K", description, navyColor),
                  _buildDetailItem("Nominal Potongan", discountText, navyColor),
                  _buildDetailItem("ID Promo", promoId, navyColor),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200, thickness: 1.5),
            const SizedBox(height: 8),

            // --- KOTAK KODE PROMO ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: promoBoxBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: promoBoxAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kode Promo",
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            color: promoBoxAccent, 
                            fontWeight: FontWeight.w600
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          couponCode,
                          style: GoogleFonts.poppins(
                            fontSize: 18, 
                            color: navyColor, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: couponCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode promo berhasil disalin!')),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "SALIN",
                        style: GoogleFonts.poppins(
                          color: promoBoxAccent, 
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            
            // Memberikan sedikit ruang di bawah layar
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper widget buat bikin list informasi yang numpuk atas-bawah persis gambar
  Widget _buildDetailItem(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13, 
              color: color, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13, 
              color: color, 
              fontWeight: FontWeight.w400,
              height: 1.4, // Biar teks deskripsi panjang (S&K) tetep rapi dibacanya
            ),
          ),
        ],
      ),
    );
  }
}