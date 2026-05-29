import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/screens/karyawan/orders/karyawan_tracking_screen.dart';
import 'package:mobile/utils/constants.dart';


class OrderDetailScreenKaryawan extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic>) onOrderUpdated;

  const OrderDetailScreenKaryawan({
    super.key,
    required this.order,
    required this.onOrderUpdated,
  });

  @override
  State<OrderDetailScreenKaryawan> createState() => _OrderDetailScreenKaryawanState();
}

class _OrderDetailScreenKaryawanState extends State<OrderDetailScreenKaryawan> {
  late Map<String, dynamic> _currentOrder;
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgGrey = const Color(0xFFF8FBFC);
  final Color softTeal = const Color(0xFFBCEFF2);
  bool _isDeliveryStarted = false;
  bool _isPickupStarted = false;

  @override
  void initState() {
    super.initState();
    // Salin data order lokal agar modifikasi state aman secara interaktif
    _currentOrder = Map<String, dynamic>.from(widget.order);
  }

  // --- KONSISTENSI DENGAN DETIL PESANAN PELANGGAN ---
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

    if (order['tipe_logistik'] == 'Drop-off') {
      sortedList.removeWhere((element) {
        final name = (element['nama_status'] ?? '').toString().toLowerCase();
        return name.contains('jemput') || name.contains('pickup') || name.contains('penjemputan');
      });
    }

