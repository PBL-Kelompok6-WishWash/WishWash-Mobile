import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';

class KaryawanTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const KaryawanTrackingScreen({super.key, required this.order});

  @override
  State<KaryawanTrackingScreen> createState() => _KaryawanTrackingScreenState();
}

class _KaryawanTrackingScreenState extends State<KaryawanTrackingScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color softTeal = const Color(0xFFBCEFF2);
  final Color bgGrey = const Color(0xFFF8FBFC);

  bool _isUpdating = false;

  Future<void> _launchGoogleMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  Future<void> _confirmArrival() async {
    final status = _getOrderStatus(widget.order).toLowerCase();
    String nextStatus = 'proses timbang';
    String successMsg = 'Anda telah sampai di lokasi penjemputan!';

    if (status == 'siap diantar') {
      nextStatus = 'selesai';
      successMsg = 'Cucian berhasil diantarkan ke pelanggan!';
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedOrder = await OrderService.updateOrder(
        widget.order['id_order'],
        {'status': nextStatus},
      );
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context, updatedOrder);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getOrderStatus(Map<String, dynamic> order) {
    final historyList = order['RiwayatStatusDetail'];
    if (historyList == null || historyList is! List || historyList.isEmpty) {
      return 'Pesanan Diterima';
    }
    List<dynamic> sortedHistory = List.from(historyList);
    sortedHistory.sort((a, b) => (a['id_riwayat_status_detail'] as num? ?? 0).compareTo(b['id_riwayat_status_detail'] as num? ?? 0));
    final latestHistory = sortedHistory.last;
    final refStatus = latestHistory['ReferensiStatus'];
    if (refStatus != null && refStatus is Map) {
      return refStatus['nama_status'] ?? 'Pesanan Diterima';
    }
    return 'Pesanan Diterima';
  }

  @override
  Widget build(BuildContext context) {
    final pelanggan = widget.order['Pelanggan'] ?? {};
    final customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
    final customerPhone = (pelanggan['no_telp'] ?? pelanggan['no_hp'] ?? pelanggan['NoTelp'] ?? '-').toString();
    
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup = status == 'penjemputan' || status == 'pesanan diterima';

    // Alamat tujuan kurir
    final alamatAmbil = widget.order['AlamatPengambilan'] ?? {};
    final alamatKirim = widget.order['AlamatPenyerahan'] ?? {};
    final String targetAddress = isPickup 
        ? (alamatAmbil['alamat_lengkap'] ?? 'Alamat Pelanggan')
        : (alamatKirim['alamat_lengkap'] ?? 'Alamat Pelanggan');

    final String titleText = isPickup ? 'Navigasi Penjemputan' : 'Navigasi Pengantaran';
    final String actionButtonText = isPickup ? 'Konfirmasi Sampai di Lokasi' : 'Konfirmasi Selesai Diantar';

    return Scaffold(
      body: Stack(
        children: [
          // 1. HIGH-FIDELITY VECTOR MAP MOCKUP (POPT-IN ARTWORK)
          Positioned.fill(
            child: _buildInteractiveMockMap(),
          ),

          // 2. PREMIUM APP BAR OVERLAY
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: navyColor.withOpacity(0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    titleText,
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildGlassIconButton(
                  icon: Icons.navigation_rounded,
                  onTap: () => _launchGoogleMaps(targetAddress),
                ),
              ],
            ),
          ),

          // 3. COURIER HUD ACTION PANEL (BOTTOM SHEET STYLE)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pull pill
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Route Card (Gojek / Grab POV style)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgGrey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: navyColor.withOpacity(0.05), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.storefront_rounded, color: cyanColor, size: 20),
                            Container(
                              width: 2,
                              height: 35,
                              color: Colors.grey.shade300,
                            ),
                            Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 22),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WishWash Laundry Outlet',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                targetAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(height: 18),

                  // Customer Quick Info Card
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: softTeal,
                        child: Icon(Icons.person_rounded, color: navyColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: navyColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              customerPhone,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chat button
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Membuka chat dengan $customerName...'), backgroundColor: navyColor),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cyanColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chat_bubble_rounded, color: navyColor, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Direct Google Maps shortcut
                      GestureDetector(
                        onTap: () => _launchGoogleMaps(targetAddress),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.directions_rounded, color: Colors.green.shade700, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Primary Navigation Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPickup ? cyanColor : Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: (isPickup ? cyanColor : Colors.green.shade700).withOpacity(0.3),
                      ),
                      onPressed: _isUpdating ? null : _confirmArrival,
                      child: _isUpdating
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isPickup ? Icons.sports_motorsports_outlined : Icons.done_all_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  actionButtonText,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: navyColor, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInteractiveMockMap() {
    return Container(
      color: const Color(0xFFE5E9F0), // Soft vector map bg
      child: CustomPaint(
        painter: MapPainter(navyColor: navyColor, cyanColor: cyanColor),
      ),
    );
  }
}

// Custom Painter to draw a gorgeous, high-fidelity mock vector road and tracking path!
class MapPainter extends CustomPainter {
  final Color navyColor;
  final Color cyanColor;

  MapPainter({required this.navyColor, required this.cyanColor});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = const Color(0xFF1E88E5) // Premium maps active blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw some structural mockup roads
    Path roads = Path();
    roads.moveTo(size.width * 0.15, size.height * 0.1);
    roads.lineTo(size.width * 0.15, size.height * 0.7);
    roads.lineTo(size.width * 0.65, size.height * 0.7);
    roads.lineTo(size.width * 0.65, size.height * 0.3);
    roads.lineTo(size.width * 0.9, size.height * 0.3);

    // Cross roads
    roads.moveTo(0, size.height * 0.45);
    roads.lineTo(size.width, size.height * 0.45);

    roads.moveTo(size.width * 0.4, 0);
    roads.lineTo(size.width * 0.4, size.height);

    canvas.drawPath(roads, roadBorderPaint);
    canvas.drawPath(roads, roadPaint);

    // Draw active driver navigation route
    Path activeRoute = Path();
    activeRoute.moveTo(size.width * 0.65, size.height * 0.65); // Starting near outlet
    activeRoute.lineTo(size.width * 0.65, size.height * 0.45);
    activeRoute.lineTo(size.width * 0.15, size.height * 0.45);
    activeRoute.lineTo(size.width * 0.15, size.height * 0.2); // Near customer destination

    canvas.drawPath(activeRoute, routePaint);

    // Draw destination pin (Red Pin)
    final pinPaint = Paint()..color = Colors.redAccent;
    final centerDest = Offset(size.width * 0.15, size.height * 0.2);
    canvas.drawCircle(centerDest, 10, pinPaint);
    canvas.drawCircle(centerDest, 4, Paint()..color = Colors.white);

    // Draw Courier current position (Blue Circle/Pill)
    final driverPaint = Paint()..color = const Color(0xFF1E88E5);
    final centerDriver = Offset(size.width * 0.45, size.height * 0.45);
    canvas.drawCircle(centerDriver, 12, driverPaint);
    canvas.drawCircle(centerDriver, 14, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(centerDriver, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
