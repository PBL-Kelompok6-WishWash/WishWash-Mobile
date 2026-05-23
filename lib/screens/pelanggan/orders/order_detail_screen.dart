import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:mobile/services/translation_service.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  List<Map<String, dynamic>> _getSortedReferenceStatuses(Map<String, dynamic> order) {
    final layanan = order['Layanan'];
    final List<dynamic>? refList = layanan != null ? layanan['ReferensiStatus'] : null;
    
    if (refList == null || refList.isEmpty) {
      return const [
        {'nama_status': 'Pesanan Diterima', 'urutan_tahap': 1},
        {'nama_status': 'Penjemputan', 'urutan_tahap': 2},
        {'nama_status': 'Proses Timbang', 'urutan_tahap': 3},
        {'nama_status': 'Proses Cuci', 'urutan_tahap': 4},
        {'nama_status': 'Proses Kering', 'urutan_tahap': 5},
        {'nama_status': 'Proses Lipat', 'urutan_tahap': 6},
        {'nama_status': 'Siap Diantar', 'urutan_tahap': 7},
        {'nama_status': 'Selesai', 'urutan_tahap': 8},
      ];
    }
    
    List<Map<String, dynamic>> sortedList = refList.map((e) => Map<String, dynamic>.from(e)).toList();
    sortedList.sort((a, b) {
      final int seqA = a['urutan_tahap'] as int? ?? 0;
      final int seqB = b['urutan_tahap'] as int? ?? 0;
      return seqA.compareTo(seqB);
    });
    return sortedList;
  }

  String _getShortStatusLabel(String rawStatus, String lang) {
    final status = rawStatus.toLowerCase().trim();
    final isEn = lang == 'en';
    
    if (status.contains('diterima') || status.contains('received')) {
      return isEn ? 'Received' : 'Diterima';
    }
    if (status.contains('jemput') || status.contains('pickup') || status.contains('pick up') || status.contains('penjemputan')) {
      return isEn ? 'Pick Up' : 'Jemput';
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
      return isEn ? 'Ready' : 'Kirim';
    }
    if (status.contains('selesai') || status.contains('completed') || status.contains('success') || status.contains('done')) {
      return isEn ? 'Done' : 'Selesai';
    }
    
    if (rawStatus.length > 7) {
      return rawStatus.substring(0, 7);
    }
    return rawStatus;
  }

  Map<String, dynamic> _getCurrentStatusInfo(Map<String, dynamic> order) {
    final List<Map<String, dynamic>> refStatuses = _getSortedReferenceStatuses(order);
    
    final historyList = order['RiwayatStatusDetail'];
    if (historyList == null || historyList is! List || historyList.isEmpty) {
      final String rawStatus = refStatuses.isNotEmpty ? refStatuses.first['nama_status'] : 'Pesanan Diterima';
      return {
        'nama_status': TranslationService.translateStatus(rawStatus),
        'raw_status': rawStatus,
        'active_index': 0,
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
      return {
        'nama_status': TranslationService.translateStatus(rawStatus),
        'raw_status': rawStatus,
        'active_index': 0,
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
        final String name = (refStatuses[i]['nama_status'] ?? '').toString().toLowerCase().trim();
        if (name == lowerRaw) {
          activeIndex = i;
          break;
        }
      }
    }

    final bool isSelesai = rawStatus.toLowerCase().contains('selesai') || rawStatus.toLowerCase().contains('completed') || rawStatus.toLowerCase().contains('success');

    return {
      'nama_status': translatedStatus,
      'raw_status': rawStatus,
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
    if (order['jadwal_pickup'] == null || order['jadwal_pickup'].toString().isEmpty) {
      return '-';
    }
    try {
      final pickup = DateTime.parse(order['jadwal_pickup']);
      final paket = order['PaketLayanan'];
      final int durasiJam = paket != null ? (paket['durasi_jam'] as num?)?.toInt() ?? 0 : 0;
      
      if (durasiJam == 0) {
        return _formatDate(order['jadwal_pickup']);
      }
      
      final estSelesai = pickup.add(Duration(hours: durasiJam));
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
      return _formatDate(order['jadwal_pickup']);
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

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    
    final String orderId = order['kode_order'] != null && order['kode_order'].toString().isNotEmpty
        ? order['kode_order'].toString()
        : 'WW-${order['id_order']}';

    final layanan = order['Layanan'] ?? {};
    final String rawServiceName = layanan['nama_layanan'] ?? 'Layanan Laundry';
    final double kuantitas = (order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String qtyStr = kuantitas == 0.0
        ? (TranslationService.currentLang == 'en' ? ' (Pending Weight)' : ' (Menunggu Timbang)')
        : ' ($kuantitas kg)';
    final serviceName = '${TranslationService.translateService(rawServiceName)}$qtyStr';
    final baseColor = _getServiceColor(rawServiceName);
    final orderColor = _getDarkenedTextColor(baseColor);

    final double totalBayar = (order['total_bayar'] as num?)?.toDouble() ?? 0.0;
    final price = _formatRupiah(totalBayar);
    final estDate = _getEstSelesaiDate(order);
    final orderDate = _formatDate(order['tgl_pesanan']);

    final statusInfo = _getCurrentStatusInfo(order);
    final String currentStatus = statusInfo['nama_status'];

    final pelanggan = order['Pelanggan'] ?? {};
    final String customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';

    final alamatPengambilan = order['AlamatPengambilan'] ?? {};
    final String pickupAddr = alamatPengambilan['alamat_lengkap'] ?? '-';
    
    final alamatPenyerahan = order['AlamatPenyerahan'];
    final String deliveryAddr = (alamatPenyerahan != null && alamatPenyerahan['alamat_lengkap'] != null)
        ? alamatPenyerahan['alamat_lengkap'].toString()
        : (TranslationService.currentLang == 'en' ? 'Not specified yet' : 'Belum ditentukan');

    final parfum = order['Parfum'] ?? {};
    final String perfumeName = parfum['nama_parfum'] ?? 'Lavender Bliss';

    final paketLayanan = order['PaketLayanan'] ?? {};
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: navyColor,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Order Details',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Stepper Card
                      _buildProgressCard(
                        order: order,
                        orderId: orderId,
                        serviceName: serviceName,
                        price: price,
                        estDate: estDate,
                        statusInfo: statusInfo,
                        baseColor: baseColor,
                        orderColor: orderColor,
                        currentStatus: currentStatus,
                      ),
                      const SizedBox(height: 16),
                      // Schedule Details Card
                      _buildScheduleCard(
                        pickupDate: estDate,
                        pickupAddr: pickupAddr,
                        deliveryAddr: deliveryAddr,
                        logistikType: order['tipe_logistik'] ?? 'Courier Delivery',
                        navyColor: navyColor,
                      ),
                      const SizedBox(height: 24),
                      // Receipt/Invoice Details Card
                      _buildReceiptSection(
                        orderId: orderId,
                        orderDate: orderDate,
                        customerName: customerName,
                        packageName: packageName,
                        perfumeName: perfumeName,
                        logistikType: order['tipe_logistik'] ?? 'Courier Delivery',
                        totalBayar: totalBayar,
                        price: price,
                        catatan: order['catatan_order'],
                        navyColor: navyColor,
                        currentStatus: currentStatus,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: orderColor,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Text(
                      'Download Receipt',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(baseColor.withValues(alpha: 0.18), Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: orderColor.withValues(alpha: 0.4),
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
                'Order #$orderId',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: orderColor,
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
                    'Est: $estDate',
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
            serviceName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: orderColor,
            ),
          ),
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
                  final pembayaran = order['Pembayaran'];
                  final bool isLunas = pembayaran != null && pembayaran['status_pembayaran'] == 'Lunas';
                  final Color capBg = isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
                  final Color capText = isLunas ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
                  final String capLabel = isLunas 
                      ? (TranslationService.currentLang == 'en' ? 'Paid' : 'Lunas')
                      : (TranslationService.currentLang == 'en' ? 'Unpaid' : 'Belum Lunas');
                  
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: capBg,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: capText.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: capText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              capLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: capText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              })(),
            ],
          ),
          const SizedBox(height: 24),
          // Stepper Tracker (DYNAMICAL DATABASE ALIGNED - GARIS NYAMBUNG PERFECT)
          (() {
            final lang = TranslationService.currentLang;
            final List<Map<String, dynamic>> refStatuses = statusInfo['statuses'];
            final int activeIdx = statusInfo['active_index'];
            final bool isSelesai = statusInfo['is_selesai'] == true;

            List<Widget> steps = [];
            for (int i = 0; i < refStatuses.length; i++) {
              final rawName = refStatuses[i]['nama_status'] ?? '';
              final String shortLabel = _getShortStatusLabel(rawName, lang);
              final bool isDone = i < activeIdx || (isSelesai && i == refStatuses.length - 1);
              final bool isCurrent = i == activeIdx && !isSelesai;
              final bool isActive = isDone || isCurrent;

              steps.add(
                _buildTimelineStep(
                  label: shortLabel,
                  isActive: isActive,
                  isDone: isDone,
                  isCurrent: isCurrent,
                  themeColor: orderColor,
                  index: i,
                  totalSteps: refStatuses.length,
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
  }) {
    final bool showLeftLine = index > 0;
    final bool showRightLine = index < totalSteps - 1;
    final Color leftLineColor = isDone || isCurrent ? themeColor : Colors.grey.shade300;
    final Color rightLineColor = isDone ? themeColor : Colors.grey.shade300;

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
                      color: isDone ? themeColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? themeColor : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (isCurrent)
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Center(
                      child: isCurrent
                          ? Icon(Icons.fiber_manual_record, size: 8, color: themeColor)
                          : (isDone ? const Icon(Icons.check, size: 10, color: Colors.white) : const SizedBox.shrink()),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.normal,
                color: isActive ? themeColor : Colors.grey.shade600,
              ),
            ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick Up',
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
                      'Pick Up Address',
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
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: Colors.blue.shade100,
              thickness: 1,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      logistikType,
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
                      'Delivery Address',
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

  Widget _buildReceiptSection({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Receipt',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: navyColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                color: navyColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderId',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      Text(
                        orderDate,
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: currentStatus.toLowerCase().contains('selesai') || currentStatus.toLowerCase().contains('completed') || currentStatus.toLowerCase().contains('success')
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentStatus,
                      style: GoogleFonts.poppins(
                        color: currentStatus.toLowerCase().contains('selesai') || currentStatus.toLowerCase().contains('completed') || currentStatus.toLowerCase().contains('success')
                            ? Colors.green
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildReceiptRow('Customer', customerName),
              _buildReceiptRow('Package & Perfume', '$packageName Package - $perfumeName'),
              _buildReceiptRow('Logistics Method', logistikType),
              if (catatan != null && catatan.trim().isNotEmpty)
                _buildReceiptRow('Note / Instruction', catatan),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Colors.blue.shade100,
                  thickness: 1,
                ),
              ),
              _buildPriceRow('Sub Total', price, isBoldLabel: false),
              const SizedBox(height: 4),
              _buildPriceRow('Paid Total', price, isTotal: true),
              const SizedBox(height: 24),
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: 'Order#$orderId',
                drawText: false,
                height: 50,
                width: double.infinity,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '*Show this receipt when picking up your order',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C4B8E),
              fontSize: 13,
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF0C4B8E),
            fontWeight: isTotal || isBoldLabel ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 14 : 12,
          ),
        ),
        Text(
          price,
          style: GoogleFonts.poppins(
            color: const Color(0xFF0C4B8E),
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 14 : 12,
          ),
        ),
      ],
    );
  }
}