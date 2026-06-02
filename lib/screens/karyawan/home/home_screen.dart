import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/karyawan/orders/pesanan.dart';
import 'package:mobile/screens/karyawan/orders/pesanan_diproses.dart';
import 'package:mobile/screens/karyawan/orders/pesanan_diantar.dart';
import 'package:mobile/screens/karyawan/orders/pesanan_selesai.dart';
import 'package:mobile/screens/karyawan/home/notifikasi.dart';
import 'package:mobile/screens/karyawan/home/riwayat_pendapatan.dart';
import 'package:mobile/screens/karyawan/home/scanner_screen.dart';
import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/utils/constants.dart';
import 'dart:convert';
import 'dart:ui';

class DashboardKaryawan extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const DashboardKaryawan({super.key, this.onProfileTap});

  @override
  State<DashboardKaryawan> createState() => _DashboardKaryawanState();
}

class _DashboardKaryawanState extends State<DashboardKaryawan> {
  int orderCount = 3;
  int prosesCount = 0;
  int antarCount = 0;
  int selesaiCount = 8;

  String _namaKaryawan = 'Karyawan';
  String _fotoKaryawan = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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

  Future<void> _onRefresh() async {
    await _fetchProfile();
  }

  Widget _buildProfileImage() {
    if (_fotoKaryawan.startsWith('http://') || _fotoKaryawan.startsWith('https://')) {
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
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: const Color(0xFF0C4B8E),
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

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

                        const SizedBox(height: 100), // Spacing agar tidak tertutup Bottom Nav
                      ],
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
                child: ClipOval(
                  child: _buildProfileImage(),
                ),
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

  Widget _buildGlassIconButton(IconData icon, Color color, {VoidCallback? onTap}) {
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
                                TranslationService.translate('total_revenue_today').toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "PENDAPATAN HARI INI",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                              builder: (context) => const RiwayatPendapatanScreen(),
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
                    "Rp 727.000,00",
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFFBCEFF2),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          TranslationService.translate('revenue_trending'),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15, // slightly wider than tall
      children: [
        _buildGridCard(TranslationService.translate('order_incoming'), "$orderCount", const Color(0xFFFFF3E0), const Color(0xFFFF9800), Icons.receipt_long_rounded, onTap: () async {
          final acceptedCount = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PesananScreen()));
          if (acceptedCount != null && acceptedCount is int && acceptedCount > 0) {
            setState(() {
              orderCount -= acceptedCount;
              if (orderCount < 0) orderCount = 0;
              prosesCount += acceptedCount;
            });
          }
        }),
        _buildGridCard(TranslationService.translate('in_progress'), "$prosesCount", const Color(0xFFE3F2FD), const Color(0xFF2196F3), Icons.local_laundry_service_rounded, onTap: () async {
          final finishedCount = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PesananDiprosesScreen()));
          if (finishedCount != null && finishedCount is int && finishedCount > 0) {
            setState(() {
              prosesCount -= finishedCount;
              if (prosesCount < 0) prosesCount = 0;
              antarCount += finishedCount;
            });
          }
        }),
        _buildGridCard(TranslationService.translate('ready_for_delivery'), "$antarCount", const Color(0xFFF3E5F5), const Color(0xFF9C27B0), Icons.delivery_dining_rounded, onTap: () async {
          final finishedCount = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PesananDiantarScreen()));
          if (finishedCount != null && finishedCount is int && finishedCount > 0) {
            setState(() {
              antarCount -= finishedCount;
              if (antarCount < 0) antarCount = 0;
              selesaiCount += finishedCount;
            });
          }
        }),
        _buildGridCard(TranslationService.translate('completed'), "$selesaiCount", const Color(0xFFE8F5E9), const Color(0xFF4CAF50), Icons.check_circle_outline_rounded, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PesananSelesaiScreen()));
        }),
      ],
    );
  }

  Widget _buildGridCard(String title, String count, Color bgColor, Color iconColor, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Aesthetic background icon
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              icon,
              size: 80,
              color: bgColor.withOpacity(0.8),
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
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0C4B8E),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      title,
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
    ));
  }

  Widget _buildRecentActivities(Color navyColor, Color cyanColor) {
    final bool isEn = TranslationService.currentLang == 'en';
    
    // High-fidelity mock of the 5 latest orders for this employee
    final List<Map<String, dynamic>> recentOrders = [
      {
        "id": "WW-H78F2",
        "name": "Cecil Clarissa",
        "service": isEn ? "Wash & Iron" : "Cuci & Setrika",
        "time": isEn ? "Just now" : "Baru saja",
        "status": isEn ? "Processing" : "Diproses",
        "statusColor": const Color(0xFF2196F3),
        "statusBg": const Color(0xFFE3F2FD),
      },
      {
        "id": "WW-K92B1",
        "name": "Abilah Budi",
        "service": isEn ? "Ironing Only" : "Setrika Saja",
        "time": isEn ? "10m ago" : "10m lalu",
        "status": isEn ? "New Order" : "Pesanan Baru",
        "statusColor": const Color(0xFFFF9800),
        "statusBg": const Color(0xFFFFF3E0),
      },
      {
        "id": "WW-T33G4",
        "name": "Clarissa Ica",
        "service": isEn ? "Dry Clean & Fold" : "Cuci Kering Lipat",
        "time": isEn ? "1h ago" : "1j lalu",
        "status": isEn ? "Delivering" : "Diantar",
        "statusColor": const Color(0xFF9C27B0),
        "statusBg": const Color(0xFFF3E5F5),
      },
      {
        "id": "WW-P11A9",
        "name": "Devi Ajeng",
        "service": isEn ? "Dry Clean & Fold" : "Cuci Kering Lipat",
        "time": isEn ? "3h ago" : "3j lalu",
        "status": isEn ? "Completed" : "Selesai",
        "statusColor": const Color(0xFF4CAF50),
        "statusBg": const Color(0xFFE8F5E9),
      },
      {
        "id": "WW-L88P3",
        "name": "Budi Santoso",
        "service": isEn ? "Wash & Iron" : "Cuci & Setrika",
        "time": isEn ? "Yesterday" : "Kemarin",
        "status": isEn ? "Completed" : "Selesai",
        "statusColor": const Color(0xFF4CAF50),
        "statusBg": const Color(0xFFE8F5E9),
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentOrders.length,
      itemBuilder: (context, index) {
        final order = recentOrders[index];
        final String initials = _getInitials(order["name"]);

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
              // Circular Initial Avatar
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
                  boxShadow: [
                    BoxShadow(
                      color: cyanColor.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
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
              // Center Info details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "#${order['id']}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: cyanColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "•  ${order['time']}",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order["name"],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order["service"],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right Status Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: order["statusBg"],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order["status"],
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: order["statusColor"],
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