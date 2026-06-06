import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailPromoScreen extends StatefulWidget {
  // Terima data dinamis dari database/API lewat constructor
  final Map<String, dynamic> promoData;

  const DetailPromoScreen({super.key, required this.promoData});

  @override
  State<DetailPromoScreen> createState() => _DetailPromoScreenState();
}

class _DetailPromoScreenState extends State<DetailPromoScreen> {
  bool _isClaimed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkClaimedStatus();
  }

  Future<void> _checkClaimedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final claimedList = prefs.getStringList('claimed_promo_ids') ?? [];
      final String promoId = widget.promoData['id_promo']?.toString() ?? '';
      if (mounted) {
        setState(() {
          _isClaimed = claimedList.contains(promoId);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _claimPromo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final claimedList = prefs.getStringList('claimed_promo_ids') ?? [];
      final String promoId = widget.promoData['id_promo']?.toString() ?? '';
      if (!claimedList.contains(promoId)) {
        claimedList.add(promoId);
        await prefs.setStringList('claimed_promo_ids', claimedList);
        if (mounted) {
          setState(() {
            _isClaimed = true;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo berhasil diklaim!')),
        );
      }
    } catch (e) {
      debugPrint("Error claiming promo in details: $e");
    }
  }

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
    String couponCode = widget.promoData['kode_promo'] ?? '';
    String description = widget.promoData['deskripsi'] ?? '';
    String paymentMethod = widget.promoData['payment_method'] ?? 'QRIS, Cash';
    String promoId = widget.promoData['id_promo']?.toString() ?? '';
    
    // Format Diskon berdasarkan jenisnya
    String discountText = "";
    if (widget.promoData['tipe_promo']?.toString().toLowerCase() == 'persentase') {
      discountText = "${(widget.promoData['nominal_potongan'] as num?)?.toInt() ?? 0}%";
    } else {
      discountText = "Rp ${NumberFormat('#,###', 'id_ID').format((widget.promoData['nominal_potongan'] as num?)?.toDouble() ?? 0.0)}";
    }

    // Format mata uang untuk min order
    String minOrder = widget.promoData['minimal_order'] != null
        ? "Rp ${NumberFormat('#,###', 'id_ID').format((widget.promoData['minimal_order'] as num).toDouble())}"
        : "Rp 0";

    // Format Tanggal (start_date & end_date)
    String formatPeriod() {
      if (widget.promoData['tgl_mulai'] == null || widget.promoData['tgl_berakhir'] == null) return "-";
      try {
        DateTime start = DateTime.parse(widget.promoData['tgl_mulai']);
        DateTime end = DateTime.parse(widget.promoData['tgl_berakhir']);
        var formatter = DateFormat('dd MMM yyyy', 'id_ID');
        return "${formatter.format(start)} - ${formatter.format(end)}";
      } catch (e) {
        return "${widget.promoData['tgl_mulai']} - ${widget.promoData['tgl_berakhir']}";
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, // Mulai dari sisi atas
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
                          widget.promoData['nama_promo'] ?? "Free Pickup Available",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: bannerTextMagenta,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.promoData['deskripsi'] ?? "",
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
                // Ilustrasi Skuter 3D
                Positioned(
                  right: -5,
                  bottom: -15,
                  child: Builder(
                    builder: (context) {
                      final String imgPath = widget.promoData['gambar_promo'] ?? '';
                      if (imgPath.isNotEmpty) {
                        final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
                        final String url = imgPath.startsWith('http') ? imgPath : '$staticHost$imgPath';
                        return Image.network(
                          url,
                          width: 170,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/promos/free_deliv.png',
                            width: 170,
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                      return Image.asset(
                        'assets/images/promos/free_deliv.png',
                        width: 170,
                        fit: BoxFit.contain,
                      );
                    },
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

            // --- KOTAK KODE PROMO / TOMBOL KLAIM ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isClaimed
                      ? Container(
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
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: promoBoxAccent.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _claimPromo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: promoBoxAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.confirmation_number_rounded, color: Colors.white),
                                const SizedBox(width: 10),
                                Text(
                                  "KLAIM VOUCHER SEKARANG",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
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