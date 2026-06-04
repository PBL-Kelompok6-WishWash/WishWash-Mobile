import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/splash_screen.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/notifikasi.dart';
import 'package:mobile/screens/pelanggan/chat/chat_screen.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/screens/pelanggan/profile/profile_screen.dart';
import 'package:mobile/screens/pelanggan/home/alamat_screen.dart';
import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/services/layanan_service.dart';
import 'package:mobile/screens/pelanggan/create_order/laundry_order_screen.dart';
import 'package:mobile/screens/pelanggan/create_order/create_order_screen.dart';
import 'package:mobile/services/order_service.dart';
import 'dart:convert';
import 'package:mobile/utils/constants.dart';
import 'package:mobile/screens/pelanggan/orders/order_detail_screen.dart';
import 'package:mobile/screens/pelanggan/home/detail_promo.dart';
import 'package:mobile/services/promo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    const MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class PelangganHomeScreen extends StatefulWidget {
  final bool showNavbar;
  final bool showOrderSuccessNotification;
  final VoidCallback? onProfileTap;
  final VoidCallback? onViewOrdersTap;
  const PelangganHomeScreen({
    super.key, 
    this.showNavbar = true, 
    this.showOrderSuccessNotification = false,
    this.onProfileTap,
    this.onViewOrdersTap,
  });

  @override
  State<PelangganHomeScreen> createState() => PelangganHomeScreenState();
}

class PelangganHomeScreenState extends State<PelangganHomeScreen> {
  int _currentPromoIndex = 0;
  int _currentActiveOrderIndex = 0;
  bool _isLocationMenuOpen = false;

  final PageController _promoController = PageController(viewportFraction: 0.9);
  final PageController _activeOrderController = PageController();

  String _namaLengkap = 'User';
  String _fotoPelanggan = '';
  String _alamatLengkap = 'Memuat alamat...';
  String _tipeAlamat = 'Rumah';
  List<dynamic> _services = [];
  bool _isLoadingServices = true;
  bool _isSeeAllPressed = false;
  bool _isNotificationVisible = false;
  List<dynamic> _activeOrders = [];
  bool _isLoadingActiveOrders = true;
  List<dynamic> _promos = [];
  bool _isLoadingPromos = true;
  List<String> _claimedPromoIds = [];

