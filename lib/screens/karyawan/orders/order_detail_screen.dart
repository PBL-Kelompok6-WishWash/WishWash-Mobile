import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:barcode_widget/barcode_widget.dart';

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

  @override
  void initState() {
    super.initState();
    // Salin data order lokal agar modifikasi state aman secara interaktif
    _currentOrder = Map<String, dynamic>.from(widget.order);
  }

  // --- KONSISTENSI DENGAN DETIL PESANAN PELANGGAN ---
  
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
    final String currentStatus = order['status_operasional'] ?? 'Pesanan Diterima';
    final String lowerCurrent = currentStatus.toLowerCase().trim();
    
    int activeIndex = 0;
    for (int i = 0; i < refStatuses.length; i++) {
      final String name = (refStatuses[i]['nama_status'] ?? '').toString().toLowerCase().trim();
      if (name == lowerCurrent) {
        activeIndex = i;
        break;
      }
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
  
  void _updateStatus(String newStatus) {
    setState(() {
      _currentOrder['status_operasional'] = newStatus;
    });
    widget.onOrderUpdated(_currentOrder);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status pesanan berhasil diperbarui ke: ${TranslationService.translateStatus(newStatus)}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _getDarkenedTextColor(_getServiceColor((_currentOrder['Layanan']?['nama_layanan'] ?? ''))),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _markAsPaid() {
    setState(() {
      _currentOrder['Pembayaran'] = {
        'status_pembayaran': 'Lunas',
      };
    });
    widget.onOrderUpdated(_currentOrder);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pembayaran berhasil ditandai LUNAS',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void _showWeighingDialog() {
    final textController = TextEditingController();
    final double hargaPerKg = (_currentOrder['Layanan']['harga_per_satuan'] as num).toDouble();
    final double biayaTambahan = (_currentOrder['PaketLayanan']['biaya_tambahan'] as num).toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Timbang Cucian',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: navyColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan berat cucian riil dalam kilogram (Kg):',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Berat Cucian (Kg)',
                  labelStyle: GoogleFonts.poppins(color: navyColor),
                  suffixText: 'Kg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: navyColor, width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: navyColor),
              ),
              const SizedBox(height: 10),
              Text(
                '*Harga/Kg: ${_formatRupiah(hargaPerKg)}\n*Biaya Paket: ${_formatRupiah(biayaTambahan)}',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: navyColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final double? weight = double.tryParse(textController.text.replaceAll(',', '.'));
                if (weight == null || weight <= 0.0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harap masukkan angka berat yang valid!')),
                  );
                  return;
                }

                Navigator.pop(context);

                final double computedTotal = (weight * hargaPerKg) + biayaTambahan;

                setState(() {
                  _currentOrder['kuantitas'] = weight;
                  _currentOrder['total_bayar'] = computedTotal;
                });

                _updateStatus('proses cuci');
              },
              child: Text(
                'Simpan & Proses',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
    final String customerPhone = pelanggan['no_hp'] ?? '-';

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
                      'Detail Pesanan',
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Progress Card (Desain & Horizontal Stepper Persis Punya Pelanggan)
                      _buildProgressCard(
                        order: _currentOrder,
                        orderId: orderId,
                        serviceName: serviceName,
                        price: priceStr,
                        estDate: estDate,
                        statusInfo: statusInfo,
                        baseColor: baseColor,
                        orderColor: orderColor,
                        currentStatus: currentStatus,
                      ),
                      const SizedBox(height: 16),

                      // 2. Customer Information Card (Eksklusif Karyawan - Menggunakan tombol pesan/chat, BUKAN telp)
                      _buildCustomerCard(customerName, customerPhone),
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

                      // 4. Receipt Card / Invoice Details (Sama Persis Punya Pelanggan + Barcode)
                      _buildReceiptSection(
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
                  final String capLabel = isLunas ? 'Lunas' : 'Belum Lunas';
                  
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
          
          // Stepper Tracker Horizontal Persis Punya Pelanggan
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
  Widget _buildCustomerCard(String customerName, String customerPhone) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pelanggan',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: softTeal,
                child: Icon(Icons.person_rounded, color: navyColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: navyColor,
                      ),
                    ),
                    Text(
                      customerPhone,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol pesan / chat eksklusif, bukan telepon
              GestureDetector(
                onTap: () => _openCustomerChat(customerName),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: cyanColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_rounded, color: navyColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Pesan',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logistics',
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
    final String customerPhone = pelanggan['no_hp'] ?? '-';

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
                    _buildReceiptRow(isEn ? 'Pickup Address' : 'Alamat Jemput', pickupAddr),
                    _buildReceiptRow(isEn ? 'Delivery Address' : 'Alamat Antar', deliveryAddr),
                    if (patokanLokasi != '-')
                      _buildReceiptRow(isEn ? 'Location Notes' : 'Patokan Lokasi', patokanLokasi),
                    _buildReceiptRow(isEn ? 'Logistics Method' : 'Metode Logistik', logistikType),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Membuka chat dengan $name...',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: navyColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Footer lengket berisi Tombol Update Status & Pembayaran
  Widget _buildStickyActionFooter() {
    final status = _currentOrder['status_operasional'].toString().toLowerCase();
    final statusPembayaran = _currentOrder['Pembayaran']?['status_pembayaran'] ?? 'Belum Lunas';
    final bool isBelumLunas = statusPembayaran == 'Belum Lunas';

    String actionBtnText = '';
    String nextStatus = '';
    VoidCallback? customAction;

    if (status == 'penjemputan') {
      actionBtnText = 'Konfirmasi Penjemputan Selesai';
      nextStatus = 'proses timbang';
    } else if (status == 'pesanan diterima' || status == 'proses timbang') {
      actionBtnText = 'Mulai Timbang Cucian';
      customAction = _showWeighingDialog; 
    } else if (status == 'proses cuci') {
      actionBtnText = 'Pencucian Selesai ➔ Mulai Keringkan';
      nextStatus = 'proses kering';
    } else if (status == 'proses kering') {
      actionBtnText = 'Pengeringan Selesai ➔ Mulai Lipat';
      nextStatus = 'proses lipat';
    } else if (status == 'proses lipat') {
      actionBtnText = 'Lipat Selesai ➔ Mulai Setrika';
      nextStatus = 'proses setrika';
    } else if (status == 'proses setrika') {
      actionBtnText = 'Penyetrikaan Selesai ➔ Siap Diantar';
      nextStatus = 'siap diantar';
    } else if (status == 'siap diantar') {
      actionBtnText = 'Konfirmasi Pengantaran Selesai';
      nextStatus = 'selesai';
    }

    if (actionBtnText.isEmpty && !isBelumLunas) {
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
          if (actionBtnText.isNotEmpty)
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
                    Icon(status == 'siap diantar' || status == 'penjemputan' 
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
          
          if (isBelumLunas) ...[
            if (actionBtnText.isNotEmpty) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade600, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _markAsPaid,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Tandai Pembayaran LUNAS',
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
