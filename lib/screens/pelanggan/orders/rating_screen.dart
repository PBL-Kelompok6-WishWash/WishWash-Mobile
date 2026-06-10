import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/penilaian_service.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/widgets/loading_overlay.dart';

class RatingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const RatingScreen({super.key, required this.order});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgGrey = const Color(0xFFF8FBFC);

  int bintangOverall = 0;
  int bintangLayanan = 0;
  int bintangKurir = 0;
  int bintangKecepatan = 0;
  final TextEditingController ulasanController = TextEditingController();
  bool isSubmitting = false;

  void _showSuccessAutoDismissDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded, 
                      color: Color(0xFF2E7D32), 
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorAutoDismissDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded, 
                      color: Color(0xFFD32F2F), 
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Future<void> _submitRating() async {
    final isEn = TranslationService.currentLang == 'en';
    if (bintangOverall == 0 || bintangLayanan == 0 || bintangKurir == 0 || bintangKecepatan == 0) {
      _showErrorAutoDismissDialog(
        isEn
            ? 'Please give a star rating for all categories!'
            : 'Silakan berikan ulasan bintang untuk semua kategori!',
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await PenilaianService.rateOrder(
        orderId: widget.order['id_order'],
        bintang: bintangOverall,
        bintangLayanan: bintangLayanan,
        bintangKurir: bintangKurir,
        bintangKecepatan: bintangKecepatan,
        ulasan: ulasanController.text.trim(),
      );

      // Fetch fresh order details
      final freshOrder = await OrderService.getOrderById(widget.order['id_order']);

      if (mounted) {
        _showSuccessAutoDismissDialog(
          isEn ? 'Thank you for your rating!' : 'Terima kasih atas penilaian Anda!',
        );
        Future.delayed(const Duration(milliseconds: 2100), () {
          if (mounted) {
            Navigator.pop(context, freshOrder); // Go back and return updated order data
          }
        });
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      if (mounted) {
        _showErrorAutoDismissDialog('Failed: $e');
      }
    }
  }

  Widget _buildStarSelector(String title, int currentValue, Function(int) onSelected, {bool isLarge = false}) {
    final isEn = TranslationService.currentLang == 'en';
    return Column(
      crossAxisAlignment: isLarge ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (isLarge)
          Center(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: navyColor,
              ),
            ),
          )
        else
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: navyColor,
            ),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: isLarge ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: isLarge ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: List.generate(5, (index) {
                final starVal = index + 1;
                final isSelected = starVal <= currentValue;
                return GestureDetector(
                  onTap: () => onSelected(starVal),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeIn,
                    margin: const EdgeInsets.only(right: 6.0),
                    transform: Matrix4.identity()..scale(isSelected ? 1.05 : 0.95),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected ? Colors.amber : Colors.grey.shade400,
                      size: isLarge ? 54 : 38,
                    ),
                  ),
                );
              }),
            ),
            if (!isLarge)
              Text(
                currentValue == 0
                    ? (isEn ? 'Tap to rate' : 'Pilih rating')
                    : currentValue == 5
                        ? (isEn ? 'Excellent!' : 'Sangat Bagus!')
                        : currentValue == 4
                            ? (isEn ? 'Good' : 'Bagus')
                            : currentValue == 3
                                ? (isEn ? 'Average' : 'Cukup')
                                : currentValue == 2
                                    ? (isEn ? 'Poor' : 'Kurang')
                                    : (isEn ? 'Very Bad' : 'Sangat Kurang'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: currentValue == 0 ? Colors.grey.shade500 : cyanColor,
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = TranslationService.currentLang == 'en';
    
    // Extract Order details
    final String orderId = widget.order['kode_order'] != null && widget.order['kode_order'].toString().isNotEmpty
        ? widget.order['kode_order'].toString()
        : 'WW-${widget.order['id_order']}';
    
    final layanan = widget.order['Layanan'] ?? {};
    final String rawServiceName = layanan['nama_layanan'] ?? 'Layanan Laundry';
    final String serviceName = TranslationService.translateService(rawServiceName);
    
    final baseColor = _getServiceColor(rawServiceName);
    final orderColor = _getDarkenedTextColor(baseColor);
    
    final double kuantitas = (widget.order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final statusInfo = _getCurrentStatusInfo(widget.order);
    
    final String rawStatus = (statusInfo['raw_status'] ?? '').toString().toLowerCase();
    final bool isCancelled = rawStatus.contains('batal') || rawStatus.contains('cancel') || rawStatus.contains('tolak') || rawStatus.contains('reject');
    final String qtyStr = kuantitas > 0.0
        ? '$kuantitas kg'
        : (isCancelled
            ? ''
            : (rawStatus.contains('diterima') || rawStatus.contains('received')
                ? (isEn ? 'Awaiting Confirmation' : 'Menunggu Konfirmasi')
                : (rawStatus.contains('jemput') || rawStatus.contains('pickup') || rawStatus.contains('penjemputan')
                    ? (isEn ? 'Awaiting Pickup' : 'Menunggu Dijemput')
                    : (isEn ? 'Pending Weight' : 'Menunggu Timbang'))));
                
    final estDate = _getEstSelesaiDate(widget.order);
    final double totalBayar = (widget.order['total_bayar'] as num?)?.toDouble() ?? 0.0;
    final price = _formatRupiah(totalBayar);
    String cancelTime = '-';
    if (isCancelled) {
      final historyList = widget.order['RiwayatStatusDetail'];
      if (historyList != null && historyList is List && historyList.isNotEmpty) {
        List<dynamic> sortedHistory = List.from(historyList);
        sortedHistory.sort((a, b) => (a['id_riwayat_status_detail'] as num? ?? 0).compareTo(b['id_riwayat_status_detail'] as num? ?? 0));
        final rawTime = sortedHistory.last['waktu_update'] ?? sortedHistory.last['WaktuUpdate'];
        if (rawTime != null) {
          cancelTime = _formatDate(rawTime.toString());
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFBCEFF2),
      extendBody: true,
      body: LoadingOverlay(
        isLoading: isSubmitting,
        child: Column(
          children: [
          // WishWash Page style AppBar/Header (matching CreateOrderScreen)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: navyColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      isEn ? 'Rate & Review' : 'Rating & Ulasan',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 48), // Balancing spacer
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Main content container sheet
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FBFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Order Tracker Card (exact duplicate of list page/details)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(baseColor.withValues(alpha: 0.18), Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: orderColor.withValues(alpha: 0.4), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isEn ? 'Order #$orderId' : 'Pesanan #$orderId',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: orderColor,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (isCancelled || statusInfo['is_selesai'] == true) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCancelled
                                              ? const Color(0xFFFF3B30)
                                              : const Color(0xFF4CAF50),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isCancelled
                                              ? (isEn ? 'Cancelled' : 'Dibatalkan')
                                              : (isEn ? 'Completed' : 'Selesai'),
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        isEn ? 'Est: $estDate' : 'Estimasi: $estDate',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              serviceName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: orderColor,
                              ),
                            ),
                            if (qtyStr.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                qtyStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isCancelled ? Colors.red.shade700 : orderColor.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                             Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      price,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: orderColor.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (kuantitas > 0.0) ...[
                                      const SizedBox(width: 8),
                                      (() {
                                        final pembayaran = widget.order['Pembayaran'];
                                        final bool isLunas = pembayaran != null && pembayaran['status_pembayaran'] == 'Lunas';
                                        final Color capBg = isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
                                        final Color capText = isLunas ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
                                        final String capLabel = isLunas 
                                            ? (isEn ? 'Paid' : 'Lunas')
                                            : (isEn ? 'Unpaid' : 'Belum Lunas');
                                        
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: capBg,
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(color: capText.withValues(alpha: 0.2), width: 1),
                                          ),
                                          child: Text(
                                            capLabel,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: capText,
                                            ),
                                          ),
                                        );
                                      })(),
                                    ],
                                  ],
                                ),
                                if (statusInfo['is_selesai'] == true)
                                  Text(
                                    isEn
                                        ? 'Finished: ${_getCompletionTime(widget.order)}'
                                        : 'Selesai: ${_getCompletionTime(widget.order)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: orderColor.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else if (isCancelled)
                                  Text(
                                    isEn
                                        ? 'Cancelled: $cancelTime'
                                        : 'Dibatalkan: $cancelTime',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Stepper Tracker (Garis nyambung perfect)
                            (() {
                              final lang = TranslationService.currentLang;
                              final List<Map<String, dynamic>> refStatuses = statusInfo['statuses'];
                              final int activeIdx = statusInfo['active_index'];
                              final bool isSelesaiStatus = statusInfo['is_selesai'] == true;
                              final bool isOrderCancelled = rawStatus.contains('batal') || rawStatus.contains('cancel') || rawStatus.contains('tolak') || rawStatus.contains('reject');

                              List<Widget> steps = [];
                              for (int i = 0; i < refStatuses.length; i++) {
                                final rName = refStatuses[i]['nama_status'] ?? '';
                                final bool isDrop = widget.order['tipe_logistik'] == 'Drop-off' || widget.order['tipe_logistik'] == 'Self Pickup';
                                final String shortLabel = _getShortStatusLabel(
                                  rName,
                                  lang,
                                  isCancelled: isOrderCancelled,
                                  isDropOff: isDrop,
                                );
                                
                                final bool isCurrent = i == activeIdx && !isSelesaiStatus;
                                final bool isDone = (i < activeIdx) || (isSelesaiStatus && i == refStatuses.length - 1) || (i == 0 && activeIdx > 0);
                                final bool isActive = isDone || isCurrent;

                                steps.add(
                                  _buildStepItem(
                                    label: shortLabel,
                                    isActive: isActive,
                                    isDone: isDone,
                                    isCurrent: isCurrent,
                                    themeColor: orderColor,
                                    index: i,
                                    totalSteps: refStatuses.length,
                                    isCancelled: isOrderCancelled,
                                  ),
                                );
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: steps,
                              );
                            })(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Overall Rating Container
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              _buildStarSelector(
                                isEn ? 'Overall Rating' : 'Penilaian Keseluruhan',
                                bintangOverall,
                                (val) {
                                  setState(() {
                                    bintangOverall = val;
                                  });
                                },
                                isLarge: true,
                              ),
                              const SizedBox(height: 12),
                               Text(
                                bintangOverall == 0
                                    ? (isEn ? 'Choose star rating above' : 'Pilih jumlah bintang di atas')
                                    : bintangOverall == 5
                                        ? (isEn ? 'Excellent!' : 'Sangat Bagus!')
                                        : bintangOverall == 4
                                            ? (isEn ? 'Good' : 'Bagus')
                                            : bintangOverall == 3
                                                ? (isEn ? 'Average' : 'Cukup')
                                                : bintangOverall == 2
                                                    ? (isEn ? 'Poor' : 'Kurang')
                                                    : (isEn ? 'Very Bad' : 'Sangat Kurang'),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: bintangOverall == 0 ? Colors.grey.shade500 : cyanColor,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Detail Ratings Card
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              _buildStarSelector(
                                isEn ? 'Service Quality' : 'Kualitas Layanan',
                                bintangLayanan,
                                (val) => setState(() => bintangLayanan = val),
                              ),
                              const Divider(height: 28),
                              _buildStarSelector(
                                isEn ? 'Courier/Driver Performance' : 'Kinerja Kurir/Driver',
                                bintangKurir,
                                (val) => setState(() => bintangKurir = val),
                              ),
                              const Divider(height: 28),
                              _buildStarSelector(
                                isEn ? 'Delivery & Washing Speed' : 'Kecepatan Cuci & Pengantaran',
                                bintangKecepatan,
                                (val) => setState(() => bintangKecepatan = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Text Review Field
                      Text(
                        isEn ? 'Write a Comment' : 'Tulis Ulasan Anda',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: navyColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ulasanController,
                        maxLines: 4,
                        maxLength: 250,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: isEn
                              ? 'Describe your experience (optional)...'
                              : 'Ceritakan pengalaman Anda (opsional)...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: cyanColor, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: Container(
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [navyColor, cyanColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isSubmitting ? null : _submitRating,
              child: Text(
                isEn ? 'Submit Review' : 'Kirim Ulasan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helpers for exact active order tracker duplication ---

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final int hour = dt.hour;
      final String amPm = hour >= 12 ? 'PM' : 'AM';
      final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final String hourStr = hour12.toString().padLeft(2, '0');
      final String minuteStr = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hourStr:$minuteStr $amPm';
    } catch (_) {
      try {
        return isoString.split('T')[0];
      } catch (_) {
        return isoString;
      }
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
      final baseDate = DateTime.parse(baseDateStr).toLocal();
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
      return '-';
    }
  }

  String _formatRupiah(double value) {
    if (value == 0.0) {
      return 'Rp 0';
    }
    String valStr = value.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  Color _getServiceColor(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('lipat') || name.contains('dry clean')) {
      return const Color(0xFF00BCD4); // Cyan (#00BCD4)
    } else if (name.contains('kering') && !name.contains('lipat')) {
      return const Color(0xFF8BC34A); // Green (#8BC34A)
    } else if (name.contains('setrika') && (name.contains('cuci') || name.contains('wash'))) {
      return const Color(0xFF9C27B0); // Purple (#9C27B0)
    } else if (name.contains('setrika')) {
      return const Color(0xFFFFC107); // Yellow (#FFC107)
    }
    return const Color(0xFF00BCD4); // fallback Cyan
  }

  Color _getDarkenedTextColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.hue >= 160 && hsl.hue <= 210) {
      return const Color(0xFF0C4B8E); // Memaksa Navy untuk Cyan/Teal agar kontras tinggi
    }
    if (hsl.lightness > 0.45) {
      double targetLightness = 0.30;
      if (hsl.hue >= 45 && hsl.hue <= 65) {
        targetLightness = 0.25; // Warm Golden Amber for Yellow
      }
      return hsl.withLightness(targetLightness).toColor();
    }
    return color;
  }

  List<Map<String, dynamic>> _getSortedReferenceStatuses(Map<String, dynamic> order) {
    final layanan = order['Layanan'];
    final List<dynamic>? refList = layanan != null ? (layanan['referensi_status'] ?? layanan['ReferensiStatus']) : null;
    
    List<Map<String, dynamic>> sortedList = [];
    if (refList == null || refList.isEmpty) {
      sortedList = [
        {'nama_status': 'Pesanan Diterima', 'urutan_tahap': 1},
        {'nama_status': 'Penjemputan', 'urutan_tahap': 2},
        {'nama_status': 'Proses Timbang', 'urutan_tahap': 3},
        {'nama_status': 'Proses Cuci', 'urutan_tahap': 4},
        {'nama_status': 'Proses Kering', 'urutan_tahap': 5},
        {'nama_status': 'Proses Lipat', 'urutan_tahap': 6},
        {'nama_status': 'Siap Diantar', 'urutan_tahap': 7},
        {'nama_status': 'Selesai', 'urutan_tahap': 8},
      ];
    } else {
      final temp = refList.map((e) => Map<String, dynamic>.from(e)).toList();
      temp.sort((a, b) {
        final int seqA = a['urutan_tahap'] as int? ?? 0;
        final int seqB = b['urutan_tahap'] as int? ?? 0;
        return seqA.compareTo(seqB);
      });

      sortedList.add({'nama_status': 'Pesanan Diterima', 'urutan_tahap': 1});
      for (int i = 0; i < temp.length; i++) {
        final item = temp[i];
        final name = (item['nama_status'] ?? '').toString();
        final nameLower = name.toLowerCase();
        if (nameLower.contains('diterima') || nameLower.contains('received') ||
            nameLower.contains('batal') || nameLower.contains('cancel') ||
            nameLower.contains('tolak') || nameLower.contains('reject')) {
          continue;
        }
        sortedList.add({
          'id_referensi_status_layanan': item['id_referensi_status_layanan'],
          'nama_status': name,
          'urutan_tahap': sortedList.length + 1,
        });
      }
    }

    final bool hasPickup = (order['id_alamat_pengambilan'] != null && order['id_alamat_pengambilan'] != 0) ||
        (order['AlamatPengambilan'] != null && order['AlamatPengambilan']['id_alamat'] != null && order['AlamatPengambilan']['id_alamat'] != 0);
    if (!hasPickup) {
      sortedList.removeWhere((element) {
        final name = (element['nama_status'] ?? '').toString().toLowerCase();
        return name.contains('jemput') || name.contains('pickup') || name.contains('penjemputan');
      });
    }

    return sortedList;
  }

  Map<String, dynamic> _getCurrentStatusInfo(Map<String, dynamic> order) {
    final List<Map<String, dynamic>> refStatuses = _getSortedReferenceStatuses(order);
    
    final historyList = order['RiwayatStatusDetail'];
    if (historyList == null || historyList is! List || historyList.isEmpty) {
      final String rawStatus = refStatuses.isNotEmpty ? refStatuses.first['nama_status'] : 'Pesanan Diterima';
      final int initialActiveIndex = refStatuses.length > 1 ? 1 : 0;
      return {
        'nama_status': TranslationService.translateStatus(rawStatus),
        'raw_status': rawStatus,
        'active_index': initialActiveIndex,
        'statuses': refStatuses,
        'is_selesai': false,
      };
    }

    List<dynamic> sortedHistory = List.from(historyList);
    sortedHistory.sort((a, b) {
      final idA = a['id_riwayat_status_detail'] as num? ?? 0;
      final idB = b['id_riwayat_status_detail'] as num? ?? 0;
      return idA.compareTo(idB);
    });

    final latestHistory = sortedHistory.last;
    final refStatus = latestHistory['ReferensiStatus'];
    if (refStatus == null || refStatus is! Map) {
      final String rawStatus = refStatuses.isNotEmpty ? refStatuses.first['nama_status'] : 'Pesanan Diterima';
      final int initialActiveIndex = refStatuses.length > 1 ? 1 : 0;
      return {
        'nama_status': TranslationService.translateStatus(rawStatus),
        'raw_status': rawStatus,
        'active_index': initialActiveIndex,
        'statuses': refStatuses,
        'is_selesai': false,
      };
    }

    final String rawStatus = refStatus['nama_status'] ?? 'Pesanan Diterima';
    final translatedStatus = TranslationService.translateStatus(rawStatus);
    
    int activeIndex = 0;
    final idRef = refStatus['id_referensi_status_layanan'];
    if (idRef != null) {
      for (int i = 0; i < refStatuses.length; i++) {
        if (refStatuses[i]['id_referensi_status_layanan'] == idRef) {
          activeIndex = i;
          break;
        }
      }
    } else {
      final String lowerRaw = rawStatus.toLowerCase().trim();
      for (int i = 0; i < refStatuses.length; i++) {
        final String refName = (refStatuses[i]['nama_status'] ?? '').toString().toLowerCase().trim();
        if (refName == lowerRaw ||
            (lowerRaw.contains('diterima') && refName.contains('diterima')) ||
            (lowerRaw.contains('jemput') && refName.contains('jemput')) ||
            (lowerRaw.contains('timbang') && refName.contains('timbang')) ||
            (lowerRaw.contains('cuci') && refName.contains('cuci')) ||
            (lowerRaw.contains('kering') && refName.contains('kering')) ||
            (lowerRaw.contains('lipat') && refName.contains('lipat')) ||
            (lowerRaw.contains('setrika') && refName.contains('setrika')) ||
            (lowerRaw.contains('antar') && refName.contains('antar')) ||
            (lowerRaw.contains('selesai') && refName.contains('selesai'))) {
          activeIndex = i;
          break;
        }
      }
    }

    if (activeIndex == 0 && refStatuses.length > 1) {
      activeIndex = 0;
    }

    bool isCompletedByKaryawanOnly = false;
    if (historyList.isNotEmpty) {
      final latest = sortedHistory.last;
      final refStatusObj = latest['ReferensiStatus'];
      String latestStatusName = '';
      if (refStatusObj != null && refStatusObj is Map) {
        latestStatusName = (refStatusObj['nama_status'] ?? '').toString().toLowerCase();
      } else {
        latestStatusName = (latest['nama_status'] ?? '').toString().toLowerCase();
      }

      if (latestStatusName.contains('selesai') ||
          latestStatusName.contains('completed') ||
          latestStatusName.contains('success')) {
        final idKaryawan = latest['id_karyawan'] ?? latest['KaryawanID'];
        if (idKaryawan != null && (idKaryawan as num).toInt() > 0) {
          isCompletedByKaryawanOnly = true;
        }
      }
    }

    final bool isSelesai = (rawStatus.toLowerCase().contains('selesai') || 
                           rawStatus.toLowerCase().contains('completed') || 
                           rawStatus.toLowerCase().contains('success') || 
                           rawStatus.toLowerCase().contains('batal') || 
                           rawStatus.toLowerCase().contains('tolak') || 
                           rawStatus.toLowerCase().contains('reject')) &&
                           !isCompletedByKaryawanOnly;

    return {
      'nama_status': translatedStatus,
      'raw_status': rawStatus,
      'active_index': activeIndex,
      'statuses': refStatuses,
      'is_selesai': isSelesai,
      'is_waiting_customer_confirm': isCompletedByKaryawanOnly,
    };
  }

  String _getCompletionTime(Map<String, dynamic> order) {
    final historyList = order['RiwayatStatusDetail'];
    if (historyList != null && historyList is List && historyList.isNotEmpty) {
      dynamic completionEntry;
      for (var history in historyList) {
        final refStatus = history['ReferensiStatus'];
        if (refStatus != null && refStatus is Map) {
          final String statusName = (refStatus['nama_status'] ?? '').toString().toLowerCase();
          if (statusName.contains('selesai') ||
              statusName.contains('completed') ||
              statusName.contains('success') ||
              statusName.contains('batal') ||
              statusName.contains('cancel') ||
              statusName.contains('tolak') ||
              statusName.contains('reject')) {
            completionEntry = history;
            break;
          }
        }
      }
      final timeSource = completionEntry ?? historyList.last;
      final rawTime = timeSource['waktu_update'] ?? timeSource['WaktuUpdate'];
      if (rawTime != null) {
        return _formatDate(rawTime.toString());
      }
    }
    return '-';
  }

  String _getShortStatusLabel(String rawStatus, String lang, {bool isCancelled = false, bool isDropOff = false}) {
    final status = rawStatus.toLowerCase().trim();
    final isEn = lang == 'en';
    
    if (status.contains('diterima') || status.contains('received')) {
      return isEn ? 'Received' : 'Diterima';
    }
    if (status.contains('jemput') || status.contains('pickup') || status.contains('pick up') || status.contains('penjemputan')) {
      return isEn ? 'Pickup' : 'Jemput';
    }
    if (status.contains('timbang') || status.contains('weigh')) {
      return isEn ? 'Weigh' : 'Timbang';
    }
    if (status.contains('cuci') || status.contains('wash')) {
      return isEn ? 'Wash' : 'Cuci';
    }
    if (status.contains('kering') || status.contains('dry')) {
      return isEn ? 'Dry' : 'Kering';
    }
    if (status.contains('lipat') || status.contains('fold')) {
      return isEn ? 'Fold' : 'Lipat';
    }
    if (status.contains('setrika') || status.contains('iron')) {
      return isEn ? 'Iron' : 'Setrika';
    }
    if (status.contains('antar') || status.contains('ready') || status.contains('siap diantar')) {
      return isEn ? 'Ready' : (isDropOff ? 'Ambil' : 'Kirim');
    }
    if (status.contains('selesai') || status.contains('completed') || status.contains('success') || status.contains('done') || status.contains('batal') || status.contains('cancel') || status.contains('tolak') || status.contains('reject')) {
      if (isCancelled) {
        return isEn ? 'Cancelled' : 'Dibatalkan';
      }
      return isEn ? 'Done' : 'Selesai';
    }
    
    if (rawStatus.length > 7) {
      return rawStatus.substring(0, 7);
    }
    return rawStatus;
  }

  Widget _buildStepItem({
    required String label,
    required bool isActive,
    required bool isDone,
    required bool isCurrent,
    required Color themeColor,
    required int index,
    required int totalSteps,
    bool isCancelled = false,
  }) {
    final bool showLeftLine = index > 0;
    final bool showRightLine = index < totalSteps - 1;
    final Color leftLineColor = isCancelled
        ? Colors.red.shade400
        : (isDone || isCurrent ? themeColor : Colors.grey.shade300);
    final Color rightLineColor = isCancelled
        ? Colors.red.shade400
        : (isDone ? themeColor : Colors.grey.shade300);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 20,
            child: Stack(
              children: [
                if (showLeftLine)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(height: 2, color: leftLineColor),
                    ),
                  ),
                if (showRightLine)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(height: 2, color: rightLineColor),
                    ),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? const Color(0xFFFF3B30)
                          : (isDone ? themeColor : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCancelled
                            ? const Color(0xFFFF3B30)
                            : (isActive ? themeColor : Colors.grey.shade300),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (isCurrent && !isCancelled)
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Center(
                      child: isCancelled
                          ? const Icon(Icons.close_rounded, size: 10, color: Colors.white)
                          : (isCurrent
                              ? Icon(Icons.circle, size: 8, color: themeColor)
                              : (isDone ? const Icon(Icons.check, size: 10, color: Colors.white) : const SizedBox.shrink())),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: isCancelled || isCurrent || isDone ? FontWeight.bold : FontWeight.normal,
                color: isCancelled
                    ? Colors.red.shade700
                    : (isActive ? themeColor : Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
