import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/home_screen.dart';
import 'package:mobile/screens/pelanggan/chat/chat_screen.dart';
import 'package:mobile/screens/pelanggan/profile/profile_screen.dart';
import 'package:mobile/screens/pelanggan/home/notifikasi.dart';
import 'package:mobile/screens/pelanggan/orders/wash_ironing.dart';
import 'package:mobile/screens/pelanggan/orders/wash_only.dart';
import 'package:mobile/screens/pelanggan/orders/ironing_only.dart';
import 'package:mobile/screens/pelanggan/orders/dry_clean.dart';

class OrdersScreen extends StatefulWidget {
  final bool showNavbar;
  const OrdersScreen({super.key, this.showNavbar = true});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTab = 0;

  Color _getServiceColor(String serviceName) {
    final name = serviceName.toLowerCase();

    if (name.contains('lipat') || name.contains('dry clean')) {
      return const Color(0xFF00BCD4);
    } else if (name.contains('kering') && !name.contains('lipat')) {
      return const Color(0xFF8BC34A);
    } else if (name.contains('setrika') &&
        (name.contains('cuci') || name.contains('wash'))) {
      return const Color(0xFF9C27B0);
    } else if (name.contains('setrika')) {
      return const Color(0xFFFFC107);
    }

    return const Color(0xFF00BCD4);
  }

  // WARNA TEKS DIGELAPIN
  Color _getDarkenedTextColor(Color color) {
    final hsl = HSLColor.fromColor(color);

    if (hsl.lightness > 0.45) {
      double targetLightness = 0.26;

      // Yellow
      if (hsl.hue >= 45 && hsl.hue <= 65) {
        targetLightness = 0.22;
      }

      // Green
      else if (hsl.hue >= 70 && hsl.hue <= 150) {
        targetLightness = 0.26;
      }

      // Cyan / Blue
      else if (hsl.hue >= 170 && hsl.hue <= 210) {
        targetLightness = 0.22;
      }

      return hsl.withLightness(targetLightness).toColor();
    }

    return color;
  }

  Widget _buildNotificationIcon(Color navyColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: navyColor,
              size: 28,
            ),
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    const Color cyanColor = Color(0xFF42C6D4);
    const Color bgGrey = Color(0xFFF8FBFC);

