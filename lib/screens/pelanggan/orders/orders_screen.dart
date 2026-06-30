import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/home_screen.dart';
import 'package:mobile/screens/pelanggan/chat/chat_screen.dart';
import 'package:mobile/screens/pelanggan/profile/profile_screen.dart';
import 'package:mobile/screens/pelanggan/home/notifikasi.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/screens/pelanggan/orders/order_detail_screen.dart';
import 'package:mobile/screens/pelanggan/orders/rating_screen.dart';
import 'package:mobile/screens/pelanggan/create_order/create_order_screen.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/services/notifikasi_service.dart';
import 'package:mobile/utils/notification_listener.dart';

class OrdersScreen extends StatefulWidget {
  final bool showNavbar;
  final int initialTab;
  const OrdersScreen({super.key, this.showNavbar = true, this.initialTab = 0});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late int _selectedTab; // 0: Aktif, 1: Riwayat
  late PageController _pageController;
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _pageController = PageController(initialPage: widget.initialTab);
    _fetchOrders();
    _checkUnreadNotifications();
    NotificationListenerManager().addCallback(_onNewNotificationWS);
  }

  @override
  void dispose() {
    NotificationListenerManager().removeCallback(_onNewNotificationWS);
    _pageController.dispose();
    super.dispose();
  }

  void _onNewNotificationWS(Map<String, dynamic> notif) {
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = true;
      });
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final list = await NotifikasiService.getNotifications();
      final hasUnread = list.any((notif) => notif['is_read'] == false);
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final orders = await OrderService.getOrders();
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

  String _formatDateTime(String? isoString) {
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

  String _formatRupiah(double value) {
    if (value == 0.0) {
      return 'Rp 0';
    }
    String valStr = value.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  Widget _buildEmptyState(Color navyColor, String title, String subtitle) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: navyColor.withValues(alpha: 0.4),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getServiceColor(String serviceName, {String? hexColor}) {
    if (hexColor != null && hexColor.isNotEmpty) {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF' + hex;
      }
      try {
        return Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }
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

  Widget _buildNotificationIcon() {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationScreen()),
            );
            _checkUnreadNotifications();
          },
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF0C4B8E),
                  size: 26,
                ),
                if (_hasUnreadNotifications)
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
                            offset: const Offset(0, 2),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    const Color cyanColor = Color(0xFF42C6D4);
    const Color bgGrey = Color(0xFFF8FBFC);

    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        final double statusBarHeight = MediaQuery.of(context).padding.top;
        return Scaffold(
          backgroundColor: bgGrey,
          extendBody: true,
          body: Stack(
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
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, statusBarHeight + 10, 20, 10),
                        child: SizedBox(
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Navigator.canPop(context)
                                  ? Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 20),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    )
                                  : const SizedBox(width: 48),
                              Text(
                                TranslationService.translate('orders'),
                                style: GoogleFonts.poppins(
                                  color: navyColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              _buildNotificationIcon(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildTabSelector(navyColor, cyanColor),
                    ),
                  ];
                },
                body: _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: navyColor, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchOrders,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(TranslationService.currentLang == 'en' ? 'Retry' : 'Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navyColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _selectedTab = index;
                              });
                            },
                            children: [
                              _buildActiveOrders(navyColor),
                              _buildCompletedOrders(navyColor),
                            ],
                          ),
                          if (_isLoading)
                            Container(
                              color: bgGrey.withValues(alpha: 0.6),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(navyColor),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
      // FAB & BottomNavbar
      bottomNavigationBar: widget.showNavbar
          ? BottomNavbar(
              currentIndex: 1, // Index 1 adalah Orders
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, a1, a2) => const PelangganHomeScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else if (index == 3) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, a1, a2) => const ChatScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else if (index == 4) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, a1, a2) => const ProfileScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }
              },
            )
          : null,
    );
  },
);
  }

  Widget _buildTabSelector(Color navyColor, Color cyanColor) {
    final String activeText = TranslationService.currentLang == 'en' ? 'Active' : 'Aktif';
    final String historyText = TranslationService.currentLang == 'en' ? 'History' : 'Riwayat';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Sliding active background indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                left: _selectedTab == 0 ? 0 : tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cyanColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cyanColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Interactive buttons row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _selectedTab = 0);
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _selectedTab == 0 ? Colors.white : navyColor.withValues(alpha: 0.6),
                          ),
                          child: Text(activeText),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _selectedTab = 1);
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _selectedTab == 1 ? Colors.white : navyColor.withValues(alpha: 0.6),
                          ),
                          child: Text(historyText),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
    ),
    );
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

  Widget _buildActiveOrders(Color navyColor) {
    final activeOrders = _allOrders.where((order) {
      final statusInfo = _getCurrentStatusInfo(order);
      return statusInfo['is_selesai'] == false;
    }).toList();

    if (activeOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchOrders,
        color: navyColor,
        child: _buildEmptyState(
          navyColor,
          TranslationService.currentLang == 'en' ? 'No Active Orders' : 'Belum Ada Pesanan Aktif',
          TranslationService.currentLang == 'en'
              ? 'Your active laundry requests will appear here.'
              : 'Permintaan laundry aktif Anda akan muncul di sini.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: navyColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
        final order = activeOrders[index];
        final String orderId = order['kode_order'] != null && order['kode_order'].toString().isNotEmpty
            ? order['kode_order'].toString()
            : 'WW-${order['id_order']}';
        
        final layanan = order['Layanan'] ?? {};
        final serviceName = layanan['nama_layanan'] ?? 'Layanan Laundry';
        
        final estDate = _getEstSelesaiDate(order);
        final double totalBayar = (order['total_bayar'] as num?)?.toDouble() ?? 0.0;
        final price = _formatRupiah(totalBayar);
        
        final statusInfo = _getCurrentStatusInfo(order);
        
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 350 + (index * 80).clamp(0, 240)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1.0 - value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildActiveOrderCard(
              order: order,
              orderId: orderId,
              serviceName: serviceName,
              estDate: estDate,
              price: price,
              statusInfo: statusInfo,
              navyColor: navyColor,
            ),
          ),
        );
      },
    ),
    ),
    ),
    );
  }

  DateTime _getCompletionDateTime(Map<String, dynamic> order) {
    String endDateTimeStr = order['tgl_pesanan'] ?? '';
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
        endDateTimeStr = rawTime.toString();
      }
    }
    return DateTime.tryParse(endDateTimeStr) ?? DateTime(1970);
  }

  Widget _buildCompletedOrders(Color navyColor) {
    final completedOrders = _allOrders.where((order) {
      final statusInfo = _getCurrentStatusInfo(order);
      return statusInfo['is_selesai'] == true;
    }).toList();

    completedOrders.sort((a, b) {
      final dateA = _getCompletionDateTime(a);
      final dateB = _getCompletionDateTime(b);
      return dateB.compareTo(dateA);
    });

    if (completedOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchOrders,
        color: navyColor,
        child: _buildEmptyState(
          navyColor,
          TranslationService.currentLang == 'en' ? 'No Order History' : 'Belum Ada Riwayat Pesanan',
          TranslationService.currentLang == 'en'
              ? 'Completed laundry orders will appear here.'
              : 'Pesanan laundry yang sudah selesai akan muncul di sini.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: navyColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          itemCount: completedOrders.length,
          itemBuilder: (context, index) {
        final order = completedOrders[index];
        final String orderId = order['kode_order'] != null && order['kode_order'].toString().isNotEmpty
            ? order['kode_order'].toString()
            : 'WW-${order['id_order']}';
        
        final layanan = order['Layanan'] ?? {};
        final serviceName = layanan['nama_layanan'] ?? 'Layanan Laundry';
        
        String endDateTimeStr = order['tgl_pesanan'] ?? '';
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
            endDateTimeStr = rawTime.toString();
          }
        }
        final endDate = _formatDateTime(endDateTimeStr);
        final double totalBayar = (order['total_bayar'] as num?)?.toDouble() ?? 0.0;
        final price = _formatRupiah(totalBayar);
        
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 350 + (index * 80).clamp(0, 240)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1.0 - value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCompletedOrderCard(
              order: order,
              orderId: orderId,
              serviceName: serviceName,
              endDate: endDate,
              price: price,
              navyColor: navyColor,
            ),
          ),
        );
      },
    ),
    ),
    ),
    );
  }

  Widget _buildActiveOrderCard({
    required Map<String, dynamic> order,
    required String orderId,
    required String serviceName,
    required String estDate,
    required String price,
    required Map<String, dynamic> statusInfo,
    required Color navyColor,
  }) {
    final baseColor = _getServiceColor(serviceName, hexColor: (order['Layanan']?['warna_layanan'] ?? '').toString());
    final orderColor = _getDarkenedTextColor(baseColor);

    final double kuantitas = (order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final String rawStatus = (statusInfo['raw_status'] ?? '').toString().toLowerCase();
    final bool isCancelled = rawStatus.contains('batal') || rawStatus.contains('cancel') || rawStatus.contains('tolak') || rawStatus.contains('reject');
    final bool isEn = TranslationService.currentLang == 'en';
    final String unit = (order['Layanan']?['jenis_satuan'] ?? 'Kg').toString();
    final bool isPcs = unit.toLowerCase() == 'pcs';
    final String qtyStr = kuantitas > 0.0
        ? (isPcs ? '${kuantitas.toInt()} pcs' : '${kuantitas.toStringAsFixed(1)} kg')
        : (isCancelled
            ? ''
            : (rawStatus.contains('diterima') || rawStatus.contains('received')
                ? (isEn ? 'Awaiting Confirmation' : 'Menunggu Konfirmasi')
                : (rawStatus.contains('jemput') || rawStatus.contains('pickup') || rawStatus.contains('penjemputan')
                    ? (isEn ? 'Awaiting Pickup' : 'Menunggu Dijemput')
                    : (isEn 
                        ? (isPcs ? 'Pending Count' : 'Pending Weight') 
                        : (isPcs ? 'Menunggu Hitung' : 'Menunggu Timbang')))));

    return Container(
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
              Expanded(
                child: Text(
                  'Order #$orderId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: orderColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Est: $estDate',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            TranslationService.translateService(serviceName),
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
              final bool isDropOff = order['tipe_logistik'] == 'Drop-off' || order['tipe_logistik'] == 'Self Pickup';
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
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
                _fetchOrders();
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedOrderCard({
    required Map<String, dynamic> order,
    required String orderId,
    required String serviceName,
    required String endDate,
    required String price,
    required Color navyColor,
  }) {
    final baseColor = _getServiceColor(serviceName, hexColor: (order['Layanan']?['warna_layanan'] ?? '').toString());
    final orderColor = _getDarkenedTextColor(baseColor);

    final statusInfo = _getCurrentStatusInfo(order);
    final String rawStatus = (statusInfo['raw_status'] ?? '').toString().toLowerCase();
    final bool isCancelled = rawStatus.contains('batal') || rawStatus.contains('cancel') || rawStatus.contains('tolak') || rawStatus.contains('reject');

    final double kuantitas = (order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final bool isEn = TranslationService.currentLang == 'en';
    final String unit = (order['Layanan']?['jenis_satuan'] ?? 'Kg').toString();
    final bool isPcs = unit.toLowerCase() == 'pcs';
    final String qtyStr = kuantitas > 0.0
        ? (isPcs ? '${kuantitas.toInt()} pcs' : '${kuantitas.toStringAsFixed(1)} kg')
        : (isCancelled
            ? ''
            : (rawStatus.contains('diterima') || rawStatus.contains('received')
                ? (isEn ? 'Awaiting Confirmation' : 'Menunggu Konfirmasi')
                : (rawStatus.contains('jemput') || rawStatus.contains('pickup') || rawStatus.contains('penjemputan')
                    ? (isEn ? 'Awaiting Pickup' : 'Menunggu Dijemput')
                    : (isEn 
                        ? (isPcs ? 'Pending Count' : 'Pending Weight') 
                        : (isPcs ? 'Menunggu Hitung' : 'Menunggu Timbang')))));

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
        _fetchOrders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(baseColor.withValues(alpha: 0.10), Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? Colors.red.shade400.withValues(alpha: 0.7)
              : orderColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #$orderId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: isCancelled ? Colors.red.shade700 : orderColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF4CAF50), // Soft / Light Green
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isCancelled
                        ? (TranslationService.currentLang == 'en' ? 'Cancelled' : 'Dibatalkan')
                        : (TranslationService.currentLang == 'en' ? 'Completed' : 'Selesai'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            TranslationService.translateService(serviceName),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isCancelled ? Colors.red.shade900 : orderColor,
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
          SizedBox(height: isCancelled ? 8 : 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isCancelled) ...[
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: orderColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  isCancelled
                      ? (TranslationService.currentLang == 'en' ? 'Cancelled: $endDate' : 'Dibatalkan: $endDate')
                      : 'Selesai: $endDate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isCancelled ? Colors.red.shade700 : orderColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          (() {
            final lang = TranslationService.currentLang;
            final List<Map<String, dynamic>> refStatuses = statusInfo['statuses'];
            List<Widget> steps = [];
            for (int i = 0; i < refStatuses.length; i++) {
              final rawName = refStatuses[i]['nama_status'] ?? '';
              final bool isDropOff = order['tipe_logistik'] == 'Drop-off' || order['tipe_logistik'] == 'Self Pickup';
              final String shortLabel = _getShortStatusLabel(
                rawName,
                lang,
                isCancelled: isCancelled,
                isDropOff: isDropOff,
              );
              steps.add(
                _buildStepItem(
                  label: shortLabel,
                  isActive: true,
                  isDone: true,
                  isCurrent: false,
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
          const SizedBox(height: 16),
          Row(
            children: [
              if (!isCancelled) ...[
                Expanded(
                  child: order['Penilaian'] != null
                      ? Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${order['Penilaian']['bintang']}.0',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                TranslationService.currentLang == 'en' ? 'Rated' : 'Dinilai',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RatingScreen(order: order),
                                ),
                              );
                              _fetchOrders();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: orderColor,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              TranslationService.currentLang == 'en' ? 'Write Review' : 'Beri Ulasan',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orderColor,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      TranslationService.currentLang == 'en' ? 'Order Again' : 'Pesan Lagi',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
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