    return sortedList;
  }

  String _getShortStatusLabel(String rawStatus, String lang, {bool isCancelled = false}) {
    String status = rawStatus.toLowerCase().trim();
    if (status.startsWith('proses ')) {
      status = status.replaceFirst('proses ', '').trim();
    }
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
      final bool isDropOff = _currentOrder['tipe_logistik'] == 'Drop-off';
      return isEn ? 'Ready' : (isDropOff ? 'Ambil' : 'Kirim');
    }
    if (status.contains('selesai') || status.contains('completed') || status.contains('success') || status.contains('done') || status.contains('batal') || status.contains('cancel') || status.contains('tolak') || status.contains('reject')) {
      if (isCancelled) {
        return isEn ? 'Cancelled' : 'Dibatalkan';
      }
      return isEn ? 'Done' : 'Selesai';
    }
    
    if (status.isNotEmpty) {
      return status[0].toUpperCase() + status.substring(1);
    }
    return rawStatus;
  }

  String _getOrderStatus(Map<String, dynamic> order) {
    final historyList = order['RiwayatStatusDetail'];
    if (historyList == null || historyList is! List || historyList.isEmpty) {
      final layanan = order['Layanan'];
      final refList = layanan != null ? (layanan['referensi_status'] ?? layanan['ReferensiStatus']) : null;
      if (layanan != null && refList != null && refList is List) {
        if (refList.isNotEmpty) {
          List<dynamic> sortedRef = List.from(refList);
          sortedRef.sort((a, b) => (a['urutan_tahap'] as int? ?? 0).compareTo(b['urutan_tahap'] as int? ?? 0));
          return sortedRef.first['nama_status'] ?? 'Pesanan Diterima';
        }
      }
      return 'Pesanan Diterima';
    }

    List<dynamic> sortedHistory = List.from(historyList);
    sortedHistory.sort((a, b) {
      final idA = a['id_riwayat_status_detail'] as num? ?? 0;
      final idB = b['id_riwayat_status_detail'] as num? ?? 0;
      return idA.compareTo(idB);
    });

    final latestHistory = sortedHistory.last;
    final refStatus = latestHistory['ReferensiStatus'];
    if (refStatus != null && refStatus is Map) {
      return refStatus['nama_status'] ?? 'Pesanan Diterima';
    }
    return 'Pesanan Diterima';
  }

  String _getPaymentStatus(Map<String, dynamic> order) {
    final pembayaran = order['Pembayaran'];
    if (pembayaran == null || pembayaran is! Map) {
      return 'Belum Lunas';
    }
    final status = pembayaran['status_pembayaran'] ?? 'Belum Lunas';
    if (status == 'Paid' || status == 'Lunas') {
      return 'Lunas';
    }
    return 'Belum Lunas';
  }

  Map<String, dynamic> _getCurrentStatusInfo(Map<String, dynamic> order) {
    final List<Map<String, dynamic>> refStatuses = _getSortedReferenceStatuses(order);
    final String currentStatus = _getOrderStatus(order);
    final String lowerCurrent = currentStatus.toLowerCase().trim();
    
    int activeIndex = 0;
    for (int i = 0; i < refStatuses.length; i++) {
      final String refName = (refStatuses[i]['nama_status'] ?? '').toString().toLowerCase().trim();
      
      // Flexible matching for both dynamic DB alur
      if (refName == lowerCurrent || 
          (lowerCurrent.contains('diterima') && refName.contains('diterima')) ||
          (lowerCurrent.contains('jemput') && refName.contains('jemput')) ||
          (lowerCurrent.contains('timbang') && refName.contains('timbang')) ||
          (lowerCurrent.contains('cuci') && refName.contains('cuci')) ||
          (lowerCurrent.contains('kering') && refName.contains('kering')) ||
          (lowerCurrent.contains('lipat') && refName.contains('lipat')) ||
          (lowerCurrent.contains('setrika') && refName.contains('setrika')) ||
          (lowerCurrent.contains('antar') && refName.contains('antar')) ||
          (lowerCurrent.contains('selesai') && refName.contains('selesai'))) {
        activeIndex = i;
        break;
      }
    }

    // If the order has status 'Pesanan Diterima', keep the active dot at index 0 (Diterima)
    if (activeIndex == 0 && refStatuses.length > 1) {
      activeIndex = 0;
    }

    final bool isSelesai = lowerCurrent.contains('selesai') || lowerCurrent.contains('completed');

    return {
      'nama_status': TranslationService.translateStatus(currentStatus),
      'raw_status': currentStatus,
      'active_index': activeIndex,
      'statuses': refStatuses,
      'is_selesai': isSelesai,
    };
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
      return _formatDate(baseDateStr);
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
      return const Color(0xFF0C4B8E); // Memaksa Navy untuk Cyan/Teal
    }
    if (hsl.lightness > 0.45) {
      double targetLightness = 0.30;
      if (hsl.hue >= 45 && hsl.hue <= 65) {
        targetLightness = 0.25; // Warm Golden Amber
      }
      return hsl.withLightness(targetLightness).toColor();
    }
    return color;
  }

  // --- PEMBARUAN STATUS KARYAWAN & SIMULASI INTERAKSI ---
  
  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    final isEn = TranslationService.currentLang == 'en';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [navyColor.withValues(alpha: 0.12), navyColor.withValues(alpha: 0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sync_rounded,
                    color: navyColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 10),
                // Content
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Buttons - stacked vertically
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Text(
                      isEn ? 'Yes, Update' : 'Ya, Perbarui',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isEn ? 'Cancel' : 'Batal',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog({
    required String title,
    required String content,
  }) {
    final isEn = TranslationService.currentLang == 'en';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: navyColor),
              ),
              const SizedBox(height: 10),
              Text(
                content,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isEn ? 'Done' : 'Selesai',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    final translatedStatus = TranslationService.translateStatus(newStatus);
    final isEn = TranslationService.currentLang == 'en';
    _showConfirmationDialog(
      title: isEn ? 'Confirm Status Change' : 'Konfirmasi Perubahan Status',
      content: isEn
          ? 'Are you sure you want to update the order status to "$translatedStatus"?'
          : 'Apakah Anda yakin ingin memperbarui status pesanan menjadi "$translatedStatus"?',
      onConfirm: () async {
        try {
          final updatedOrder = await OrderService.updateOrder(
            _currentOrder['id_order'],
            {'status': newStatus},
          );
          if (mounted) {
            setState(() {
              _currentOrder = Map<String, dynamic>.from(updatedOrder);
            });
            widget.onOrderUpdated(_currentOrder);

            _showSuccessDialog(
              title: isEn ? 'Status Updated Successfully' : 'Status Berhasil Diperbarui',
              content: isEn
                  ? 'Order status has been successfully updated to "$translatedStatus".'
                  : 'Status pesanan berhasil diperbarui ke "$translatedStatus".',
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEn ? 'Failed to update status: $e' : 'Gagal memperbarui status: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _markAsPaid() async {
    final isEn = TranslationService.currentLang == 'en';
    try {
      final updatedOrder = await OrderService.updateOrder(
        _currentOrder['id_order'],
        {
          'status_pembayaran': 'Lunas',
          'metode_bayar': 'Cash',
        },
      );
      if (mounted) {
        setState(() {
          _currentOrder = Map<String, dynamic>.from(updatedOrder);
        });
        widget.onOrderUpdated(_currentOrder);

        _showSuccessDialog(
          title: isEn ? 'Payment Successful!' : 'Pembayaran Lunas!',
          content: isEn
              ? 'This order has been successfully marked as PAID.'
              : 'Pesanan ini telah berhasil ditandai sebagai LUNAS.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? 'Failed to record payment: $e' : 'Gagal mencatat pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitWeightAndStatus(double weight, double totalBayar, String status) async {
    final isEn = TranslationService.currentLang == 'en';
    try {
      final updatedOrder = await OrderService.updateOrder(
        _currentOrder['id_order'],
        {
          'kuantitas': weight,
          'total_bayar': totalBayar,
          'status': status,
        },
      );
      if (mounted) {
        setState(() {
          _currentOrder = Map<String, dynamic>.from(updatedOrder);
        });
        widget.onOrderUpdated(_currentOrder);

        _showSuccessDialog(
          title: isEn ? 'Weighing Successful' : 'Timbangan Berhasil',
          content: isEn 
              ? 'Laundry successfully weighed ($weight kg) and status updated to "${TranslationService.translateStatus(status)}".'
              : 'Cucian berhasil ditimbang ($weight kg) dan status diperbarui ke "${TranslationService.translateStatus(status)}".',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? 'Failed to update weighing data: $e' : 'Gagal memperbarui data timbangan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTolakPesananDialog() {
    final reasonController = TextEditingController();
    final bool isEn = TranslationService.currentLang == 'en';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFFF3B30),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isEn ? 'Reject Order?' : 'Tolak Pesanan?',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEn 
                      ? 'Enter the reason why this order is rejected'
                      : 'Masukkan alasan mengapa pesanan ini ditolak',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: isEn ? 'Write the rejection reason here...' : 'Tulis alasan penolakan di sini...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: navyColor, width: 2),
                    ),
                    filled: true,
                    fillColor: navyColor.withValues(alpha: 0.04),
                  ),
                  style: GoogleFonts.poppins(fontSize: 13, color: navyColor),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEn ? 'Please enter a rejection reason!' : 'Harap masukkan alasan penolakan!'
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      
                      try {
                        final updatedOrder = await OrderService.updateOrder(
                          _currentOrder['id_order'],
                          {
                            'status': 'Dibatalkan',
                            'catatan_order': 'Ditolak: $reason',
                          },
                        );
                        if (mounted) {
                           setState(() {
                            _currentOrder = Map<String, dynamic>.from(updatedOrder);
                          });
                          widget.onOrderUpdated(_currentOrder);
                          _showSuccessDialog(
                            title: isEn ? 'Order Rejected' : 'Pesanan Ditolak',
                            content: isEn
                                ? 'The order has been successfully rejected with reason: "$reason"'
                                : 'Pesanan telah berhasil ditolak dengan alasan: "$reason"',
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEn ? 'Failed to reject order: $e' : 'Gagal menolak pesanan: $e'
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(
                      isEn ? 'Yes, Reject Order' : 'Ya, Tolak Pesanan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isEn ? 'Cancel' : 'Batal',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWeighingDialog() {
    final textController = TextEditingController();
    final double hargaPerKg = (_currentOrder['Layanan']['harga_per_satuan'] as num).toDouble();
    final double biayaTambahan = (_currentOrder['PaketLayanan']['biaya_tambahan'] as num).toDouble();
    final String namaPaket = (_currentOrder['PaketLayanan']['nama_paket'] as String?) ?? 'Paket Laundry';
    final isEn = TranslationService.currentLang == 'en';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double? previewWeight = double.tryParse(textController.text.replaceAll(',', '.'));
            double previewTotal = previewWeight != null && previewWeight > 0
                ? (previewWeight * hargaPerKg) + biayaTambahan
                : 0;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: navyColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Header
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [navyColor.withValues(alpha: 0.12), navyColor.withValues(alpha: 0.06)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.scale_rounded,
                        color: navyColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isEn ? 'Weigh Laundry' : 'Timbang Cucian',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEn ? 'Enter actual laundry weight in kilograms' : 'Masukkan berat cucian riil dalam kilogram',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // TextField
                    TextField(
                      controller: textController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: isEn ? 'Laundry Weight' : 'Berat Cucian',
                        labelStyle: GoogleFonts.poppins(color: navyColor),
                        suffixText: 'Kg',
                        suffixStyle: GoogleFonts.poppins(
                          color: navyColor,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: navyColor, width: 2),
                        ),
                        filled: true,
                        fillColor: navyColor.withValues(alpha: 0.04),
                      ),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: navyColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    // Info row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isEn ? 'Price/Kg' : 'Harga/Kg', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                              Text(_formatRupiah(hargaPerKg), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: navyColor)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isEn ? '$namaPaket Cost' : 'Biaya $namaPaket', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                              Text(_formatRupiah(biayaTambahan), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: navyColor)),
                            ],
                          ),
                          if (previewTotal > 0) ...[
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isEn ? 'Estimated Total' : 'Estimasi Total', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: navyColor)),
                                Text(
                                  _formatRupiah(previewTotal),
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final double? weight = double.tryParse(textController.text.replaceAll(',', '.'));
                          if (weight == null || weight <= 0.0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEn ? 'Please enter a valid weight number!' : 'Harap masukkan angka berat yang valid!')),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          final double computedTotal = (weight * hargaPerKg) + biayaTambahan;
                          
                          final List<Map<String, dynamic>> refStatuses = _getSortedReferenceStatuses(_currentOrder);
                          final int timbangIdx = refStatuses.indexWhere(
                            (element) => (element['nama_status'] ?? '').toString().toLowerCase().contains('timbang') ||
                                         (element['nama_status'] ?? '').toString().toLowerCase().contains('weigh')
                          );
                          String targetNextStatus = 'proses cuci'; // fallback
                          if (timbangIdx != -1 && timbangIdx < refStatuses.length - 1) {
                            targetNextStatus = (refStatuses[timbangIdx + 1]['nama_status'] ?? '').toString();
                          }
                          _submitWeightAndStatus(weight, computedTotal, targetNextStatus);
                        },
                        child: Text(
                          isEn ? 'Save & Process' : 'Simpan & Proses',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          isEn ? 'Cancel' : 'Batal',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String orderId = _currentOrder['kode_order'] != null && _currentOrder['kode_order'].toString().isNotEmpty
        ? _currentOrder['kode_order'].toString()
        : 'WW-${_currentOrder['id_order']}';

    final layanan = _currentOrder['Layanan'] ?? {};
    final String rawServiceName = layanan['nama_layanan'] ?? 'Layanan Laundry';
    final double kuantitas = (_currentOrder['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String qtyStr = kuantitas == 0.0
        ? (TranslationService.currentLang == 'en' ? ' (Pending Weight)' : ' (Menunggu Timbang)')
        : ' ($kuantitas kg)';
    final serviceName = '${TranslationService.translateService(rawServiceName)}$qtyStr';
    final baseColor = _getServiceColor(rawServiceName);
    final orderColor = _getDarkenedTextColor(baseColor);

    final double totalBayar = (_currentOrder['total_bayar'] as num?)?.toDouble() ?? 0.0;
    final double hargaPerSatuan = (layanan['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final double subtotalCucian = kuantitas * hargaPerSatuan;
    final paketLayanan = _currentOrder['PaketLayanan'] ?? {};
    final double biayaTambahan = (paketLayanan['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;

    // Diskon Promo
    final List<dynamic> promoOrders = _currentOrder['PromoOrder'] ?? [];
    double promoDiscount = 0.0;
    if (promoOrders.isNotEmpty) {
      final promoOrderObj = promoOrders.first;
      final promo = promoOrderObj['Promo'] ?? {};
      if (promo.isNotEmpty) {
        final String tipePromo = promo['tipe_promo'] ?? 'Nominal';
        final double nominalPotongan = (promo['nominal_potongan'] as num?)?.toDouble() ?? 0.0;
        final double maksimalPotongan = (promo['maksimal_potongan'] as num?)?.toDouble() ?? 0.0;
        
        if (tipePromo.toLowerCase().contains('persen')) {
          promoDiscount = subtotalCucian * (nominalPotongan / 100);
          if (maksimalPotongan > 0.0 && promoDiscount > maksimalPotongan) {
            promoDiscount = maksimalPotongan;
          }
        } else {
          promoDiscount = nominalPotongan;
        }
      }
    }

    final double computedTotal = subtotalCucian + biayaTambahan - promoDiscount;
    final double totalTagihan = kuantitas > 0.0 
        ? (computedTotal > 0.0 ? computedTotal : 0.0)
        : 0.0;
    final priceStr = _formatRupiah(totalTagihan);
    final estDate = _getEstSelesaiDate(_currentOrder);
    final orderDate = _formatDate(_currentOrder['tgl_pesanan']);

    final statusInfo = _getCurrentStatusInfo(_currentOrder);
    final String currentStatus = statusInfo['nama_status'];

    final pelanggan = _currentOrder['Pelanggan'] ?? {};
    final String customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
    final String customerPhone = (pelanggan['no_telp'] ?? pelanggan['no_hp'] ?? pelanggan['NoTelp'] ?? pelanggan['NoHp'] ?? pelanggan['noTelp'] ?? '-').toString();

    final alamatPengambilan = _currentOrder['AlamatPengambilan'] ?? {};
    final String pickupAddr = alamatPengambilan['alamat_lengkap'] ?? '-';
    
    final alamatPenyerahan = _currentOrder['AlamatPenyerahan'];
    final String deliveryAddr = (alamatPenyerahan != null && alamatPenyerahan['alamat_lengkap'] != null)
        ? alamatPenyerahan['alamat_lengkap'].toString()
        : (TranslationService.currentLang == 'en' ? 'Not specified yet' : 'Belum ditentukan');

    final parfum = _currentOrder['Parfum'] ?? {};
    final String perfumeName = parfum['nama_parfum'] ?? 'Lavender Bliss';
    final String packageName = paketLayanan['nama_paket'] ?? 'Reguler';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBCEFF2),
              Color(0xFFF8FBFC),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- APP BAR LENGKAP ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: navyColor,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      TranslationService.currentLang == 'en' ? 'Order Detail' : 'Detail Pesanan',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    // Tombol chat diposisikan di pojok kanan AppBar untuk kepraktisan Kurir/Kasir
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: navyColor,
                        size: 22,
                      ),
                      onPressed: () => _openCustomerChat(customerName),
                    ),
                  ],
                ),
              ),
              
              // --- SCROLL CONTENT ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Progress Card (Desain & Horizontal Stepper Persis Punya Pelanggan)
                      (() {
                        final bool isCancelled = currentStatus.toLowerCase().contains('batal') || currentStatus.toLowerCase().contains('tolak') || currentStatus.toLowerCase().contains('reject');
                        return _buildProgressCard(
                          order: _currentOrder,
                          orderId: orderId,
                          serviceName: serviceName,
                          price: priceStr,
                          estDate: estDate,
                          statusInfo: statusInfo,
                          baseColor: baseColor,
                          orderColor: orderColor,
                          currentStatus: currentStatus,
                          isCancelled: isCancelled,
                        );
                      })(),
                      const SizedBox(height: 16),

                      // 2. Customer Information Card (Eksklusif Karyawan - Menggunakan tombol pesan/chat, BUKAN telp)
                      _buildCustomerCard(pelanggan),
                      const SizedBox(height: 16),

                      // 3. Schedule Details Card (Sama Persis Punya Pelanggan)
                      _buildScheduleCard(
                        pickupDate: estDate,
                        pickupAddr: pickupAddr,
                        deliveryAddr: deliveryAddr,
                        logistikType: _currentOrder['tipe_logistik'] ?? 'Courier Delivery',
                        navyColor: navyColor,
                      ),
                      const SizedBox(height: 24),

                      // 4. Clean Order Preview Card (Tinjau Pesanan) with Slide-Up Receipt Modal Button
                      _buildReviewOrderCard(
                        mainService: TranslationService.translateService(rawServiceName),
                        packageName: packageName,
                        perfumeName: perfumeName,
                        pickupAddr: pickupAddr,
                        deliveryAddr: deliveryAddr,
                        pickupDate: estDate,
                        logistikType: _currentOrder['tipe_logistik'] ?? 'Courier Delivery',
                        isEn: TranslationService.currentLang == 'en',
                        hargaPerSatuan: hargaPerSatuan,
                        biayaTambahan: biayaTambahan,
                        catatan: _currentOrder['catatan_order'] ?? '',
                        orderDate: orderDate,
                        estDate: estDate,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Sticky footer action buttons khusus Karyawan
      bottomSheet: _buildStickyActionFooter(),
    );
  }

  // --- PEMBUATAN WIDGETS DETAIL SECARA KONSISTEN & PREMIUM ---

  Widget _buildProgressCard({
    required Map<String, dynamic> order,
    required String orderId,
    required String serviceName,
    required String price,
    required String estDate,
    required Map<String, dynamic> statusInfo,
    required Color baseColor,
    required Color orderColor,
    required String currentStatus,
    bool isCancelled = false,
  }) {
    final bool isEn = TranslationService.currentLang == 'en';
    
    // Retrieve cancellation time if cancelled
    String cancelTime = '-';
    if (isCancelled) {
      final historyList = order['RiwayatStatusDetail'];
      if (historyList != null && historyList is List && historyList.isNotEmpty) {
        List<dynamic> sortedHistory = List.from(historyList);
        sortedHistory.sort((a, b) => (a['id_riwayat_status_detail'] as num? ?? 0).compareTo(b['id_riwayat_status_detail'] as num? ?? 0));
        cancelTime = _formatDate(sortedHistory.last['waktu_update'] ?? sortedHistory.last['WaktuUpdate']);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(baseColor.withValues(alpha: 0.18), Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? Colors.red.shade300.withValues(alpha: 0.7)
              : orderColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
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
                TranslationService.currentLang == 'en' ? 'Order #$orderId' : 'Pesanan #$orderId',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? Colors.red.shade800 : orderColor,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCancelled
                        ? (isEn ? 'Cancelled: $cancelTime' : 'Dibatalkan: $cancelTime')
                        : (isEn ? 'Est: $estDate' : 'Estimasi: $estDate'),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCancelled
                ? (isEn ? '${serviceName.split('(')[0].trim()} (Cancelled)' : '${serviceName.split('(')[0].trim()} (Dibatalkan)')
                : serviceName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCancelled ? Colors.red.shade900 : orderColor,
            ),
          ),
          if (!isCancelled) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: orderColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                (() {
                  final double kuantitas = (order['kuantitas'] as num?)?.toDouble() ?? 0.0;
                  if (kuantitas > 0.0) {
                    final String paymentStatus = _getPaymentStatus(order);
                    final bool isLunas = paymentStatus == 'Lunas';
                    final Color capBg = isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
                    final Color capText = isLunas ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
                    final bool isEn = TranslationService.currentLang == 'en';
                    final String capLabel = isLunas ? (isEn ? 'Paid' : 'Lunas') : (isEn ? 'Unpaid' : 'Belum Lunas');
                    
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Container(
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
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                })(),
              ],
            ),
          ],
          if (isCancelled && order['catatan_order'] != null && order['catatan_order'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'REJECTION REASON:' : 'ALASAN PENOLAKAN:',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['catatan_order'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          
          // Stepper Tracker Horizontal Persis Punya Pelanggan
          (() {
            final lang = TranslationService.currentLang;
            final List<Map<String, dynamic>> refStatuses = statusInfo['statuses'];
            final int activeIdx = statusInfo['active_index'];
            final bool isSelesai = statusInfo['is_selesai'] == true;
            final String rawStatus = statusInfo['raw_status'] ?? 'Pesanan Diterima';
            final bool isCancelled = rawStatus.toLowerCase().contains('batal') || rawStatus.toLowerCase().contains('tolak') || rawStatus.toLowerCase().contains('reject');

            List<Widget> steps = [];
            for (int i = 0; i < refStatuses.length; i++) {
              final rawName = refStatuses[i]['nama_status'] ?? '';
              final String shortLabel = _getShortStatusLabel(rawName, lang, isCancelled: isCancelled);
              
              final bool isCurrent = i == activeIdx && !isSelesai;
              final bool isDone = (i < activeIdx) || (isSelesai && i == refStatuses.length - 1) || (i == 0 && activeIdx > 0);
              final bool isActive = isDone || isCurrent;

              steps.add(
                _buildTimelineStep(
                  label: shortLabel,
                  isActive: isCancelled ? true : isActive,
                  isDone: isCancelled ? true : isDone,
                  isCurrent: isCancelled ? false : isCurrent,
                  themeColor: isCancelled ? Colors.red : orderColor,
                  index: i,
                  totalSteps: refStatuses.length,
                  isCancelled: isCancelled,
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
    );
  }

  Widget _buildTimelineStep({
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
                              ? Icon(Icons.fiber_manual_record, size: 8, color: themeColor)
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
                fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.normal,
                color: isActive ? themeColor : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card Informasi Pelanggan (Ingat: Pelanggan tidak bisa ditelepon, melainkan dikirimi pesan/chat)
  Widget _buildCustomerCard(Map<String, dynamic> pelanggan) {
    final String customerName = (pelanggan['nama_lengkap'] ?? 'Pelanggan').toString();
    final String customerPhone = (pelanggan['no_telp'] ?? pelanggan['no_hp'] ?? pelanggan['NoTelp'] ?? pelanggan['NoHp'] ?? pelanggan['noTelp'] ?? '-').toString();
    final String rawFoto = (pelanggan['foto_pelanggan'] ?? '').toString();

    // Build full photo URL same as other screens
    final String staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
    String fotoUrl = '';
    if (rawFoto.isNotEmpty) {
      if (rawFoto.startsWith('http://') || rawFoto.startsWith('https://')) {
        fotoUrl = rawFoto;
      } else if (rawFoto.startsWith('/')) {
        fotoUrl = '$staticHost$rawFoto';
      } else {
        fotoUrl = '$staticHost/$rawFoto';
      }
    }
    final bool hasFoto = fotoUrl.isNotEmpty;

    // Determine avatar initials from name
    final List<String> nameParts = customerName.trim().split(' ');
    final String initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : (nameParts.isNotEmpty && nameParts[0].isNotEmpty
            ? nameParts[0][0].toUpperCase()
            : '?');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF42C6D4).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: navyColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_pin_rounded, color: navyColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                TranslationService.currentLang == 'en' ? 'Customer Information' : 'Informasi Pelanggan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar circle with dynamic photo or initials
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0C4B8E), Color(0xFF42C6D4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0C4B8E).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: hasFoto
                    ? ClipOval(
                        child: Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (ctx, err, stack) => Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              // Name & info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF0C4B8E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF718096)),
                        const SizedBox(width: 5),
                        Text(
                          customerPhone,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tombol pesan / chat eksklusif
              GestureDetector(
                onTap: () => _openCustomerChat(customerName),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [navyColor, const Color(0xFF105CAE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0C4B8E).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        TranslationService.currentLang == 'en' ? 'Message' : 'Pesan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required String pickupDate,
    required String pickupAddr,
    required String deliveryAddr,
    required String logistikType,
    required Color navyColor,
  }) {
    final bool isDropOff = logistikType == 'Drop-off';
    final isEn = TranslationService.currentLang == 'en';
    final String translatedLogistik = isDropOff
        ? (isEn ? 'Drop-off' : 'Drop-off (Mandiri)')
        : (isEn ? 'Courier Delivery' : 'Pengantaran Kurir');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!isDropOff) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Pick Up' : 'Penjemputan',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickupDate,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: navyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Pick Up Address' : 'Alamat Jemput',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickupAddr,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: navyColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Logistics' : 'Logistik / Pengiriman',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      translatedLogistik,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: navyColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Delivery Address' : 'Alamat Antar',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deliveryAddr,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: navyColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewOrderCard({
    required String mainService,
    required String packageName,
    required String perfumeName,
    required String pickupAddr,
    required String deliveryAddr,
    required String pickupDate,
    required String logistikType,
    required bool isEn,
    required double hargaPerSatuan,
    required double biayaTambahan,
    required String catatan,
    required String orderDate,
    required String estDate,
  }) {
    final bool isDropOff = logistikType == 'Drop-off';
    final double kuantitasVal = (_currentOrder['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String qtyText = kuantitasVal == 0.0
        ? (isEn ? 'Pending Weight' : 'Menunggu Timbang')
        : '$kuantitasVal kg';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: navyColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.fact_check_rounded, color: navyColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                isEn ? 'Review Order' : 'Tinjau Pesanan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Main Service Padded Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: softTeal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_laundry_service_rounded, color: navyColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Laundry Service' : 'Layanan Laundry',
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mainService,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: navyColor),
                      ),
                      if (hargaPerSatuan > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${_formatRupiah(hargaPerSatuan)} / kg',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: navyColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    qtyText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail Section: Package & Perfume Info
          Row(
            children: [
              // Package
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: navyColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            isEn ? 'Package' : 'Paket',
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        packageName,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: navyColor),
                      ),
                      if (biayaTambahan > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '+ ${_formatRupiah(biayaTambahan)}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Perfume
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.spa_outlined, color: navyColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            isEn ? 'Perfume' : 'Parfum',
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        perfumeName,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: navyColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes Section (Instruksi Khusus)
          if (catatan.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note_rounded, color: navyColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Special Instruction' : 'Instruksi Khusus',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          catatan,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: navyColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timeline Details Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  isEn ? 'Order Type' : 'Tipe Pemesanan',
                  !isDropOff
                      ? (isEn ? 'Online (App)' : 'Online (Aplikasi)')
                      : (isEn ? 'Walk-in (Outlet)' : 'Walk-in (Di Toko)'),
                  Icons.devices_rounded,
                ),
                const Divider(height: 20),
                _buildDetailRow(isEn ? 'Order Date' : 'Tanggal Pesanan', orderDate, Icons.calendar_month_rounded),
                const Divider(height: 20),
                
                if (!isDropOff) ...[
                  _buildDetailRow(isEn ? 'Pick Up Date' : 'Tanggal Penjemputan', pickupDate, Icons.airport_shuttle_rounded),
                  const Divider(height: 20),
                  _buildDetailRow(isEn ? 'Pickup Address' : 'Alamat Penjemputan', pickupAddr, Icons.location_on_rounded),
                  const Divider(height: 20),
                ],
                
                _buildDetailRow(
                  isEn ? 'Logistics' : 'Tipe Logistik',
                  isDropOff 
                      ? (isEn ? 'Store Pickup (Drop-off)' : 'Ambil Sendiri di Toko') 
                      : (isEn ? 'Courier Delivery' : 'Pengantaran Kurir'),
                  Icons.local_shipping_rounded,
                ),
                const Divider(height: 20),
                _buildDetailRow(isEn ? 'Estimated Finished' : 'Estimasi Selesai', estDate, Icons.av_timer_rounded),
                const Divider(height: 20),
                
                if (!isDropOff) ...[
                  _buildDetailRow(
                    isEn ? 'Delivery Address' : 'Alamat Pengantaran',
                    deliveryAddr,
                    Icons.location_on_rounded,
                  ),
                ] else ...[
                  _buildDetailRow(
                    isEn ? 'Store Address' : 'Alamat Toko (Drop-off)',
                    'WishWash Laundry Utama\nJalan Raya Laundry No. 99, Tembalang, Semarang, Central Java',
                    Icons.storefront_rounded,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),
          
          // Action Button: View Transaction Receipt
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: Icon(Icons.receipt_long_rounded, color: navyColor, size: 18),
              label: Text(
                isEn ? 'View Transaction Receipt' : 'Lihat Resi Transaksi',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: navyColor.withOpacity(0.4), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showReceiptModal(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: navyColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: navyColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReceiptModal() {
    final String orderId = _currentOrder['kode_order'] != null && _currentOrder['kode_order'].toString().isNotEmpty
        ? _currentOrder['kode_order'].toString()
        : 'WW-${_currentOrder['id_order']}';

    final layanan = _currentOrder['Layanan'] ?? {};
    final String rawServiceName = layanan['nama_layanan'] ?? 'Layanan Laundry';
    final double kuantitas = (_currentOrder['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String qtyStr = kuantitas == 0.0
        ? (TranslationService.currentLang == 'en' ? ' (Pending Weight)' : ' (Menunggu Timbang)')
        : ' ($kuantitas kg)';
    final serviceName = '${TranslationService.translateService(rawServiceName)}$qtyStr';

    final double totalBayar = (_currentOrder['total_bayar'] as num?)?.toDouble() ?? 0.0;
    final double hargaPerSatuan = (layanan['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final double subtotalCucian = kuantitas * hargaPerSatuan;
    final paketLayanan = _currentOrder['PaketLayanan'] ?? {};
    final double biayaTambahan = (paketLayanan['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;

    // Diskon Promo
    final List<dynamic> promoOrders = _currentOrder['PromoOrder'] ?? [];
    double promoDiscount = 0.0;
    if (promoOrders.isNotEmpty) {
      final promoOrderObj = promoOrders.first;
      final promo = promoOrderObj['Promo'] ?? {};
      if (promo.isNotEmpty) {
        final String tipePromo = promo['tipe_promo'] ?? 'Nominal';
        final double nominalPotongan = (promo['nominal_potongan'] as num?)?.toDouble() ?? 0.0;
        final double maksimalPotongan = (promo['maksimal_potongan'] as num?)?.toDouble() ?? 0.0;
        
        if (tipePromo.toLowerCase().contains('persen')) {
          promoDiscount = subtotalCucian * (nominalPotongan / 100);
          if (maksimalPotongan > 0.0 && promoDiscount > maksimalPotongan) {
            promoDiscount = maksimalPotongan;
          }
        } else {
          promoDiscount = nominalPotongan;
        }
      }
    }

    final double computedTotal = subtotalCucian + biayaTambahan - promoDiscount;
    final double totalTagihan = kuantitas > 0.0 
        ? (computedTotal > 0.0 ? computedTotal : 0.0)
        : 0.0;
    final priceStr = _formatRupiah(totalTagihan);
    final orderDate = _formatDate(_currentOrder['tgl_pesanan']);
    final statusInfo = _getCurrentStatusInfo(_currentOrder);
    final String currentStatus = statusInfo['nama_status'];

    final pelanggan = _currentOrder['Pelanggan'] ?? {};
    final String customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';

    final parfum = _currentOrder['Parfum'] ?? {};
    final String perfumeName = parfum['nama_parfum'] ?? 'Lavender Bliss';
    final String packageName = paketLayanan['nama_paket'] ?? 'Reguler';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: _buildReceiptSection(
                      order: _currentOrder,
                      orderId: orderId,
                      orderDate: orderDate,
                      customerName: customerName,
                      packageName: packageName,
                      perfumeName: perfumeName,
                      logistikType: _currentOrder['tipe_logistik'] ?? 'Courier Delivery',
                      totalBayar: totalBayar,
                      price: priceStr,
                      catatan: _currentOrder['catatan_order'],
                      navyColor: navyColor,
                      currentStatus: currentStatus,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptSection({
    required Map<String, dynamic> order,
    required String orderId,
    required String orderDate,
    required String customerName,
    required String packageName,
    required String perfumeName,
    required String logistikType,
    required double totalBayar,
    required String price,
    required String? catatan,
    required Color navyColor,
    required String currentStatus,
  }) {
    final lang = TranslationService.currentLang;
    final isEn = lang == 'en';

    final String estDateText = _getEstSelesaiDate(order);

    final pelanggan = order['Pelanggan'] ?? {};
    final String customerPhone = (pelanggan['no_telp'] ?? pelanggan['NoTelp'] ?? pelanggan['no_hp'] ?? '-').toString();

    final alamatPengambilan = order['AlamatPengambilan'] ?? {};
    final String pickupAddr = alamatPengambilan['alamat_lengkap'] ?? '-';

    final alamatPenyerahan = order['AlamatPenyerahan'];
    final String deliveryAddr = (alamatPenyerahan != null && alamatPenyerahan['alamat_lengkap'] != null)
        ? alamatPenyerahan['alamat_lengkap'].toString()
        : (isEn ? 'Not specified yet' : 'Belum ditentukan');

    final layanan = order['Layanan'] ?? {};
    final String mainService = TranslationService.translateService(layanan['nama_layanan'] ?? 'Layanan Laundry');

    final double kuantitas = (order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String weightText = kuantitas == 0.0
        ? (isEn ? 'Pending Weight' : 'Menunggu Timbang')
        : '$kuantitas kg';

    final double hargaPerSatuan = (layanan['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final double subtotalCucian = kuantitas * hargaPerSatuan;
    final paketLayanan = order['PaketLayanan'] ?? {};
    final double biayaTambahan = (paketLayanan['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;

    final List<dynamic> promoOrders = order['PromoOrder'] ?? [];
    double promoDiscount = 0.0;
    String promoCode = '';

    if (promoOrders.isNotEmpty) {
      final promoOrderObj = promoOrders.first;
      final promo = promoOrderObj['Promo'] ?? {};
      if (promo.isNotEmpty) {
        promoCode = promo['kode_promo'] ?? '';
        final String tipePromo = promo['tipe_promo'] ?? 'Nominal';
        final double nominalPotongan = (promo['nominal_potongan'] as num?)?.toDouble() ?? 0.0;
        final double maksimalPotongan = (promo['maksimal_potongan'] as num?)?.toDouble() ?? 0.0;
        
        if (tipePromo.toLowerCase().contains('persen')) {
          promoDiscount = subtotalCucian * (nominalPotongan / 100);
          if (maksimalPotongan > 0.0 && promoDiscount > maksimalPotongan) {
            promoDiscount = maksimalPotongan;
          }
        } else {
          promoDiscount = nominalPotongan;
        }
      }
    }

    final karyawan = order['Karyawan'];
    final String employeeName = karyawan != null && karyawan['nama_karyawan'] != null
        ? karyawan['nama_karyawan'].toString()
        : (isEn ? 'Assigning Courier...' : 'Menunggu Kurir...');

    final pembayaran = order['Pembayaran'];
    final String paymentMethod = pembayaran != null && pembayaran['metode_bayar'] != null
        ? pembayaran['metode_bayar'].toString()
        : (isEn ? 'Unpaid Yet' : 'Belum Dibayar');

    final String paymentStatusLabel = pembayaran != null && pembayaran['status_pembayaran'] != null
        ? (pembayaran['status_pembayaran'] == 'Lunas' ? (isEn ? 'Paid' : 'Lunas') : (isEn ? 'Unpaid' : 'Belum Lunas'))
        : (isEn ? 'Unpaid' : 'Belum Lunas');

    final String patokanLokasi = order['keterangan_lokasi'] != null && order['keterangan_lokasi'].toString().trim().isNotEmpty
        ? order['keterangan_lokasi'].toString().trim()
        : '-';

    final String paymentRef = pembayaran != null && pembayaran['referensi_bayar'] != null && pembayaran['referensi_bayar'].toString().trim().isNotEmpty
        ? pembayaran['referensi_bayar'].toString().trim()
        : '-';

    final Color charBlack = const Color(0xFF2D3748); // Charcoal Black utama struk
    final Color slateGray = const Color(0xFF718096); // Slate Gray label struk

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 16),
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
              // Bagian Atas Struk (Header Struk Belanja)
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
                            color: const Color(0xFF0C4B8E), // Kode pesanan tetap berwarna brand WishWash
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isEn ? 'DATE' : 'TANGGAL',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: slateGray,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          orderDate,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: charBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bagian Isi Struk Belanja
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
                    if (logistikType != 'Drop-off')
                      _buildReceiptRow(isEn ? 'Pickup Address' : 'Alamat Jemput', pickupAddr),
                    _buildReceiptRow(isEn ? 'Delivery Address' : 'Alamat Antar', deliveryAddr),
                    if (patokanLokasi != '-')
                      _buildReceiptRow(isEn ? 'Location Notes' : 'Patokan Lokasi', patokanLokasi),
                    _buildReceiptRow(
                      isEn ? 'Order Type' : 'Tipe Pemesanan',
                      logistikType.toLowerCase().contains('drop')
                          ? (isEn ? 'Walk-in (Outlet)' : 'Walk-in (Di Toko)')
                          : (isEn ? 'Online (App)' : 'Online (Aplikasi)'),
                    ),
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

                    // Perhitungan Harga
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
                      promoCode.isNotEmpty
                          ? (isEn ? 'Promo Discount ($promoCode)' : 'Diskon Promo ($promoCode)')
                          : (isEn ? 'Promo Discount' : 'Diskon Promo'),
                      promoDiscount > 0.0
                          ? '- ${_formatRupiah(promoDiscount)}'
                          : _formatRupiah(0.0),
                      isBoldLabel: false,
                      textColor: promoDiscount > 0.0 ? Colors.red.shade700 : charBlack,
                    ),
                    _buildDashedDivider(),
                    
                    // Grand Total Bayar
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
                          price,
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
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100, width: 1),
                        ),
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
                              isEn ? '*Scan this barcode for operational validation' : '*Pindai barcode ini untuk validasi operasional',
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
                                  ? 'OPERATIONAL GUIDELINES:\n1. Ensure cloth quantity matches the weighed weight before laundry processing.\n2. Always verify payment status prior to order delivery.'
                                  : 'PANDUAN OPERASIONAL:\n1. Pastikan jumlah pakaian sesuai dengan berat timbangan sebelum masuk proses pencucian.\n2. Selalu verifikasi status pembayaran sebelum melakukan penyerahan order ke pelanggan.',
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
              color: const Color(0xFF718096), // Slate Gray
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
                color: isStatus ? (statusColor ?? const Color(0xFF2D3748)) : const Color(0xFF2D3748), // Charcoal Black
                fontSize: 12,
              ),
            ),
          ),
        ],
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

  // --- PEMBUATAN CHAT DIALOG SEMENTARA ---
  
  void _openCustomerChat(String name) {
    final bool isEn = TranslationService.currentLang == 'en';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEn ? 'Opening chat with $name...' : 'Membuka chat dengan $name...',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: navyColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Footer lengket berisi Tombol Update Status & Pembayaran
  Widget _buildStickyActionFooter() {
    final status = _getOrderStatus(_currentOrder).toLowerCase();
    final statusPembayaran = _getPaymentStatus(_currentOrder);
    final bool isBelumLunas = statusPembayaran == 'Belum Lunas';
    final double kuantitas = (_currentOrder['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final bool showTandaiLunas = isBelumLunas && kuantitas > 0.0;

    String actionBtnText = '';
    String nextStatus = '';
    VoidCallback? customAction;

    final refStatuses = _getSortedReferenceStatuses(_currentOrder);
    final currentStatusIdx = refStatuses.indexWhere(
      (element) => (element['nama_status'] ?? '').toString().toLowerCase().trim() == status
    );

    final String logistikType = _currentOrder['tipe_logistik'] ?? 'Courier Delivery';
    final bool isDropOff = logistikType == 'Drop-off';

    final pembayaran = _currentOrder['Pembayaran'];
    final String paymentMethod = pembayaran != null && pembayaran['metode_bayar'] != null
        ? pembayaran['metode_bayar'].toString().toUpperCase()
        : '';
    final String paymentStatus = _getPaymentStatus(_currentOrder);

    final bool isPaymentConfirmed = pembayaran != null && paymentMethod.isNotEmpty;
    final bool canDeliver = isPaymentConfirmed && 
        (paymentMethod == 'CASH' || paymentMethod == 'COD' || (paymentMethod == 'QRIS' && paymentStatus == 'Lunas'));

    if (status == 'siap diantar' && !isDropOff) {
      if (!_isDeliveryStarted) {
        actionBtnText = TranslationService.currentLang == 'en' ? 'Deliver Now' : 'Antar Sekarang';
        customAction = () {
          if (!canDeliver) {
            String warningMsg = '';
            if (!isPaymentConfirmed) {
              warningMsg = TranslationService.currentLang == 'en'
                  ? 'The customer has not selected a payment method (Cash/QRIS) yet in their app.'
                  : 'Pelanggan belum memilih metode pembayaran (Cash/QRIS) di aplikasi mereka.';
            } else if (paymentMethod == 'QRIS' && paymentStatus != 'Lunas') {
              warningMsg = TranslationService.currentLang == 'en'
                  ? 'The customer selected QRIS payment, but the payment status is not LUNAS yet.'
                  : 'Pelanggan memilih metode pembayaran QRIS, tetapi status pembayaran belum LUNAS.';
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                final isEn = TranslationService.currentLang == 'en';
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: navyColor.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Header
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFE65100),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          isEn ? 'Payment Unconfirmed' : 'Pembayaran Belum Siap',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: navyColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Content
                        Text(
                          warningMsg,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              isEn ? 'Understood' : 'Mengerti',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
            return;
          }

          _showConfirmationDialog(
            title: TranslationService.currentLang == 'en' ? 'Start Delivery?' : 'Mulai Pengantaran?',
            content: TranslationService.currentLang == 'en'
                ? 'Are you sure you want to start delivering this order now?'
                : 'Apakah Anda yakin ingin mulai mengantarkan pesanan ini sekarang?',
            onConfirm: () {
              setState(() {
                _isDeliveryStarted = true;
              });
            },
          );
        };
      } else {
        actionBtnText = '';
      }
    } else if (currentStatusIdx != -1 && currentStatusIdx < refStatuses.length - 1) {
      final nextRef = refStatuses[currentStatusIdx + 1];
      final rawNextName = (nextRef['nama_status'] ?? '').toString();
      final lowerNext = rawNextName.toLowerCase().trim();

      nextStatus = lowerNext;

      // Map button label dynamically
      if (status.contains('timbang') || status.contains('weigh') ||
          ((lowerNext.contains('timbang') || lowerNext.contains('weigh')) &&
           !(status.contains('jemput') || status.contains('pickup') || status.contains('penjemputan')))) {
        actionBtnText = TranslationService.currentLang == 'en' ? 'Start Weighing Laundry' : 'Mulai Timbang Cucian';
        customAction = _showWeighingDialog;
      } else if (status.contains('jemput') || status.contains('pickup') || status.contains('penjemputan')) {
        if (!_isPickupStarted) {
          actionBtnText = TranslationService.currentLang == 'en' ? 'Pick Up Now' : 'Jemput Sekarang';
          customAction = () {
            _showConfirmationDialog(
              title: TranslationService.currentLang == 'en' ? 'Start Pickup?' : 'Mulai Penjemputan?',
              content: TranslationService.currentLang == 'en' 
                  ? 'Are you sure you want to start picking up this order now?'
                  : 'Apakah Anda yakin ingin mulai menjemput pesanan ini sekarang?',
              onConfirm: () {
                setState(() {
                  _isPickupStarted = true;
                });
              },
            );
          };
        } else {
          actionBtnText = '';
        }
      } else if (lowerNext.contains('jemput') || lowerNext.contains('pickup') || lowerNext.contains('penjemputan')) {
        actionBtnText = TranslationService.currentLang == 'en' ? 'Order Received ➔ Ready to Pick Up' : 'Pesanan Diterima ➔ Siap Jemput';
      } else {
        final isEn = TranslationService.currentLang == 'en';
        final String currentLabel = _getShortStatusLabel(status, TranslationService.currentLang);
        final String nextLabel = _getShortStatusLabel(rawNextName, TranslationService.currentLang);

        if (lowerNext.contains('selesai') || lowerNext.contains('completed') || lowerNext.contains('success')) {
          if (!isBelumLunas) {
            actionBtnText = isEn ? 'Mark Order as Completed' : 'Tandai Pesanan Selesai';
          } else {
            actionBtnText = '';
          }
        } else if (lowerNext.contains('antar') || lowerNext.contains('delivery') || lowerNext.contains('siap diantar')) {
          actionBtnText = isEn
              ? 'Process $currentLabel Completed ➔ Ready to Deliver'
              : 'Proses $currentLabel Selesai ➔ Siap Diantar';
        } else {
          actionBtnText = isEn
              ? 'Process $currentLabel Completed ➔ Start $nextLabel'
              : 'Proses $currentLabel Selesai ➔ Mulai $nextLabel';
        }
      }
    }

    final bool hasMapButton = status == 'penjemputan' || status == 'siap diantar' || nextStatus == 'penjemputan';
    if (actionBtnText.isEmpty && !showTandaiLunas && !hasMapButton) {
      return const SizedBox.shrink();
    }

    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'siap diantar' && !isDropOff && !canDeliver) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      !isPaymentConfirmed
                          ? (TranslationService.currentLang == 'en'
                              ? 'Waiting for customer to choose payment method (Cash/QRIS) in the app.'
                              : 'Menunggu pelanggan memilih metode pembayaran (Cash/QRIS) di aplikasi.')
                          : (TranslationService.currentLang == 'en'
                              ? 'Customer selected QRIS, waiting for payment confirmation.'
                              : 'Pelanggan menggunakan QRIS. Menunggu pembayaran lunas sebelum diantar.'),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status == 'pesanan diterima') ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                      ),
                      onPressed: _showTolakPesananDialog,
                      icon: const Icon(Icons.cancel_rounded, size: 18),
                      label: Text(
                        TranslationService.currentLang == 'en' ? 'Reject Order' : 'Tolak Pesanan',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
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
                        if (nextStatus.isNotEmpty) {
                          _updateStatus(nextStatus);
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        TranslationService.currentLang == 'en' ? 'Accept Order' : 'Terima Pesanan',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (actionBtnText.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: navyColor.withValues(alpha: 0.4),
                ),
                onPressed: () {
                  if (customAction != null) {
                    customAction();
                  } else if (nextStatus.isNotEmpty) {
                    _updateStatus(nextStatus);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(status == 'siap diantar' || status == 'penjemputan' || nextStatus == 'penjemputan'
                        ? Icons.local_shipping_outlined 
                        : Icons.check_circle_outline_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      actionBtnText,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if ((status == 'penjemputan' && _isPickupStarted) || (status == 'siap diantar' && _isDeliveryStarted)) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KaryawanTrackingScreen(order: _currentOrder),
                    ),
                  );
                  if (result != null && result is Map<String, dynamic> && mounted) {
                    setState(() {
                      _currentOrder = result;
                    });
                    widget.onOrderUpdated(_currentOrder);
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  status == 'siap diantar' 
                      ? (TranslationService.currentLang == 'en' ? 'Open Delivery Map' : 'Buka Peta Pengantaran')
                      : (TranslationService.currentLang == 'en' ? 'Open Pickup Map' : 'Buka Peta Penjemputan'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          
          if (showTandaiLunas) ...[
            if (actionBtnText.isNotEmpty || (status == 'penjemputan' || status == 'siap diantar')) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () {
                  _showConfirmationDialog(
                    title: TranslationService.currentLang == 'en' ? 'Mark Payment as Paid?' : 'Tandai Pembayaran Lunas?',
                    content: TranslationService.currentLang == 'en'
                        ? 'Make sure payment has been received before marking this order as PAID.'
                        : 'Pastikan pembayaran sudah diterima sebelum menandai pesanan ini sebagai LUNAS.',
                    onConfirm: _markAsPaid,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.currentLang == 'en' ? 'Mark Payment as PAID' : 'Tandai Pembayaran LUNAS',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
