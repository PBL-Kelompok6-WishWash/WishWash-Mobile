import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/screens/pelanggan/orders/payment_screen.dart';
import 'package:mobile/services/alamat_service.dart';
import 'package:mobile/screens/pelanggan/home/alamat_screen.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> _currentOrder;
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgGrey = const Color(0xFFF8FBFC);
  final Color softTeal = const Color(0xFFBCEFF2);

  // Interactive Payment & Checkout state
  String _selectedPaymentMethod = 'QRIS';
  final TextEditingController _promoController = TextEditingController();
  double _appliedPromoDiscount = 0.0;
  bool _isPromoApplied = false;
  String _promoError = '';
  String _appliedPromoCode = '';

  List<dynamic> addresses = [];
  bool isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _currentOrder = Map<String, dynamic>.from(widget.order);
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final pelanggan = _currentOrder['Pelanggan'] ?? {};
      final int? idPelanggan = pelanggan['id_pelanggan'];
      if (idPelanggan != null) {
        final list = await AlamatService.getAlamat(idPelanggan: idPelanggan);
        setState(() {
          addresses = list;
          isLoadingAddresses = false;
          if (list.isNotEmpty) {
            final primary = list.firstWhere(
              (element) => element['is_primary'] == true,
              orElse: () => list.first,
            );
            _currentOrder['AlamatPenyerahan'] = {
              'alamat_lengkap': primary['alamat_lengkap'],
              'tipe_alamat': primary['tipe_alamat'],
              'nama_penerima': primary['nama_penerima'],
            };
            // Set logistics type to Courier Delivery immediately only if it is not already Drop-off
            if (_currentOrder['tipe_logistik'] != 'Drop-off') {
              _currentOrder['tipe_logistik'] = 'Courier Delivery';
              _updateLogisticsBackend('Courier Delivery', idAlamatPenyerahan: primary['id_alamat']);
            }
          }
        });
      } else {
        setState(() {
          isLoadingAddresses = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingAddresses = false;
      });
    }
  }

  Future<void> _chooseAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlamatScreen()),
    );
    _loadAddresses();
  }

  Future<void> _updateLogisticsBackend(String newType, {int? idAlamatPenyerahan}) async {
    try {
      final Map<String, dynamic> body = {'tipe_logistik': newType};
      if (idAlamatPenyerahan != null) {
        body['id_alamat_penyerahan'] = idAlamatPenyerahan;
      }
      
      final updatedOrder = await OrderService.updateOrder(
        _currentOrder['id_order'],
        body,
      );
      setState(() {
        _currentOrder = Map<String, dynamic>.from(updatedOrder);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.currentLang == 'en' 
                ? 'Failed to update logistics: $e' 
                : 'Gagal memperbarui metode pengiriman: $e'
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    if (order['tipe_logistik'] == 'Drop-off') {
      sortedList.removeWhere((element) {
        final name = (element['nama_status'] ?? '').toString().toLowerCase();
        return name.contains('jemput') || name.contains('pickup') || name.contains('penjemputan');
      });
    }

    return sortedList;
  }

  String _getShortStatusLabel(String rawStatus, String lang, {bool isCancelled = false}) {
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
      final bool isDropOff = _currentOrder['tipe_logistik'] == 'Drop-off';
      return isEn ? 'Ready' : (isDropOff ? 'Ambil' : 'Kirim');
    }
    if (status.contains('selesai') || status.contains('completed') || status.contains('success') || status.contains('done') || status.contains('batal') || status.contains('cancel') || status.contains('tolak') || status.contains('reject')) {
      if (isCancelled) {
        return isEn ? 'Cancelled' : 'Batal';
      }
      return isEn ? 'Done' : 'Selesai';
    }
    
    if (rawStatus.length > 7) {
      return rawStatus.substring(0, 7);
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

    final bool isSelesai = lowerCurrent.contains('selesai') || 
                           lowerCurrent.contains('completed') || 
                           lowerCurrent.contains('batal') || 
                           lowerCurrent.contains('tolak') || 
                           lowerCurrent.contains('reject');

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
      final dt = DateTime.parse(isoString).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
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
      return const Color(0xFF00BCD4);
    } else if (name.contains('kering') && !name.contains('lipat')) {
      return const Color(0xFF8BC34A);
    } else if (name.contains('setrika') && (name.contains('cuci') || name.contains('wash'))) {
      return const Color(0xFF9C27B0);
    } else if (name.contains('setrika')) {
      return const Color(0xFFFFC107);
    }
    return const Color(0xFF00BCD4);
  }

  Color _getDarkenedTextColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.hue >= 160 && hsl.hue <= 210) {
      return const Color(0xFF0C4B8E);
    }
    if (hsl.lightness > 0.45) {
      double targetLightness = 0.30;
      if (hsl.hue >= 45 && hsl.hue <= 65) {
        targetLightness = 0.25;
      }
      return hsl.withLightness(targetLightness).toColor();
    }
    return color;
  }

  void _applyPromoCode(double subtotalCucian) {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      if (code == 'WISHWASH50') {
        _appliedPromoDiscount = subtotalCucian * 0.50;
        _isPromoApplied = true;
        _promoError = '';
        _appliedPromoCode = code;
      } else if (code == 'HELLOWW') {
        _appliedPromoDiscount = subtotalCucian > 10000 ? 10000 : subtotalCucian;
        _isPromoApplied = true;
        _promoError = '';
        _appliedPromoCode = code;
      } else {
        _appliedPromoDiscount = 0.0;
        _isPromoApplied = false;
        _promoError = TranslationService.currentLang == 'en' ? 'Invalid Promo Code!' : 'Kode Promo Tidak Valid!';
        _appliedPromoCode = '';
      }
    });
  }

  Widget _buildCancelledBanner(BuildContext context, Color orderColor, bool isEn, String? reason) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade200.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFFF3B30),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Order Cancelled' : 'Pesanan Dibatalkan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEn ? 'This order has been rejected or cancelled.' : 'Pesanan ini telah ditolak atau dibatalkan.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFFFCDD2), height: 1),
            const SizedBox(height: 14),
            Text(
              isEn ? 'REJECTION REASON:' : 'ALASAN PENOLAKAN:',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reason,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder;
    final String orderId = order['kode_order'] != null && order['kode_order'].toString().isNotEmpty
        ? order['kode_order'].toString()
        : 'WW-${order['id_order']}';

    final layanan = order['Layanan'] ?? {};
    final String rawServiceName = layanan['nama_layanan'] ?? 'Layanan Laundry';
    final String mainService = TranslationService.translateService(rawServiceName);
    final double kuantitas = (order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String qtyStr = kuantitas == 0.0
        ? (TranslationService.currentLang == 'en' ? ' (Pending Weight)' : ' (Menunggu Timbang)')
        : ' ($kuantitas kg)';
    final serviceName = '$mainService$qtyStr';
    final baseColor = _getServiceColor(rawServiceName);
    final orderColor = _getDarkenedTextColor(baseColor);

    final double totalBayar = (order['total_bayar'] as num?)?.toDouble() ?? 0.0;
    final double hargaPerSatuan = (layanan['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final double subtotalCucian = kuantitas * hargaPerSatuan;
    final paketLayanan = order['PaketLayanan'] ?? {};
    final double biayaTambahan = (paketLayanan['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;

    // Diskon Promo
    double promoDiscount = _isPromoApplied ? _appliedPromoDiscount : 0.0;
    if (!_isPromoApplied) {
      final List<dynamic> promoOrders = order['PromoOrder'] ?? [];
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
    }

    final double computedTotal = subtotalCucian + biayaTambahan - promoDiscount;
    final double totalTagihan = kuantitas > 0.0 
        ? (computedTotal > 0.0 ? computedTotal : 0.0)
        : 0.0;
    final price = _formatRupiah(totalTagihan);
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
    final String packageName = paketLayanan['nama_paket'] ?? 'Reguler';

    final bool isEn = TranslationService.currentLang == 'en';
    final String paymentStatus = _getPaymentStatus(order);
    final bool isPaid = paymentStatus == 'Lunas' && kuantitas > 0.0;

    final String rawStatus = (statusInfo['raw_status'] ?? '').toString().toLowerCase();
    final bool isCancelled = rawStatus.contains('batal') || rawStatus.contains('tolak') || rawStatus.contains('reject');

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
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: navyColor,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      isEn ? 'Order Details' : 'Detail Pesanan',
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Progress Stepper Card (always shown, with all red cross icons if cancelled)
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
                        isCancelled: isCancelled,
                      ),
                      const SizedBox(height: 16),

                      // 2. Employee card — shown in ALL states if karyawan is assigned
                      if (order['Karyawan'] != null &&
                          (order['Karyawan']['id_karyawan'] as int? ?? 0) > 0) ...[
                        _buildEmployeeCard(order: order, isEn: isEn),
                        const SizedBox(height: 16),
                      ],

                      // 3. Interactive flow logic:
                      // If cancelled, show final finalized receipt details directly without review steps
                      if (isCancelled) ...[
                        _buildReceiptSection(
                          order: order,
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
                      ] else if (!isPaid) ...[
                        _buildReviewOrderCard(
                          mainService: mainService,
                          packageName: packageName,
                          perfumeName: perfumeName,
                          pickupAddr: pickupAddr,
                          deliveryAddr: deliveryAddr,
                          pickupDate: _formatDate(order['jadwal_pickup']),
                          logistikType: order['tipe_logistik'] ?? 'Courier Delivery',
                          isEn: isEn,
                          hargaPerSatuan: hargaPerSatuan,
                          biayaTambahan: biayaTambahan,
                        ),
                        const SizedBox(height: 16),
                        _buildDeliveryLocationSection(isEn),
                        const SizedBox(height: 16),
                        _buildPromoCard(subtotalCucian, isEn),
                        const SizedBox(height: 16),
                        _buildChoosePaymentMethodCard(isEn),
                        const SizedBox(height: 16),
                        _buildPriceSummaryCard(
                          subtotalCucian: subtotalCucian,
                          biayaTambahan: biayaTambahan,
                          promoDiscount: promoDiscount,
                          totalTagihan: totalTagihan,
                          kuantitas: kuantitas,
                          hargaPerSatuan: hargaPerSatuan,
                          packageName: packageName,
                          promoCode: _isPromoApplied ? _appliedPromoCode : (order['PromoOrder'] != null && (order['PromoOrder'] as List).isNotEmpty ? ((order['PromoOrder'] as List).first['Promo']?['code']?.toString() ?? '') : ''),
                          isEn: isEn,
                        ),
                      ] else ...[
                        // If paid, show the static finalized receipt and schedule card
                        _buildScheduleCard(
                          pickupDate: estDate,
                          pickupAddr: pickupAddr,
                          deliveryAddr: deliveryAddr,
                          logistikType: order['tipe_logistik'] ?? 'Courier Delivery',
                          navyColor: navyColor,
                        ),
                        const SizedBox(height: 16),
                        _buildReceiptSection(
                          order: order,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _buildStickyActionFooter(
        navyColor: navyColor,
        isEn: isEn,
        isPaid: isPaid,
        isCancelled: isCancelled,
        totalTagihan: totalTagihan,
        promoDiscount: promoDiscount,
      ),
    );
  }

  // --- COUPE SHEET PROMO SELECTOR (Shopee/Tokopedia Style) ---
  void _showPromoSelectorBottomSheet(double subtotalCucian) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool isEn = TranslationService.currentLang == 'en';
            final List<Map<String, dynamic>> availablePromos = [
              {
                'code': 'WISHWASH50',
                'title': isEn ? '50% Discount (Save Max Rp 20k)' : 'Diskon 50% (Hemat s/d Rp 20.000)',
                'desc': isEn ? 'Applicable to weight laundry laundry services' : 'Berlaku untuk semua jenis cuci timbang',
                'discount': subtotalCucian * 0.50 > 20000.0 ? 20000.0 : subtotalCucian * 0.50,
              },
              {
                'code': 'HELLOWW',
                'title': isEn ? 'Flat Rp 10k Discount' : 'Potongan Langsung Rp 10.000',
                'desc': isEn ? 'Welcome discount for new customers!' : 'Diskon selamat datang pelanggan baru!',
                'discount': subtotalCucian > 10000.0 ? 10000.0 : subtotalCucian,
              },
              {
                'code': 'FREEDELIV',
                'title': isEn ? 'Free Delivery Surcharge' : 'Bebas Biaya Pengantaran Kurir',
                'desc': isEn ? 'Deducts Rp 8k for reguler package courier delivery' : 'Potongan langsung Rp 8.000 untuk pengiriman paket reguler',
                'discount': 8000.0,
              },
            ];

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Select Promo' : 'Pilih Voucher Promo',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _appliedPromoDiscount = 0.0;
                            _isPromoApplied = false;
                            _appliedPromoCode = '';
                            _promoController.clear();
                            _promoError = '';
                          });
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                        child: Text(
                          isEn ? 'Reset' : 'Hapus',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Manual Promo Input Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: bgGrey,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _promoError.isNotEmpty ? Colors.red.shade400 : Colors.grey.shade300,
                              width: _promoError.isNotEmpty ? 1.5 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _promoController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: isEn ? 'Enter promo code...' : 'Masukkan kode promo...',
                              hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: navyColor),
                            onChanged: (_) {
                              if (_promoError.isNotEmpty) {
                                setModalState(() {
                                  _promoError = '';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navyColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          onPressed: () {
                            _applyPromoCode(subtotalCucian);
                            if (_isPromoApplied) {
                              Navigator.pop(context);
                            } else {
                              setModalState(() {});
                            }
                          },
                          child: Text(
                            isEn ? 'Apply' : 'Gunakan',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_promoError.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _promoError,
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availablePromos.length,
                      itemBuilder: (context, index) {
                        final promo = availablePromos[index];
                        final String code = promo['code'];
                        final bool isCurrent = _appliedPromoCode == code;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent ? cyanColor : Colors.grey.shade200,
                              width: isCurrent ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Banner(
                              message: isEn ? 'OFFER' : 'PROMO',
                              location: BannerLocation.topEnd,
                              color: cyanColor,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _appliedPromoDiscount = promo['discount'];
                                    _isPromoApplied = true;
                                    _appliedPromoCode = code;
                                    _promoController.text = code;
                                    _promoError = '';
                                  });
                                  setModalState(() {});
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: softTeal.withValues(alpha: 0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.confirmation_num_rounded, color: navyColor, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              promo['title'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: navyColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              promo['desc'],
                                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: bgGrey,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'CODE: $code',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: navyColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isCurrent ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                        color: isCurrent ? cyanColor : Colors.grey.shade300,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

  // --- ADDRESS SELECTOR BOTTOM SHEET (Premium Interactive) ---
  void _showAddressSelectorBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (BuildContext context) {
        final bool isEn = TranslationService.currentLang == 'en';
        final List<Map<String, String>> mockAddresses = [
          {
            'tag': isEn ? 'Home (Rumah)' : 'Rumah (Mark Lee)',
            'address': 'Jalan Kesana Kesini, No. 12, Semarang, Central Java, 123456',
          },
          {
            'tag': isEn ? 'Office (Kantor)' : 'Kantor (WishWash Center)',
            'address': 'Jalan Raya Laundry No. 99, Tembalang, Semarang, Central Java, 50275',
          },
          {
            'tag': isEn ? 'Green Wish Boarding House (Kos)' : 'Kos (Green Wish, Gang Melati)',
            'address': 'Gang Melati No. 5, Tembalang, Kota Semarang, Central Java, 50272',
          },
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEn ? 'Choose Shipping Address' : 'Pilih Alamat Pengiriman',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mockAddresses.length,
                  itemBuilder: (context, index) {
                    final item = mockAddresses[index];
                    final String addressText = item['address']!;
                    final String tagText = item['tag']!;
                    final bool isCurrent = _currentOrder['AlamatPenyerahan'] != null &&
                        _currentOrder['AlamatPenyerahan']['alamat_lengkap'] == addressText;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: bgGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent ? cyanColor : Colors.grey.shade200,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentOrder['AlamatPenyerahan'] = {
                              'alamat_lengkap': addressText,
                            };
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: isCurrent ? cyanColor : navyColor, size: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tagText,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: navyColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      addressText,
                                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isCurrent ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: isCurrent ? cyanColor : Colors.grey.shade300,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- REVIEW ORDER CARD ---
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
  }) {
    final bool isDropOff = _currentOrder['tipe_logistik'] == 'Drop-off';
    final double kuantitasVal = (_currentOrder['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String qtyText = kuantitasVal == 0.0
        ? (isEn ? 'Pending Weight' : 'Menunggu Timbang')
        : '$kuantitasVal kg';

    final String catatan = _currentOrder['catatan_order'] != null && _currentOrder['catatan_order'].toString().isNotEmpty
        ? _currentOrder['catatan_order'].toString()
        : '';

    final String orderDate = _formatDate(_currentOrder['tgl_pesanan']);
    final String estDate = _getEstSelesaiDate(_currentOrder);

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: navyColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.fact_check_rounded, color: navyColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                isEn ? 'Review Order' : 'Tinjau Pesanan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
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

          // Notes Section (Instruksi Khusus) - Consistent in color and placed above Timeline Details Grid
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
                  // Pick up date is shown if not walk-in
                  _buildDetailRow(isEn ? 'Pick Up Date' : 'Tanggal Penjemputan', pickupDate, Icons.airport_shuttle_rounded),
                  const Divider(height: 20),
                  
                  // Pickup address is shown if not walk-in
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
                    addresses.isNotEmpty && addresses.firstWhere((e) => e['is_primary'] == true, orElse: () => addresses.first) != null
                        ? (() {
                            final primaryAddr = addresses.firstWhere((e) => e['is_primary'] == true, orElse: () => addresses.first);
                            return '${primaryAddr['alamat_lengkap']} (${primaryAddr['tipe_alamat']}) - Penerima: ${primaryAddr['nama_penerima']}';
                          })()
                        : deliveryAddr,
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

  // --- DELIVERY LOCATION SECTION (Consistent with LaundryOrderScreen) ---
  Widget _buildDeliveryLocationSection(bool isEn) {
    final bool isDropOff = _currentOrder['tipe_logistik'] == 'Drop-off';
    
    final address = addresses.isNotEmpty
        ? addresses.firstWhere(
            (element) => element['is_primary'] == true,
            orElse: () => addresses.first,
          )
        : null;

    final String finalDeliveryAddr = address != null
        ? '${address['alamat_lengkap']} (${address['tipe_alamat']}) - Penerima: ${address['nama_penerima']}'
        : (isEn ? 'Address Not Selected Yet' : 'Alamat Pengiriman Belum Terpilih');

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: navyColor, size: 22),
              const SizedBox(width: 8),
              Text(
                isEn ? 'Delivery Location' : 'Lokasi Pengiriman',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Dark Navy Map Placeholder (identical to LaundryOrderScreen) ---
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0D253F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: DeliveryMapPainter()),
                ),
                // GPS ACTIVE Badge
                Positioned(
                  bottom: 10,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0C4B8E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GPS ACTIVE',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pulsing Center Locator Pin
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: navyColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: navyColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: navyColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: navyColor,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!isDropOff) ...[
            // --- COURIER DELIVERY STATE ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: navyColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on_rounded, color: navyColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Delivery Address' : 'Alamat Pengiriman',
                        style: GoogleFonts.poppins(
                          color: navyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoadingAddresses
                            ? (isEn ? 'Loading address...' : 'Memuat alamat...')
                            : addresses.isNotEmpty
                                ? finalDeliveryAddr
                                : (isEn
                                    ? 'Address not set. Tap button to add.'
                                    : 'Alamat belum disetel. Ketuk tombol untuk menambahkan.'),
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _chooseAddress,
                        icon: Icon(
                          addresses.isNotEmpty ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                          size: 14,
                        ),
                        label: Text(
                          addresses.isNotEmpty
                              ? (isEn ? 'Change Address' : 'Ubah Alamat')
                              : (isEn ? 'Add Address' : 'Tambah Alamat'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: navyColor,
                          side: BorderSide(color: navyColor.withValues(alpha: 0.5), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            // Toggle → Pick Up in Store
            InkWell(
              onTap: () {
                _updateLogisticsBackend('Drop-off');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade400, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEn ? 'Pick Up in Store Instead' : 'Ambil Sendiri di Toko',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_right_rounded, color: Colors.orange.shade800, size: 22),
                  ],
                ),
              ),
            ),
          ] else ...[
            // --- DROP-OFF / PICK UP IN STORE STATE ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: navyColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.storefront_rounded, color: navyColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Store Pickup Address' : 'Alamat Toko (Drop-off)',
                        style: GoogleFonts.poppins(
                          color: navyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'WishWash Laundry Utama\nJalan Raya Laundry No. 99, Tembalang, Semarang, Central Java',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            // Toggle → Use Courier Delivery
            InkWell(
              onTap: () {
                final primary = addresses.isNotEmpty
                    ? addresses.firstWhere((e) => e['is_primary'] == true, orElse: () => addresses.first)
                    : null;
                _updateLogisticsBackend('Courier Delivery', idAlamatPenyerahan: primary != null ? primary['id_alamat'] : null);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade400, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.delivery_dining_rounded, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEn ? 'Use Courier Delivery' : 'Gunakan Pengiriman Kurir',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_right_rounded, color: Colors.orange.shade800, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- PROMO CODE CARD (Shopee/Tokopedia Style Coupon Picker) ---
  Widget _buildPromoCard(double subtotalCucian, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEn ? 'Promo Code / Voucher' : 'Kode Promo / Voucher',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navyColor,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showPromoSelectorBottomSheet(subtotalCucian),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPromoApplied ? cyanColor : Colors.grey.shade300,
                  width: _isPromoApplied ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: _isPromoApplied ? cyanColor : Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPromoApplied 
                              ? (isEn ? 'Voucher Applied: $_appliedPromoCode' : 'Promo Terpasang: $_appliedPromoCode')
                              : (isEn ? 'Use promo voucher to save more' : 'Pilih promo untuk hemat lebih banyak!'),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isPromoApplied ? cyanColor : navyColor,
                          ),
                        ),
                        if (_isPromoApplied) ...[
                          const SizedBox(height: 2),
                          Text(
                            isEn 
                                ? 'Saving: -${_formatRupiah(_appliedPromoDiscount)}'
                                : 'Hemat: -${_formatRupiah(_appliedPromoDiscount)}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey.shade600, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // --- PRICE SUMMARY CARD ---
  Widget _buildPriceSummaryCard({
    required double subtotalCucian,
    required double biayaTambahan,
    required double promoDiscount,
    required double totalTagihan,
    required double kuantitas,
    required double hargaPerSatuan,
    required String packageName,
    required String promoCode,
    required bool isEn,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                child: Icon(Icons.receipt_long_rounded, color: navyColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                isEn ? 'Payment Summary' : 'Rincian Pembayaran',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
            textColor: promoDiscount > 0.0 ? Colors.red.shade700 : const Color(0xFF2D3748),
          ),
          _buildDashedDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEn ? 'TOTAL BILL' : 'TOTAL TAGIHAN',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D3748),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _formatRupiah(totalTagihan),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D3748),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // --- CHOOSE PAYMENT METHOD CARD ---
  Widget _buildChoosePaymentMethodCard(bool isEn) {
    final bool isDropOff = _currentOrder['tipe_logistik'] == 'Drop-off';
    
    // Dynamic Cash payment label based on logistics method (Ambil di Toko / Antar ke Rumah)
    final String cashLabel = isDropOff
        ? (isEn ? 'Cash at Store (Pay when picking up)' : 'Bayar Tunai di Toko (Saat Ambil)')
        : (isEn ? 'Cash (Pay to Courier)' : 'Bayar Tunai ke Kurir (Cash)');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEn ? 'Pilih Cara Pembayaran' : 'Metode Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navyColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentMethodTile(
            methodId: 'QRIS',
            label: 'QRIS',
            icon: Icons.qr_code_scanner_rounded,
          ),
          const SizedBox(height: 10),
          _buildPaymentMethodTile(
            methodId: 'COD',
            label: cashLabel,
            icon: Icons.payments_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String methodId,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _selectedPaymentMethod == methodId;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = methodId;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? softTeal.withValues(alpha: 0.15) : bgGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cyanColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? navyColor : Colors.grey.shade500),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? navyColor : Colors.black87,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? cyanColor : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? cyanColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
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
          // Stepper Tracker
          (() {
            final lang = TranslationService.currentLang;
            final List<Map<String, dynamic>> refStatuses = statusInfo['statuses'];
            final int activeIdx = statusInfo['active_index'];
            final bool isSelesai = statusInfo['is_selesai'] == true;

            List<Widget> steps = [];
            for (int i = 0; i < refStatuses.length; i++) {
              final rawName = refStatuses[i]['nama_status'] ?? '';
              final String shortLabel = _getShortStatusLabel(rawName, lang, isCancelled: isCancelled);
              
              final bool isDone = i < activeIdx || (isSelesai && i == refStatuses.length - 1) || (i == 0 && activeIdx > 0);
              final bool isCurrent = i == activeIdx && !isSelesai;
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

  Widget _buildScheduleCard({
    required String pickupDate,
    required String pickupAddr,
    required String deliveryAddr,
    required String logistikType,
    required Color navyColor,
  }) {
    final bool isDropOff = logistikType == 'Drop-off';
    final bool isEn = TranslationService.currentLang == 'en';
    final String translatedLogistik = logistikType.toLowerCase().contains('drop')
        ? 'Drop-off'
        : (isEn ? 'Courier Delivery' : 'Pengiriman Kurir');

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
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Delivery' : 'Pengantaran',
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

  // --- EMPLOYEE PROFILE CARD ---
  Widget _buildEmployeeCard({
    required Map<String, dynamic> order,
    required bool isEn,
  }) {
    final karyawan = order['Karyawan'] as Map<String, dynamic>;
    final String name = (karyawan['nama_karyawan'] ?? '-').toString();
    final String phone = (karyawan['no_telp'] ?? '-').toString();
    final String vehicle = (karyawan['jenis_kendaraan'] ?? '').toString();
    final String plate = (karyawan['plat_nomor'] ?? '').toString();
    final String rawFoto = (karyawan['foto_karyawan'] ?? '').toString();

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
    final List<String> nameParts = name.trim().split(' ');
    final String initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : (nameParts.isNotEmpty && nameParts[0].isNotEmpty
            ? nameParts[0][0].toUpperCase()
            : '?');

    final bool hasVehicle = vehicle.isNotEmpty;
    final bool hasPlate = plate.isNotEmpty;
    final bool hasPhone = phone.isNotEmpty && phone != '-';

    Future<void> openWhatsApp() async {
      if (!hasPhone) return;
      // Strip non-digit chars, add 62 prefix
      String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.startsWith('0')) cleaned = '62${cleaned.substring(1)}';
      final uri = Uri.parse('https://wa.me/$cleaned');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42C6D4).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: Color(0xFF0C4B8E),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEn ? 'COURIER PARTNER' : 'MITRA KARYAWAN',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: const Color(0xFF0C4B8E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '4.9 (42)',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar circle with actual photo
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
                      name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF0C4B8E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (hasVehicle || hasPlate)
                      Row(
                        children: [
                          const Icon(Icons.two_wheeler_rounded, size: 13, color: Color(0xFF718096)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              [if (hasVehicle) vehicle, if (hasPlate) plate].join(' \u2022 '),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF4A5568),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    if (hasPhone)
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF718096)),
                          const SizedBox(width: 5),
                          Text(
                            phone,
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
              // WhatsApp Chat button
              if (hasPhone)
                GestureDetector(
                  onTap: openWhatsApp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25D366).withValues(alpha: 0.25),
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
                          isEn ? 'Chat' : 'Chat',
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
    double promoDiscount = _isPromoApplied ? _appliedPromoDiscount : 0.0;
    String promoCode = _isPromoApplied ? _appliedPromoCode : '';

    if (promoDiscount == 0.0 && promoOrders.isNotEmpty) {
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

    final Color charBlack = const Color(0xFF2D3748);
    final Color slateGray = const Color(0xFF718096);

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
                    _buildReceiptRow(isEn ? 'Employee / Courier' : 'Karyawan', employeeName),
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

  Widget _buildStickyActionFooter({
    required Color navyColor,
    required bool isEn,
    required bool isPaid,
    required bool isCancelled,
    required double totalTagihan,
    required double promoDiscount,
  }) {
    if (isCancelled) {
      return const SizedBox.shrink();
    }
    // If PAID, show the standard finalized "Download Receipt" footer
    if (isPaid) {
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
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
          ],
        ),
      );
    }

    // If NOT PAID, show interactive Pay Now (QRIS) or Confirm COD button
    final bool isQRIS = _selectedPaymentMethod == 'QRIS';
    final double kuantitasVal = (_currentOrder['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final bool isNotWeighed = kuantitasVal == 0.0;

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
          if (isNotWeighed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEEBA), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn
                          ? 'Awaiting clothes weighing by store/courier to determine final bill.'
                          : 'Belum bisa membayar. Menunggu pakaian ditimbang untuk menentukan total harga.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Total Bill' : 'Total Tagihan',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isNotWeighed
                          ? (isEn ? 'Pending Weight' : 'Menunggu Timbang')
                          : _formatRupiah(totalTagihan),
                      style: GoogleFonts.poppins(
                        fontSize: isNotWeighed ? 14 : 16,
                        fontWeight: FontWeight.w900,
                        color: isNotWeighed ? Colors.grey.shade600 : navyColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNotWeighed
                        ? Colors.grey.shade300
                        : (isQRIS ? navyColor : Colors.green.shade700),
                    foregroundColor: isNotWeighed ? Colors.grey.shade500 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: isNotWeighed ? 0 : 4,
                    shadowColor: isNotWeighed
                        ? Colors.transparent
                        : (isQRIS ? navyColor : Colors.green.shade700).withValues(alpha: 0.4),
                  ),
                  onPressed: isNotWeighed
                      ? null
                      : () {
                          if (isQRIS) {
                            // Navigate to our premium dynamic QRIS Payment Screen!
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  order: _currentOrder,
                                  promoDiscount: promoDiscount,
                                  totalTagihan: totalTagihan,
                                  paymentMethod: 'QRIS',
                                ),
                              ),
                            );
                          } else {
                            // Confirm Cash Payment with beautiful modern custom Dialog
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Premium Top Icon with soft green gradient circular base
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50.withValues(alpha: 0.8),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.green.shade100, width: 2),
                                        ),
                                        child: Icon(
                                          Icons.payments_rounded,
                                          color: Colors.green.shade700,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Bold Premium Title
                                      Text(
                                        isEn ? 'Confirm Cash Payment' : 'Konfirmasi Bayar Cash',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: navyColor,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Informative content
                                      Text(
                                        isEn
                                            ? 'You choose to pay cash. The total bill is payable directly to our courier / outlet staff.'
                                            : 'Anda memilih pembayaran secara Tunai (Cash). Total tagihan dapat dibayarkan langsung secara tunai.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Total Tagihan Card
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: bgGrey,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey.shade100),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              isEn ? 'TOTAL BILL' : 'TOTAL TAGIHAN',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade500,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatRupiah(totalTagihan),
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Buttons Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(
                                                isEn ? 'Cancel' : 'Batal',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green.shade700,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                try {
                                                  // Actually update the backend with CASH payment method!
                                                  final updatedOrder = await OrderService.updateOrder(
                                                    _currentOrder['id_order'],
                                                    {
                                                      'status_pembayaran': 'Belum Lunas',
                                                      'metode_bayar': 'CASH',
                                                    },
                                                  );
                                                  setState(() {
                                                    _currentOrder = Map<String, dynamic>.from(updatedOrder);
                                                  });
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          isEn
                                                              ? 'Cash payment method confirmed successfully!'
                                                              : 'Metode Pembayaran Cash berhasil dikonfirmasi!',
                                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                                        ),
                                                        backgroundColor: Colors.green.shade700,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          isEn
                                                              ? 'Failed to confirm payment method: $e'
                                                              : 'Gagal mengonfirmasi metode pembayaran: $e',
                                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                                        ),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: Text(
                                                isEn ? 'Confirm' : 'Konfirmasi',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  icon: Icon(
                    isQRIS ? Icons.qr_code_scanner_rounded : Icons.payments_rounded,
                    size: 16,
                    color: isNotWeighed ? Colors.grey.shade500 : Colors.white,
                  ),
                  label: Text(
                    isQRIS
                        ? (isEn ? 'Pay Now' : 'Bayar')
                        : (isEn ? 'Confirm' : 'Konfirmasi'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isNotWeighed ? Colors.grey.shade500 : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeliveryMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final paintRoad = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintAccentRoad = Paint()
      ..color = const Color(0xFF42C6D4).withValues(alpha: 0.4)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double j = 0; j < size.height; j += 20) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paintGrid);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.3, size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height)
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.2, size.height)
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.7);

    canvas.drawPath(path, paintRoad);

    final routePath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width, size.height * 0.8);
    canvas.drawPath(routePath, paintAccentRoad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}