    return Scaffold(
      backgroundColor: bgGrey,
      extendBody: true,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFBCEFF2),
                    Color(0xFFF8FBFC),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),

                      // JUDUL TETAP
                      Text(
                        'Orders',
                        style: GoogleFonts.poppins(
                          color: navyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),

                      _buildNotificationIcon(navyColor),
                    ],
                  ),
                ),

                _buildTabSelector(navyColor, cyanColor),

                Expanded(
                  child: _selectedTab == 0
                      ? _buildActiveOrders(navyColor)
                      : _buildCompletedOrders(navyColor),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: widget.showNavbar
          ? BottomNavbar(
              currentIndex: 1,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, a1, a2) =>
                          const PelangganHomeScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else if (index == 3) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, a1, a2) =>
                          const ChatScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else if (index == 4) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, a1, a2) =>
                          const ProfileScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }
              },
            )
          : null,
    );
  }

  Widget _buildTabSelector(Color navyColor, Color cyanColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _selectedTab == 0
                      ? cyanColor
                      : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Aktif',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _selectedTab == 0
                        ? Colors.white
                        : navyColor.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _selectedTab == 1
                      ? cyanColor
                      : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Riwayat',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _selectedTab == 1
                        ? Colors.white
                        : navyColor.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrders(Color navyColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      children: [
        _buildActiveOrderCard(
          orderId: 'WW-9831',
          serviceName: 'Cuci Kering Lipat',
          estDate: '18 Mei 2026',
          price: 'Rp 24.000',
          currentStatus: 'Sedang Dicuci',
          currentStep: 2,
          navyColor: navyColor,
        ),

        const SizedBox(height: 16),

        _buildActiveOrderCard(
          orderId: 'WW-9820',
          serviceName: 'Setrika Saja',
          estDate: '17 Mei 2026',
          price: 'Rp 12.000',
          currentStatus: 'Proses Pengantaran',
          currentStep: 3,
          navyColor: navyColor,
        ),
      ],
    );
  }

  Widget _buildCompletedOrders(Color navyColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      children: [
        _buildCompletedOrderCard(
          orderId: 'WW-9750',
          serviceName: 'Cuci Kering',
          endDate: '15 Mei 2026',
          price: 'Rp 35.000',
          navyColor: navyColor,
        ),

        const SizedBox(height: 16),

        _buildCompletedOrderCard(
          orderId: 'WW-9742',
          serviceName: 'Cuci & Setrika',
          endDate: '12 Mei 2026',
          price: 'Rp 45.000',
          navyColor: navyColor,
        ),
      ],
    );
  }

  Widget _buildActiveOrderCard({
    required String orderId,
    required String serviceName,
    required String estDate,
    required String price,
    required String currentStatus,
    required int currentStep,
    required Color navyColor,
  }) {
    final baseColor = _getServiceColor(serviceName);
    final orderColor = _getDarkenedTextColor(baseColor);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: orderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderId',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            serviceName,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: orderColor,
            ),
          ),

          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: orderColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              _buildStepItem(
                'Pick Up',
                Icons.check,
                true,
                currentStep >= 1,
                orderColor,
              ),

              _buildStepLine(currentStep >= 1, orderColor),

              _buildStepItem(
                'Wash',
                Icons.circle,
                currentStep >= 1,
                currentStep >= 2,
                orderColor,
                isCurrent: currentStep == 1,
              ),

              _buildStepLine(currentStep >= 2, orderColor),

              _buildStepItem(
                'Iron',
                Icons.circle,
                currentStep >= 2,
                currentStep >= 3,
                orderColor,
                isCurrent: currentStep == 2,
              ),

              _buildStepLine(currentStep >= 3, orderColor),

              _buildStepItem(
                'Delivery',
                Icons.circle,
                currentStep >= 3,
                currentStep >= 4,
                orderColor,
                isCurrent: currentStep == 3,
              ),

              _buildStepLine(currentStep >= 4, orderColor),

              _buildStepItem(
                'Success',
                Icons.circle,
                currentStep >= 4,
                false,
                orderColor,
                isCurrent: currentStep == 4,
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: orderColor,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'View More',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
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
    required String orderId,
    required String serviceName,
    required String endDate,
    required String price,
    required Color navyColor,
  }) {
    final baseColor = _getServiceColor(serviceName);
    final orderColor = _getDarkenedTextColor(baseColor);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: orderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderId',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: orderColor.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            serviceName,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: orderColor,
            ),
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: orderColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                'Selesai: $endDate',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: orderColor.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: orderColor,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Beri Ulasan',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
  final lowerName = serviceName.toLowerCase();

  // Cuci Kering Lipat
  if (lowerName.contains('cuci') &&
      lowerName.contains('kering') &&
      lowerName.contains('lipat')) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WashOnlyScreen(),
      ),
    );
  }

  // Cuci Kering
  else if (lowerName.contains('cuci') &&
      lowerName.contains('kering')) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DryCleanScreen(),
      ),
    );
  }

  // Cuci & Setrika
  else if (lowerName.contains('cuci') &&
      lowerName.contains('setrika')) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WashIroningScreen(),
      ),
    );
  }

  // Setrika
  else if (lowerName.contains('setrika')) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IroningOnlyScreen(),
      ),
    );
  }
},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orderColor,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Pesan Lagi',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildStepItem(
    String label,
    IconData icon,
    bool isActive,
    bool isDone,
    Color themeColor, {
    bool isCurrent = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDone ? themeColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? themeColor
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: isCurrent
              ? Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: themeColor,
                )
              : Icon(
                  isDone ? Icons.check : Icons.circle,
                  size: 8,
                  color: isDone
                      ? Colors.white
                      : (isActive
                            ? themeColor
                            : Colors.transparent),
                ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isActive
                ? themeColor
                : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive, Color themeColor) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 14),
        color: isActive
            ? themeColor
            : Colors.grey.shade300,
      ),
    );
  }
}