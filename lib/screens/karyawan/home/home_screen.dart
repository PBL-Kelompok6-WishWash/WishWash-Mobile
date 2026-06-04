import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/karyawan/orders/orders.dart';
import 'package:mobile/screens/karyawan/home/notifikasi.dart';
import 'package:mobile/screens/karyawan/home/riwayat_pendapatan.dart';
import 'package:mobile/screens/karyawan/home/scanner_screen.dart';
import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/utils/constants.dart';
import 'dart:convert';
import 'dart:ui';

class DashboardKaryawan extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final Function(int)? onTabChange;
  const DashboardKaryawan({super.key, this.onProfileTap, this.onTabChange});

  @override
  State<DashboardKaryawan> createState() => _DashboardKaryawanState();
}

class _DashboardKaryawanState extends State<DashboardKaryawan> {
  int orderCount = 0;
  int prosesCount = 0;
  int antarCount = 0;
  int selesaiCount = 0;

  String _namaKaryawan = 'Karyawan';
  String _fotoKaryawan = '';

  List<dynamic> _realOrders = [];
  bool _isLoadingOrders = true;
  double _todayRevenue = 0.0;
  String _percentageTrend = '0%';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchOrders();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await PelangganService.getProfile();
      if (response['success'] == true) {
        final data = response['data'] ?? {};
        setState(() {
          _namaKaryawan = data['nama_karyawan'] ?? 'Karyawan';
          _fotoKaryawan = data['foto_karyawan'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching employee profile on dashboard: $e");
    }
  }

  String _getOrderStatus(Map<String, dynamic> order) {
    final historyList = order['RiwayatStatusDetail'];
    if (historyList == null || historyList is! List || historyList.isEmpty) {
      final layanan = order['Layanan'];
      final refList = layanan != null
          ? (layanan['referensi_status'] ?? layanan['ReferensiStatus'])
          : null;
      if (layanan != null && refList != null && refList is List) {
        if (refList.isNotEmpty) {
          List<dynamic> sortedRef = List.from(refList);
          sortedRef.sort(
            (a, b) => (a['urutan_tahap'] as int? ?? 0).compareTo(
              b['urutan_tahap'] as int? ?? 0,
            ),
          );
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

  bool _isBaruOrder(String status) {
    final s = status.toLowerCase();
    return s == 'pesanan diterima' ||
        s.contains('received') ||
        s.contains('baru');
  }

  bool _isOutletOrder(String status, Map<String, dynamic> order) {
    final s = status.toLowerCase();
    if (s.contains('batal') ||
        s.contains('cancel') ||
        s.contains('tolak') ||
        s.contains('reject')) {
      return false;
    }
    if (s == 'pesanan diterima') {
      return false;
    }
    final logistikType = order['tipe_logistik']?.toString() ?? '';
    final bool hasPickup = (order['id_alamat_pengambilan'] != null && order['id_alamat_pengambilan'] != 0) ||
        (order['AlamatPengambilan'] != null && order['AlamatPengambilan']['id_alamat'] != null && order['AlamatPengambilan']['id_alamat'] != 0);
    final bool isDropOff = logistikType == 'Drop-off' && !hasPickup;
    if (isDropOff || logistikType == 'Self Pickup') {
      return s != 'selesai';
    }
    return s == 'proses timbang' ||
        s == 'proses cuci' ||
        s == 'proses kering' ||
        s == 'proses lipat' ||
        s == 'proses setrika';
  }

  bool _isLogistikOrder(String status, Map<String, dynamic> order) {
    final s = status.toLowerCase();
    if (s.contains('batal') ||
        s.contains('cancel') ||
        s.contains('tolak') ||
        s.contains('reject')) {
      return false;
    }
    if (s == 'pesanan diterima') {
      return false;
    }
    final bool hasPickup = (order['id_alamat_pengambilan'] != null && order['id_alamat_pengambilan'] != 0) ||
        (order['AlamatPengambilan'] != null && order['AlamatPengambilan']['id_alamat'] != null && order['AlamatPengambilan']['id_alamat'] != 0);
    final logistikType = order['tipe_logistik']?.toString() ?? '';
    
    if (s == 'penjemputan') {
      return hasPickup;
    }
    if (s == 'siap diantar') {
      return logistikType == 'Courier Delivery';
    }
    return false;
  }

  bool _isSelesaiOrder(String status) {
    final s = status.toLowerCase();
    return s == 'selesai' ||
        s.contains('completed') ||
        s.contains('success') ||
        s.contains('batal') ||
        s.contains('cancel') ||
        s.contains('tolak') ||
        s.contains('reject');
  }

  Future<void> _fetchOrders() async {
    try {
      final list = await OrderService.getOrders();
      final List<Map<String, dynamic>> listMaps = list
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      int countIncoming = 0;
      int countProses = 0;
      int countAntar = 0;
      int countSelesai = 0;

      for (var map in listMaps) {
        final status = _getOrderStatus(map);
        if (_isBaruOrder(status)) {
          countIncoming++;
        } else if (_isOutletOrder(status, map)) {
          countProses++;
        } else if (_isLogistikOrder(status, map)) {
          countAntar++;
        } else if (_isSelesaiOrder(status)) {
          countSelesai++;
        }
      }

      // Sort all orders by tgl_pesanan descending for recent activities
      listMaps.sort((a, b) {
        final tA = a['tgl_pesanan']?.toString() ?? '';
        final tB = b['tgl_pesanan']?.toString() ?? '';
        return tB.compareTo(tA);
      });

      double revenue = 0.0;
      String trend = '0%';
      try {
        final revenueData = await OrderService.getRevenueSummary();
        if (revenueData['success'] == true) {
          revenue = (revenueData['today_revenue'] as num?)?.toDouble() ?? 0.0;
          trend = revenueData['percentage_trend']?.toString() ?? '0%';
        }
      } catch (revErr) {
        debugPrint("Error fetching revenue summary on dashboard: $revErr");
      }

      if (mounted) {
        setState(() {
          _realOrders = listMaps;
          orderCount = countIncoming;
          prosesCount = countProses;
          antarCount = countAntar;
          selesaiCount = countSelesai;
          _todayRevenue = revenue;
          _percentageTrend = trend;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching orders on dashboard: $e");
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    }
  }

  String _formatPrice(double price) {
    final str = price.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  String _getCurrentDateTimeString() {
    final now = DateTime.now();
    final isEn = TranslationService.currentLang == 'en';
    
    final daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final daysId = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    
    final monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthsId = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final dayName = isEn ? daysEn[now.weekday - 1] : daysId[now.weekday - 1];
    final monthName = isEn ? monthsEn[now.month - 1] : monthsId[now.month - 1];
    
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    
    return '$dayName, ${now.day} $monthName ${now.year} • $hour:$minute';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pesanan diterima':
        return Colors.blue.shade700;
      case 'penjemputan':
        return const Color(0xFFFBC02D);
      case 'proses timbang':
        return Colors.cyan.shade700;
      case 'proses cuci':
      case 'proses kering':
      case 'proses lipat':
      case 'proses setrika':
        return const Color(0xFF9C27B0);
      case 'siap diantar':
        return const Color(0xFF0288D1);
      case 'selesai':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  String _getTimeElapsed(String isoString, bool isEn) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        return isEn ? 'Just now' : 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return isEn ? '${diff.inMinutes}m ago' : '${diff.inMinutes}m lalu';
      } else if (diff.inHours < 24) {
        return isEn ? '${diff.inHours}h ago' : '${diff.inHours}j lalu';
      } else {
        return isEn ? '${diff.inDays}d ago' : '${diff.inDays}h lalu';
      }
    } catch (_) {
      return '';
    }
  }

  Future<void> _onRefresh() async {
    await _fetchProfile();
    await _fetchOrders();
  }

  Widget _buildProfileImage() {
    if (_fotoKaryawan.startsWith('http://') ||
        _fotoKaryawan.startsWith('https://')) {
      return Image.network(
        _fotoKaryawan,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    } else if (_fotoKaryawan.startsWith('data:image')) {
      try {
        final base64Content = _fotoKaryawan.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      } catch (e) {
        return _buildDefaultAvatar();
      }
    } else if (_fotoKaryawan.startsWith('/uploads/')) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      return Image.network(
        '$staticHost$_fotoKaryawan',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    } else if (_fotoKaryawan.isNotEmpty) {
      return Image.asset(
        _fotoKaryawan,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }
    return _buildDefaultAvatar();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'K';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildDefaultAvatar() {
    final initials = _getInitials(_namaKaryawan);
    return Container(
      width: 50,
      height: 50,
      color: const Color(0xFF42C6D4), // Cyan background
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    const Color cyanColor = Color(0xFF42C6D4);
    const Color lightCyan = Color(0xFFBCEFF2);

    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FBFC),
          body: Stack(
            children: [
              // Background Blobs - Employee Signature style
              Positioned(
                top: -50,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42C6D4).withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42C6D4).withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(color: Colors.transparent),
                ),
              ),
              RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFF0C4B8E),
                backgroundColor: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24.0,
                        MediaQuery.of(context).padding.top + 8,
                        24.0,
                        24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- HEADER PRIBADI ---
                          _buildHeader(navyColor),
                          const SizedBox(height: 30),

                          // --- HERO INCOME CARD (PREMIUM) ---
                          _buildIncomeCard(navyColor, cyanColor, lightCyan),
                          const SizedBox(height: 30),

                          // --- GRID STATUS 2x2 ---
                          Text(
                            TranslationService.translate('monitor_orders'),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatusGrid(context),
                          const SizedBox(height: 30),

                          // --- AKTIVITAS TERKINI ---
                          Text(
                            TranslationService.translate('recent_activities'),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRecentActivities(navyColor, cyanColor),

                          const SizedBox(
                            height: 100,
                          ), // Spacing agar tidak tertutup Bottom Nav
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // WIDGET HELPER
  // ==========================================

  Widget _buildHeader(Color navyColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                widget.onProfileTap?.call();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(child: _buildProfileImage()),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationService.translate('welcome_greeting'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: navyColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  _namaKaryawan,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildGlassIconButton(
              Icons.qr_code_scanner_rounded,
              navyColor,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerScreen()),
                );
              },
            ),
            const SizedBox(width: 10),
            _buildGlassIconButton(
              Icons.notifications_none_rounded,
              navyColor, // ➔ Koma di sini penting biar dia turun baris
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ), // ➔ Koma di sini juga ngebantu perapian
                );
              },
            ), // ➔ Tutup kurung ini juga dikasih koma
          ],
        ),
      ],
    );
  }

  Widget _buildGlassIconButton(
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          // 3D Shadow bawah/samping yang berdimensi
          BoxShadow(
            color: const Color(0xFFCAD4DE).withOpacity(0.7),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
          // Soft ambient shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          icon: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildIncomeCard(Color navyColor, Color cyanColor, Color lightCyan) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C4B8E), // Deep WishWash navy
            Color(0xFF0A3D75), // Deep mid-blue
            Color(0xFF00ACC1), // Vibrant brand cyan/teal accent
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C4B8E).withOpacity(0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF42C6D4).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Abstract geometric glowing background accents (Premium Glassmorphism Style)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // Premium border highlight
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TranslationService.translate(
                                  'total_revenue_today',
                                ).toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getCurrentDateTimeString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Only this arrow button is clickable/triggers navigation
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RiwayatPendapatanScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Currency Amount
                  Text(
                    _formatPrice(_todayRevenue),
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Trending badge (Glass design chip)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _percentageTrend.startsWith('-')
                              ? Icons.trending_down_rounded
                              : Icons.trending_up_rounded,
                          color: const Color(0xFFBCEFF2),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          TranslationService.currentLang == 'en'
                              ? '$_percentageTrend from yesterday'
                              : '$_percentageTrend dari kemarin',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFFBCEFF2),
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildStatusGrid(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final int crossAxisCount = isTablet ? 4 : 2;
    final double childAspectRatio = isTablet ? 1.3 : 1.15;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        GridMonitorCard(
          title: TranslationService.translate('order_incoming'),
          count: "$orderCount",
          bgColor: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFFF9800),
          icon: Icons.receipt_long_rounded,
          onTap: () {
            OrderScreenKaryawan.orderTabNotifier.value = 1; // Tab 1: Baru
            widget.onTabChange?.call(1); // Swatch to orders page index 1
          },
        ),
        GridMonitorCard(
          title: TranslationService.translate('in_progress'),
          count: "$prosesCount",
          bgColor: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF2196F3),
          icon: Icons.local_laundry_service_rounded,
          onTap: () {
            OrderScreenKaryawan.orderTabNotifier.value = 3; // Tab 3: Outlet
            widget.onTabChange?.call(1);
          },
        ),
        GridMonitorCard(
          title: TranslationService.translate('ready_for_delivery'),
          count: "$antarCount",
          bgColor: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF9C27B0),
          icon: Icons.delivery_dining_rounded,
          onTap: () {
            OrderScreenKaryawan.orderTabNotifier.value = 2; // Tab 2: Logistik
            widget.onTabChange?.call(1);
          },
        ),
        GridMonitorCard(
          title: TranslationService.translate('completed'),
          count: "$selesaiCount",
          bgColor: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle_outline_rounded,
          onTap: () {
            OrderScreenKaryawan.orderTabNotifier.value = 4; // Tab 4: Selesai
            widget.onTabChange?.call(1);
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivities(Color navyColor, Color cyanColor) {
    final bool isEn = TranslationService.currentLang == 'en';
    if (_isLoadingOrders) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C4B8E)),
          ),
        ),
      );
    }
    if (_realOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              isEn ? 'No activities recorded' : 'Belum ada aktivitas terekam',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final int displayCount = _realOrders.length > 5 ? 5 : _realOrders.length;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        final order = _realOrders[index];
        final pelanggan = order['Pelanggan'] as Map<String, dynamic>? ?? {};
        final String customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
        final String initials = _getInitials(customerName);
        final String orderCode =
            order['kode_order'] ?? 'WW-${order['id_order']}';

        final String tglPesanan = order['tgl_pesanan'] ?? '';
        final String timeText = _getTimeElapsed(tglPesanan, isEn);

        final layanan = order['Layanan'] as Map<String, dynamic>? ?? {};
        final String rawServiceName = layanan['nama_layanan'] ?? 'Layanan';
        final String serviceName = TranslationService.translateService(
          rawServiceName,
        );

        final String status = _getOrderStatus(order);
        final Color statusColor = _getStatusColor(status);
        final Color statusBg = statusColor.withOpacity(0.12);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cyanColor.withOpacity(0.8),
                      navyColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "#$orderCode",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: cyanColor,
                          ),
                        ),
                        if (timeText.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            "•  $timeText",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serviceName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  TranslationService.translateStatus(status),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GridMonitorCard extends StatefulWidget {
  final String title;
  final String count;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final VoidCallback? onTap;

  const GridMonitorCard({
    super.key,
    required this.title,
    required this.count,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    this.onTap,
  });

  @override
  State<GridMonitorCard> createState() => _GridMonitorCardState();
}

class _GridMonitorCardState extends State<GridMonitorCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.bgColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.iconColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.transparent, // Hapus efek splash warna
            highlightColor: Colors.transparent, // Hapus efek highlight warna
            child: Stack(
              children: [
                // Aesthetic background icon with dynamic scaling and rotation on click!
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: AnimatedRotation(
                    turns: _isPressed ? -0.04 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutBack,
                    child: AnimatedScale(
                      scale: _isPressed ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        widget.icon,
                        size: 80,
                        color: widget.bgColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.iconColor,
                          size: 24,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.count,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0C4B8E),
                              height: 1.1,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
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
    );
  }
}