  @override
  void initState() {
    super.initState();
    _isNotificationVisible = widget.showOrderSuccessNotification;
    if (_isNotificationVisible) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isNotificationVisible = false;
          });
        }
      });
    }
    _loadClaimedPromos();
    _fetchProfileData();
    _fetchServicesData();
    _fetchActiveOrders();
    _fetchPromosData();
  }

  void closeDropdown() {
    if (mounted && _isLocationMenuOpen) {
      setState(() {
        _isLocationMenuOpen = false;
      });
    }
  }

  void reloadProfileAndServices() {
    _loadClaimedPromos();
    _fetchProfileData();
    _fetchServicesData();
    _fetchActiveOrders();
    _fetchPromosData();
  }

  Future<void> _loadClaimedPromos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _claimedPromoIds = prefs.getStringList('claimed_promo_ids') ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error loading claimed promos: $e");
    }
  }

  Future<void> _claimPromo(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList('claimed_promo_ids') ?? [];
      if (!current.contains(id)) {
        current.add(id);
        await prefs.setStringList('claimed_promo_ids', current);
        if (mounted) {
          setState(() {
            _claimedPromoIds = current;
          });
        }
      }
    } catch (e) {
      debugPrint("Error claiming promo: $e");
    }
  }

  Future<void> _fetchServicesData() async {
    try {
      final servicesData = await LayananService.getLayanan();
      if (mounted) {
        setState(() {
          _services = servicesData.where((s) {
            final status = s['status_layanan']?.toString() ?? 'Aktif';
            return status.toLowerCase() == 'aktif';
          }).toList();
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil data layanan: $e");
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  Future<void> _fetchPromosData() async {
    try {
      final promosData = await PromoService.getPromos();
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          _promos = promosData.where((p) {
            final status = p['status_promo']?.toString() ?? 'Aktif';
            if (status.toLowerCase() != 'aktif') return false;

            final tglBerakhirStr = p['tgl_berakhir']?.toString();
            if (tglBerakhirStr != null && tglBerakhirStr.isNotEmpty) {
              try {
                final tglBerakhir = DateTime.parse(tglBerakhirStr);
                if (tglBerakhir.isBefore(now)) {
                  return false;
                }
              } catch (e) {
                debugPrint("Error parsing tgl_berakhir: $e");
              }
            }
            return true;
          }).toList();
          _isLoadingPromos = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil data promo: $e");
      if (mounted) {
        setState(() {
          _isLoadingPromos = false;
        });
      }
    }
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF00BCD4); // fallback
    }
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
      } else if (hsl.hue >= 70 && hsl.hue <= 150) {
        targetLightness = 0.30; // Deep Forest Green for Green
      } else if (hsl.hue >= 170 && hsl.hue <= 200) {
        targetLightness = 0.35; // Rich Oceanic Teal for Cyan
      }
      return hsl.withLightness(targetLightness).toColor();
    }
    return color;
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await PelangganService.getProfile();
      if (response['success'] == true) {
        final data = response['data'];
        final pelanggan = data['pelanggan'] ?? {};
        
        if (mounted) {
          setState(() {
            _namaLengkap = pelanggan['nama_lengkap'] ?? 'User';
            _fotoPelanggan = pelanggan['foto_pelanggan'] ?? '';
            final alamat = data['alamat_lengkap'];
            _alamatLengkap = (alamat == null || alamat.toString().trim().isEmpty) 
                ? 'Alamat belum diatur' 
                : alamat.toString();
            _tipeAlamat = data['tipe_alamat'] ?? 'Rumah';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _alamatLengkap = 'Gagal memuat alamat';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alamatLengkap = 'Koneksi bermasalah';
        });
      }
    }
  }

  Future<void> _fetchActiveOrders() async {
    try {
      final orders = await OrderService.getOrders();
      if (mounted) {
        setState(() {
          _activeOrders = orders.where((order) {
            final historyList = order['RiwayatStatusDetail'];
            if (historyList == null || historyList is! List || historyList.isEmpty) {
              return true; // Active if no history
            }
            List<dynamic> sorted = List.from(historyList);
            sorted.sort((a, b) => (a['id_riwayat_status_detail'] as num? ?? 0)
                .compareTo(b['id_riwayat_status_detail'] as num? ?? 0));
            final latest = sorted.last;
            final ref = latest['ReferensiStatus'] ?? {};
            final String rawStatus = (ref['nama_status'] ?? '').toString().toLowerCase();
            return !rawStatus.contains('selesai') && !rawStatus.contains('completed') && !rawStatus.contains('success');
          }).toList();
          _isLoadingActiveOrders = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil data order aktif: $e");
      if (mounted) {
        setState(() {
          _isLoadingActiveOrders = false;
        });
      }
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

    // If the order has status 'Pesanan Diterima', keep the active dot at index 0 (Diterima)
    if (activeIndex == 0 && refStatuses.length > 1) {
      activeIndex = 0;
    }

    // Check if the latest status in history is "Selesai" and if it was updated by a Karyawan
    bool isCompletedByKaryawanOnly = false;
    if (historyList != null && historyList is List && historyList.isNotEmpty) {
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
                           rawStatus.toLowerCase().contains('success')) &&
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        final double statusBarHeight = MediaQuery.of(context).padding.top;
        return Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFFF8FBFC),
          body: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  color: const Color(0xFF0C4B8E),
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await Future.wait([
                      _fetchProfileData(),
                      _fetchServicesData(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Stack(
                      children: [
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
                        Padding(
                          padding: EdgeInsets.only(
                            top: statusBarHeight + 20,
                            bottom: 140,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: _buildHeader(),
                              ),
                              const SizedBox(height: 24),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    children: [
                                     Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            splashColor: const Color(0xFF0C4B8E).withValues(alpha: 0.12),
                                            highlightColor: const Color(0xFF0C4B8E).withValues(alpha: 0.06),
                                            onTap: () {
                                              setState(() {
                                                _isLocationMenuOpen = !_isLocationMenuOpen;
                                              });
                                            },
                                            child: _buildLocationCard(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  // Slider diletakkan di luar padding horizontal utama agar bisa 'bleeding' ke pinggir
                                  _buildPromoSlider(),
                                  const SizedBox(height: 8),
                                  _buildDotIndicator(),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: _buildServicesSection(),
                                        ),
                                        if (_isLoadingActiveOrders || _activeOrders.isNotEmpty) ...[
                                          const SizedBox(height: 20),
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.04),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: _buildOrderStatusSection(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOutBack,
                                top: _isLocationMenuOpen ? 64 : 35,
                                left: 20,
                                right: 20,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: _isLocationMenuOpen ? 1.0 : 0.0,
                                  child: IgnorePointer(
                                    ignoring: !_isLocationMenuOpen,
                                    child: _buildExpandedLocationCard(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
              if (_isNotificationVisible)
                Positioned(
                  top: statusBarHeight + 20,
                  left: 20,
                  right: 20,
                  child: _buildOrderSuccessBanner(),
                ),
            ],
          ),
      bottomNavigationBar: widget.showNavbar ? BottomNavbar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const PelangganHomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const ChatScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const ProfileScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
      ) : null,
    );
  },
);
  }

   // --- REVISI UTAMA: PROMO SLIDER ---
  Widget _buildPromoSlider() {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    
    if (_isLoadingPromos) {
      return SizedBox(
        height: isTablet ? 240 : 180,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_promos.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>> promoStyles = [
      {
        'bgColor': const Color(0xFFE3F9FD),
        'btnColor': const Color(0xFF42C6D4),
        'textColor': const Color(0xFF0C4B8E),
        'imagePath': 'assets/images/promos/diskon.png',
      },
      {
        'bgColor': const Color(0xFFFDEEF6),
        'btnColor': const Color(0xFFE91E63),
        'textColor': const Color(0xFF880E4F),
        'imagePath': 'assets/images/promos/free_deliv.png',
      },
      {
        'bgColor': const Color(0xFFE8F5E9),
        'btnColor': const Color(0xFF4CAF50),
        'textColor': const Color(0xFF1B5E20),
        'imagePath': 'assets/images/promos/diskon.png',
      },
      {
        'bgColor': const Color(0xFFFFF3E0),
        'btnColor': const Color(0xFFFF9800),
        'textColor': const Color(0xFFE65100),
        'imagePath': 'assets/images/promos/free_deliv.png',
      },
    ];

    return SizedBox(
      height: isTablet ? 240 : 180,
      child: PageView.builder(
        controller: _promoController,
        onPageChanged: (index) => setState(() => _currentPromoIndex = index),
        itemCount: _promos.length,
        itemBuilder: (context, index) {
          final promo = _promos[index];
          final style = promoStyles[index % promoStyles.length];
          return _buildPromoItem(
            promo,
            style['bgColor'] as Color,
            style['btnColor'] as Color,
            style['imagePath'] as String,
            style['textColor'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildPromoItem(
    Map<String, dynamic> promo,
    Color bgColor,
    Color btnColor,
    String defaultImagePath,
    Color textColor,
  ) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    final String title = promo['nama_promo'] ?? '';
    final String subtitle = promo['deskripsi'] ?? '';
    final String rawImage = promo['gambar_promo'] ?? '';
    final String promoId = promo['id_promo']?.toString() ?? '';
    final bool isClaimed = _claimedPromoIds.contains(promoId);

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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPromoScreen(
              promoData: promo,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: isTablet ? 10 : -10,
              bottom: 0,
              child: SizedBox(
                width: isTablet ? 200 : 140,
                height: isTablet ? 200 : 140,
                child: imageWidget,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isTablet ? 32 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 11,
                      color: textColor.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  if (!isClaimed) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: btnColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _claimPromo(promoId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                TranslationService.currentLang == 'en'
                                    ? 'Promo claimed successfully!'
                                    : 'Promo berhasil diklaim!',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(100, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          title.toLowerCase().contains('free') || title.toLowerCase().contains('gratis') 
                              ? 'Check Now' 
                              : 'Claim Now',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSuccessBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'W',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF42C6D4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your Order is Confirmed',
                      style: TextStyle(
                        color: Color(0xFF0C4B8E),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'please proceed with payment',
                      style: TextStyle(
                        color: const Color(0xFF0C4B8E).withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    ImageProvider? imageProvider;
    if (_fotoPelanggan.startsWith('http://') || _fotoPelanggan.startsWith('https://')) {
      imageProvider = NetworkImage(_fotoPelanggan);
    } else if (_fotoPelanggan.startsWith('data:image')) {
      try {
        final base64Content = _fotoPelanggan.split(',').last;
        final bytes = base64Decode(base64Content);
        imageProvider = MemoryImage(bytes);
      } catch (e) {
        debugPrint("Error base64 avatar: $e");
      }
    } else if (_fotoPelanggan.startsWith('/uploads/')) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      imageProvider = NetworkImage('$staticHost$_fotoPelanggan');
    } else if (_fotoPelanggan.isNotEmpty) {
      imageProvider = AssetImage(_fotoPelanggan);
    }

    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFEBF8FA),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? const Icon(
                Icons.person_rounded,
                color: Color(0xFF0C4B8E),
                size: 26,
              )
            : null,
      ),
    );
  }

  // --- SISANYA TETAP SAMA (WIDGET LAINNYA) ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Avatar + Welcome Text (Vertically Centered)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.onProfileTap != null) {
                    widget.onProfileTap!();
                  } else {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const ProfileScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }
                },
                child: _buildProfileAvatar(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_namaLengkap!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D47A1),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TranslationService.currentLang == 'en'
                          ? 'Which laundry service do you need today?'
                          : 'Layanan laundry mana yang Anda butuhkan hari ini?',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0C4B8E).withValues(alpha: 0.65),
                        
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right: Circular Notification Icon
        _buildNotificationIcon(),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationScreen()),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0C4B8E),
              size: 26,
            ),
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30), // Premium Apple iOS Red
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTipeAlamat() {
    switch (_tipeAlamat) {
      case 'Rumah':
        return Icons.home_outlined;
      case 'Kantor':
        return Icons.business_outlined;
      default:
        return Icons.bookmark_border_rounded;
    }
  }

  String _getTranslatedTipeAlamat(String tipe) {
    if (tipe == 'Rumah') return TranslationService.translate('home_tag');
    if (tipe == 'Kantor') return TranslationService.translate('office_tag');
    if (tipe == 'Lainnya') return TranslationService.translate('other_tag');
    return tipe;
  }

  Widget _buildLocationCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Image.asset('assets/images/icons/icon_location.png', width: 20, height: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _alamatLengkap == 'Alamat belum diatur' 
                  ? TranslationService.translate('address_not_set')
                  : '${_getTranslatedTipeAlamat(_tipeAlamat)} - $_alamatLengkap',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C4B8E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            _isLocationMenuOpen 
                ? Icons.keyboard_arrow_up_rounded 
                : Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF0C4B8E),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF0C4B8E).withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_alamatLengkap != 'Alamat belum diatur') ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() => _isLocationMenuOpen = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlamatScreen()),
                  ).then((_) => _fetchProfileData());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C4B8E).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIconForTipeAlamat(), color: const Color(0xFF0C4B8E), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_getTranslatedTipeAlamat(_tipeAlamat)} - $_alamatLengkap',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C4B8E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: Colors.grey.shade100, height: 1),
            ),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _isLocationMenuOpen = false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlamatScreen()),
                ).then((_) {
                  _fetchProfileData();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F7FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF42C6D4), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '+ ${TranslationService.translate('add_new_address')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42C6D4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    if (_promos.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_promos.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: _currentPromoIndex == index ? 12 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _currentPromoIndex == index
                ? const Color(0xFF0C4B8E)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              TranslationService.translate('our_services'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0D47A1),
              ),
            ),
            GestureDetector(
              onTapDown: (_) {
                setState(() {
                  _isSeeAllPressed = true;
                });
              },
              onTapCancel: () {
                setState(() {
                  _isSeeAllPressed = false;
                });
              },
              onTap: () {
                setState(() {
                  _isSeeAllPressed = true;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                ).then((_) {
                  if (mounted) {
                    setState(() {
                      _isSeeAllPressed = false;
                    });
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  TranslationService.currentLang == 'en' ? 'See All' : 'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0C4B8E),
                    decoration: _isSeeAllPressed ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: const Color(0xFF0C4B8E),
                    decorationThickness: _isSeeAllPressed ? 2.5 : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoadingServices
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            : _services.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Tidak ada layanan yang tersedia',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 3 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: MediaQuery.of(context).size.width >= 600
                          ? 2.3
                          : (MediaQuery.of(context).size.width < 360 ? 1.75 : 2.1),
                    ),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final String rawName = service['nama_layanan'] ?? '';
                      final String name = TranslationService.translateService(rawName);
                      final String hexColor = service['warna_layanan'] ?? '#00BCD4';
                      final String imagePath = service['gambar_layanan'] ?? 'assets/images/services/wash_only.png';

                      // Parse hex color to Flutter Color
                      final Color baseColor = _parseHexColor(hexColor);
                      // Generate background color (soft 15% opacity) & text color
                      final Color bgColor = baseColor.withOpacity(0.15);
                      final Color textColor = _getDarkenedTextColor(baseColor);

                      // Format name to display with newlines
                      String formattedName = name;
                      if (name.contains(' & ')) {
                        formattedName = name.replaceAll(' & ', ' &\n');
                      } else if (name.contains(' and ')) {
                        formattedName = name.replaceAll(' and ', ' and\n');
                      } else if (name.contains(' ')) {
                        formattedName = name.replaceAll(' ', '\n');
                      }

                      final VoidCallback cardOnTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LaundryOrderScreen(service: service),
                          ),
                        );
                      };

                      return _buildServiceCard(
                        formattedName,
                        bgColor,
                        textColor,
                        imagePath,
                        cardOnTap,
                      );
                    },
                  ),
      ],
    );
  }

  Widget _buildServiceCard(
    String title,
    Color bgColor,
    Color textColor,
    String imagePath,
    VoidCallback onTap,
  ) {
    final double cardRadius = 12.0;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: textColor.withOpacity(0.15),
            highlightColor: textColor.withOpacity(0.05),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.black, Colors.transparent],
                      ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                    },
                    blendMode: BlendMode.dstIn,
                    child: _buildServiceImage(imagePath),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 8),
                      child: Text(
                        title,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 20),
      );
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64Content = imagePath.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image, size: 20),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 20);
      }
    } else if (imagePath.startsWith('/uploads/')) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      return Image.network(
        '$staticHost$imagePath',
        fit: BoxFit.cover,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 20),
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 20),
      );
    }
  }

  Color getActiveOrderColor() {
    for (var service in _services) {
      final name = (service['nama_layanan'] ?? '').toString().toLowerCase();
      if ((name.contains('cuci') && name.contains('setrika')) || (name.contains('wash') && name.contains('iron'))) {
        return _parseHexColor(service['warna_layanan'] ?? '#9C27B0');
      }
    }
    return const Color(0xFF9C27B0); // Purple default for "Wash & Iron"
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

  Widget _buildOrderStatusSection() {
    if (_isLoadingActiveOrders) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C4B8E)),
          ),
        ),
      );
    }

    if (_activeOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.currentLang == 'en' ? 'Your Order Status' : 'Status Pesanan Anda',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MediaQuery.of(context).size.width >= 600 ? 295 : 282,
          child: PageView.builder(
            controller: _activeOrderController,
            itemCount: _activeOrders.length,
            onPageChanged: (index) {
              setState(() {
                _currentActiveOrderIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final order = _activeOrders[index];
              return _buildActiveOrderCardItem(order);
            },
          ),
        ),
        if (_activeOrders.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_activeOrders.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: _currentActiveOrderIndex == index ? 12 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentActiveOrderIndex == index
                      ? const Color(0xFF0C4B8E)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveOrderCardItem(Map<String, dynamic> order) {
    final String orderId = order['kode_order'] != null && order['kode_order'].toString().isNotEmpty
        ? order['kode_order'].toString()
        : 'WW-${order['id_order']}';

    final layanan = order['Layanan'] ?? {};
    final String serviceName = layanan['nama_layanan'] ?? 'Layanan Laundry';
    final baseOrderColor = _parseHexColor(layanan['warna_layanan'] ?? '#9C27B0');
    final orderColor = _getDarkenedTextColor(baseOrderColor);

    final estDate = _getEstSelesaiDate(order);
    final double totalBayar = (order['total_bayar'] as num?)?.toDouble() ?? 0.0;
    
    final statusInfo = _getCurrentStatusInfo(order);
    final double kuantitas = (order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String rawStatus = (statusInfo['raw_status'] ?? '').toString().toLowerCase();
    final bool isEn = TranslationService.currentLang == 'en';
    final String qtyStr = kuantitas > 0.0
        ? '$kuantitas kg'
        : (rawStatus.contains('diterima') || rawStatus.contains('received')
            ? (isEn ? 'Awaiting Confirmation' : 'Menunggu Konfirmasi')
            : (rawStatus.contains('jemput') || rawStatus.contains('pickup') || rawStatus.contains('penjemputan')
                ? (isEn ? 'Awaiting Pickup' : 'Menunggu Dijemput')
                : (isEn ? 'Pending Weight' : 'Menunggu Timbang')));
    final price = _formatRupiah(totalBayar);

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(baseOrderColor.withValues(alpha: 0.18), Colors.white),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Order ID & Estimasi (Warna Merah)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$orderId',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: orderColor,
                    fontSize: 12,
                  ),
                ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 13,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Est: $estDate',
                    style: const TextStyle(
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
          // Jenis Layanan
          Text(
            TranslationService.translateService(serviceName),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: orderColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            qtyStr,
            style: TextStyle(
              fontSize: 12,
              color: orderColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Baris Harga & Kapsul Pembayaran
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 13,
                  color: orderColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (kuantitas > 0.0) ...[
                const SizedBox(width: 8),
                (() {
                  final pembayaran = order['Pembayaran'];
                  final bool isLunas = pembayaran != null && pembayaran['status_pembayaran'] == 'Lunas';
                  final Color capBg = isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
                  final Color capText = isLunas ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
                  final String capLabel = isLunas 
                      ? (TranslationService.currentLang == 'en' ? 'Paid' : 'Lunas')
                      : (TranslationService.currentLang == 'en' ? 'Unpaid' : 'Belum Lunas');
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: capBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: capText.withOpacity(0.2), width: 1),
                    ),
                    child: Text(
                      capLabel,
                      style: TextStyle(
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
          const SizedBox(height: 24),

          // Stepper Tracker (DYNAMICAL DATABASE ALIGNED - GARIS NYAMBUNG PERFECT)
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
              final bool isDropOff = order['tipe_logistik'] == 'Drop-off';
              final String shortLabel = _getShortStatusLabel(
                rawName,
                lang,
                isCancelled: isCancelled,
                isDropOff: isDropOff,
              );
              
              final bool isCurrent = i == activeIdx && !isSelesai;
              final bool isDone = (i < activeIdx) || (isSelesai && i == refStatuses.length - 1) || (i == 0 && activeIdx > 0);
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
                ),
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps,
            );
          })(),

          const SizedBox(height: 20),
          // Tombol View Detail
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: orderColor,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                TranslationService.currentLang == 'en' ? 'View Detail' : 'Lihat Detail',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // Widget Helper Ikon + Label (Seamless Stepper)
  Widget _buildStepItem({
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
                          ? Icon(Icons.circle, size: 8, color: themeColor)
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
              style: TextStyle(
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
}
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
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
}
