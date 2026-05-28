import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:mobile/services/translation_service.dart';
import 'dart:typed_data';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final double promoDiscount;
  final double totalTagihan;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.order,
    required this.promoDiscount,
    required this.totalTagihan,
    required this.paymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgGrey = const Color(0xFFF8FBFC);

  String _formatRupiah(double value) {
    if (value == 0.0) return 'Rp 0';
    String valStr = value.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoString.split('T')[0];
    }
  }

  String _getEstSelesaiDate(Map<String, dynamic> order) {
    final String? pickupStr = order['jadwal_pickup']?.toString();
    final String? tglPesananStr = order['tgl_pesanan']?.toString();
    final String? baseDateStr = (pickupStr != null && pickupStr.isNotEmpty) ? pickupStr : tglPesananStr;

    if (baseDateStr == null || baseDateStr.isEmpty) {
      return '-';
    }
    try {
      final baseDate = DateTime.parse(baseDateStr);
      final paket = order['PaketLayanan'];
      final int durasiJam = paket != null ? (paket['durasi_jam'] as num?)?.toInt() ?? 0 : 0;
      
      if (durasiJam == 0) {
        return _formatDate(baseDateStr);
      }
      
      final estSelesai = baseDate.add(Duration(hours: durasiJam));
      final lang = TranslationService.currentLang;
      final months = lang == 'en' 
          ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          : ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      
      final int hour = estSelesai.hour;
      final String amPm = hour >= 12 ? 'PM' : 'AM';
      final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final String hourStr = hour12.toString().padLeft(2, '0');
      final String minuteStr = estSelesai.minute.toString().padLeft(2, '0');
      return '${estSelesai.day} ${months[estSelesai.month - 1]} ${estSelesai.year}, $hourStr:$minuteStr $amPm';
    } catch (_) {
      return _formatDate(baseDateStr);
    }
  }

  Future<void> _downloadQRIS(BuildContext context, String qrisData) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.currentLang == 'en' ? 'Downloading QRIS...' : 'Mengunduh QRIS...',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: navyColor,
          ),
        );
      }

      final url = Uri.parse('https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$qrisData');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: "QRIS_WISHWASH_${widget.order['id_order']}",
        );

        if (mounted) {
          if (result != null && result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  TranslationService.currentLang == 'en' 
                      ? 'QRIS successfully saved to Gallery!' 
                      : 'QRIS berhasil disimpan ke Galeri!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.green.shade700,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  TranslationService.currentLang == 'en'
                      ? 'Failed to save QRIS. Grant storage permission.'
                      : 'Gagal menyimpan QRIS. Berikan izin penyimpanan.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to download QR code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = TranslationService.currentLang == 'en';
    final String orderId = widget.order['kode_order'] != null && widget.order['kode_order'].toString().isNotEmpty
        ? widget.order['kode_order'].toString()
        : 'WW-${widget.order['id_order']}';

    final qrisData = 'WISHWASH_PAYMENT_ORDER_$orderId';
    
    // Receipt Details
    final orderDate = _formatDate(widget.order['tgl_pesanan']);
    final pelanggan = widget.order['Pelanggan'] ?? {};
    final String customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
    final String customerPhone = (pelanggan['no_telp'] ?? pelanggan['NoTelp'] ?? pelanggan['no_hp'] ?? '-').toString();
    
    final logistikType = widget.order['tipe_logistik'] ?? 'Courier Delivery';
    final bool isDropOff = logistikType == 'Drop-off';

    final alamatPengambilan = widget.order['AlamatPengambilan'] ?? {};
    final String pickupAddr = alamatPengambilan['alamat_lengkap'] ?? '-';

    final alamatPenyerahan = widget.order['AlamatPenyerahan'];
    final String deliveryAddr = (alamatPenyerahan != null && alamatPenyerahan['alamat_lengkap'] != null)
        ? alamatPenyerahan['alamat_lengkap'].toString()
        : (isEn ? 'Not specified yet' : 'Belum ditentukan');

    final String patokanLokasi = widget.order['keterangan_lokasi'] != null && widget.order['keterangan_lokasi'].toString().trim().isNotEmpty
        ? widget.order['keterangan_lokasi'].toString().trim()
        : '-';

    final layanan = widget.order['Layanan'] ?? {};
    final String mainService = TranslationService.translateService(layanan['nama_layanan'] ?? 'Layanan Laundry');

    final double kuantitas = (widget.order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final double hargaPerSatuan = (layanan['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final double subtotalCucian = kuantitas * hargaPerSatuan;
    final paketLayanan = widget.order['PaketLayanan'] ?? {};
    final double biayaTambahan = (paketLayanan['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;
    final String packageName = paketLayanan['nama_paket'] ?? 'Reguler';
    final parfum = widget.order['Parfum'] ?? {};
    final String perfumeName = parfum['nama_parfum'] ?? 'Lavender Bliss';

    final String weightText = kuantitas == 0.0
        ? (isEn ? 'Pending Weight' : 'Menunggu Timbang')
        : '$kuantitas kg';

    final pembayaran = widget.order['Pembayaran'];
    final String paymentStatusLabel = pembayaran != null && pembayaran['status_pembayaran'] != null
        ? (pembayaran['status_pembayaran'] == 'Lunas' ? (isEn ? 'Paid' : 'Lunas') : (isEn ? 'Unpaid' : 'Belum Lunas'))
        : (isEn ? 'Unpaid' : 'Belum Lunas');

    final String estDateText = _getEstSelesaiDate(widget.order);

    final karyawan = widget.order['Karyawan'];
    final String employeeName = karyawan != null && karyawan['nama_karyawan'] != null
        ? karyawan['nama_karyawan'].toString()
        : (isEn ? 'Assigning Courier...' : 'Menunggu Kurir...');

    final String paymentMethod = pembayaran != null && pembayaran['metode_bayar'] != null
        ? pembayaran['metode_bayar'].toString()
        : widget.paymentMethod;

    final String paymentRef = pembayaran != null && pembayaran['referensi_bayar'] != null && pembayaran['referensi_bayar'].toString().trim().isNotEmpty
        ? pembayaran['referensi_bayar'].toString().trim()
        : '-';

    final String? catatan = widget.order['catatan_order'];

    final Color charBlack = const Color(0xFF2D3748);
    final Color slateGray = const Color(0xFF718096);

    return Scaffold(
      backgroundColor: const Color(0xFFBCEFF2),
      body: Column(
        children: [
          // --- HEADER & APPBAR ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    isEn ? 'Payment' : 'Pembayaran',
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
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FBFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 120), // Extra bottom padding for sticky button
                  children: [
                  // QRIS Section Title
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
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.network(
                        'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$qrisData',
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
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadQRIS(context, qrisData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5E9), // Light Green
                        foregroundColor: const Color(0xFF2E7D32), // Dark Green
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        isEn ? 'Download QRIS' : 'Unduh QRIS',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Receipt Section Title
                  Row(
                    children: [
                      Text(
                        isEn ? 'Transaction Receipt' : 'Resi Transaksi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: navyColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: navyColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // PAPER SLIP RECEIPT CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Receipt Header Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WISHWASH LAUNDRY',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: charBlack,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Order #$orderId',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0C4B8E),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    orderDate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: slateGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                               Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200, width: 1),
                                    ),
                                    child: Text(
                                      paymentStatusLabel,
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Paper slip details
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildReceiptRow(isEn ? 'Customer' : 'Pelanggan', customerName),
                              _buildReceiptRow(isEn ? 'Phone Number' : 'No. Telepon', customerPhone),
                              _buildReceiptRow(isEn ? 'Service Type' : 'Jenis Layanan', mainService),
                              _buildReceiptRow(isEn ? 'Estimated Finish' : 'Estimasi Selesai', estDateText),
                              _buildReceiptRow(isEn ? 'Weight' : 'Berat Cucian', weightText),
                              _buildReceiptRow(isEn ? 'Package & Perfume' : 'Paket & Pewangi', '$packageName - $perfumeName'),
                              if (!isDropOff)
                                _buildReceiptRow(isEn ? 'Pickup Address' : 'Alamat Jemput', pickupAddr),
                              _buildReceiptRow(isEn ? 'Delivery Address' : 'Alamat Antar', deliveryAddr),
                              if (patokanLokasi != '-')
                                _buildReceiptRow(isEn ? 'Location Notes' : 'Patokan Lokasi', patokanLokasi),
                              _buildReceiptRow(
                                isEn ? 'Logistics Method' : 'Metode Logistik', 
                                logistikType.toLowerCase().contains('drop')
                                    ? 'Drop-off'
                                    : (isEn ? 'Courier Delivery' : 'Pengiriman Kurir'),
                              ),
                              _buildReceiptRow(isEn ? 'Courier / Worker' : 'Kurir / Petugas', employeeName),
                              _buildReceiptRow(isEn ? 'Payment Method' : 'Metode Pembayaran', paymentMethod),
                              _buildReceiptRow(
                                isEn ? 'Payment Status' : 'Status Pembayaran', 
                                paymentStatusLabel,
                                isStatus: true,
                                statusColor: paymentStatusLabel == 'Lunas' || paymentStatusLabel == 'Paid' ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                              if (paymentRef != '-')
                                _buildReceiptRow(isEn ? 'Transaction Ref' : 'Ref. Transaksi', paymentRef),
                              if (catatan != null && catatan.trim().isNotEmpty)
                                _buildReceiptRow(isEn ? 'Note / Instruction' : 'Catatan Khusus', catatan),
                              
                              _buildDashedDivider(),

                              _buildPriceRow(
                                isEn ? 'Subtotal (Laundry)' : 'Subtotal (Cucian)',
                                _formatRupiah(subtotalCucian),
                                detailText: kuantitas > 0.0
                                    ? '${kuantitas.toStringAsFixed(1)} kg x ${_formatRupiah(hargaPerSatuan)}/kg'
                                    : (isEn ? 'Pending Weight' : 'Menunggu Timbang'),
                                isBoldLabel: false,
                              ),
                              const SizedBox(height: 8),
                              _buildPriceRow(
                                isEn ? 'Package Surcharge' : 'Biaya Paket',
                                _formatRupiah(biayaTambahan),
                                detailText: packageName,
                                isBoldLabel: false,
                              ),
                              const SizedBox(height: 8),
                              _buildPriceRow(
                                isEn ? 'Promo Discount' : 'Diskon Promo',
                                widget.promoDiscount > 0.0
                                    ? '- ${_formatRupiah(widget.promoDiscount)}'
                                    : _formatRupiah(0.0),
                                isBoldLabel: false,
                                textColor: widget.promoDiscount > 0.0 ? Colors.red.shade700 : charBlack,
                              ),
                              _buildDashedDivider(),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isEn ? 'TOTAL AMOUNT' : 'TOTAL BAYAR',
                                    style: GoogleFonts.poppins(
                                      color: charBlack,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(widget.totalTagihan),
                                    style: GoogleFonts.poppins(
                                      color: charBlack,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              Center(
                                child: Column(
                                  children: [
                                    BarcodeWidget(
                                      barcode: Barcode.code128(),
                                      data: 'Order#$orderId',
                                      drawText: false,
                                      height: 75,
                                      width: double.infinity,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isEn ? '*Show this receipt when picking up your order' : '*Tunjukkan kuitansi ini saat pengambilan cucian Anda',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: slateGray,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(color: Colors.grey.shade200, thickness: 1),
                                    const SizedBox(height: 6),
                                    Text(
                                      isEn
                                          ? 'TERMS & CONDITIONS:\n1. Claims for complaints must be submitted within 24h after receiving clothes and accompanied by this receipt.\n2. Clothes not picked up within 30 days are beyond the responsibility of management.'
                                          : 'SYARAT & KETENTUAN:\n1. Klaim keluhan wajib diajukan maks. 24 jam setelah pakaian diterima dengan menyertakan resi ini.\n2. Pakaian yang tidak diambil dalam 30 hari di luar tanggung jawab manajemen.',
                                      textAlign: TextAlign.left,
                                      style: GoogleFonts.poppins(
                                        color: slateGray.withValues(alpha: 0.8),
                                        fontSize: 8,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
             ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: navyColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: navyColor.withValues(alpha: 0.4),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEn ? 'Downloading Receipt PDF...' : 'Mengunduh Kuitansi PDF...'),
                  backgroundColor: navyColor,
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined),
            label: Text(
              isEn ? 'Download Receipt' : 'Unduh Kuitansi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
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
            color: navyColor.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isStatus = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF718096),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: isStatus ? (statusColor ?? const Color(0xFF2D3748)) : const Color(0xFF2D3748),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          const dashHeight = 1.2;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.grey.shade300),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String price, {
    bool isTotal = false,
    bool isBoldLabel = true,
    String? detailText,
    Color? textColor,
  }) {
    final Color charBlack = const Color(0xFF2D3748);
    final Color slateGray = const Color(0xFF718096);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: textColor ?? charBlack,
                    fontWeight: isTotal || isBoldLabel ? FontWeight.bold : FontWeight.w500,
                    fontSize: isTotal ? 14 : 12,
                  ),
                ),
                if (detailText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detailText,
                    style: GoogleFonts.poppins(
                      color: slateGray,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            price,
            style: GoogleFonts.poppins(
              color: textColor ?? charBlack,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
