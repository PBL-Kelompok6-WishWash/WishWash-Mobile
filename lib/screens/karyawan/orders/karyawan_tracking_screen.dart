import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/utils/constants.dart';


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
        final bool isEn = TranslationService.currentLang == 'en';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'Could not open Google Maps' : 'Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup = status == 'penjemputan' || status == 'pesanan diterima';
    final bool isEn = TranslationService.currentLang == 'en';
    
    final String title = isPickup 
        ? (isEn ? 'Confirm Pickup Completed?' : 'Konfirmasi Selesai Penjemputan?')
        : (isEn ? 'Confirm Delivery Completed?' : 'Konfirmasi Selesai Diantar?');
    final String desc = isPickup 
        ? (isEn 
            ? 'Are you sure you have completed picking up the laundry from this customer?'
            : 'Apakah Anda yakin telah menyelesaikan penjemputan cucian dari pelanggan ini?')
        : (isEn 
            ? 'Are you sure the laundry has been successfully handed over to the customer?'
            : 'Apakah Anda yakin cucian telah berhasil diserahkan ke pelanggan?');

    showDialog(
      context: context,
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
                  color: navyColor.withOpacity(0.15),
                  blurRadius: 30,
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
                  decoration: BoxDecoration(
                    color: navyColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPickup ? Icons.local_shipping_rounded : Icons.task_alt_rounded,
                    color: navyColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
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
                      _confirmArrival();
                    },
                    child: Text(
                      isPickup 
                          ? (isEn ? 'Yes, Finished Pickup' : 'Ya, Selesai Jemput') 
                          : (isEn ? 'Yes, Finished Delivery' : 'Ya, Selesai Antar'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
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

  Future<void> _confirmArrival() async {
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isEn = TranslationService.currentLang == 'en';
    String nextStatus = 'proses timbang';
    String successMsg = isEn 
        ? 'You have arrived at the pickup location!' 
        : 'Anda telah sampai di lokasi penjemputan!';

    if (status == 'siap diantar') {
      nextStatus = 'selesai';
      successMsg = isEn 
          ? 'Laundry successfully delivered to customer!' 
          : 'Cucian berhasil diantarkan ke pelanggan!';
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
          SnackBar(
            content: Text(isEn ? 'Failed to update status: $e' : 'Gagal memperbarui status: $e'), 
            backgroundColor: Colors.red,
          ),
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
    final String actionButtonText = isPickup ? 'Konfirmasi Selesai Penjemputan' : 'Konfirmasi Selesai Diantar';

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
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Travel stats (ETA & Distance)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF8FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: navyColor),
                            const SizedBox(width: 4),
                            Text(
                              isPickup ? '8 Mnt' : '12 Mnt',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: navyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.navigation_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              isPickup ? '2.4 km' : '4.1 km',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Route Card (Gojek / Grab POV style - Perfected Vertical Timeline)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgGrey,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: navyColor.withOpacity(0.08), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        // Start Point: Outlet
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cyanColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: cyanColor.withOpacity(0.3), width: 1),
                              ),
                              child: Icon(Icons.storefront_rounded, color: navyColor, size: 16),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LOKASI ASAL',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'WishWash Laundry Outlet',
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
                        // Connector line
                        Row(
                          children: [
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Container(
                                width: 2,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        // End Point: Target Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 16),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPickup ? 'ALAMAT PENJEMPUTAN' : 'ALAMAT PENGANTARAN',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Customer Quick Info Card
                  // Customer Quick Info Card
                  Row(
                    children: [
                      // Dynamic Customer Avatar from Database
                      (() {
                        final String rawFoto = (pelanggan['foto_pelanggan'] ?? '').toString();
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
                          width: 48,
                          height: 48,
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
                                color: const Color(0xFF0C4B8E).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
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
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white.withOpacity(0.7),
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
                                          fontSize: 16,
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
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        );
                      })(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: navyColor,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                      ),
                      GestureDetector(
                        onTap: () {
                          final bool isEn = TranslationService.currentLang == 'en';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEn ? 'Opening chat with $customerName...' : 'Membuka chat dengan $customerName...',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: navyColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cyanColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: cyanColor.withOpacity(0.2), width: 1),
                          ),
                          child: Icon(Icons.chat_bubble_rounded, color: navyColor, size: 16),
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
                            border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
                          ),
                          child: Icon(Icons.directions_rounded, color: Colors.green.shade700, size: 18),
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
                        backgroundColor: isPickup ? navyColor : Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: (isPickup ? navyColor : Colors.green.shade700).withOpacity(0.3),
                      ),
                      onPressed: _isUpdating ? null : _showConfirmationDialog,
                      child: _isUpdating
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 20),
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
      color: const Color(0xFFF1F5F9), // Beautiful clean cool-slate background
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
    // 1. Draw Parks (Green Spaces)
    final parkPaint = Paint()..color = const Color(0xFFDCF2E4);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.22, size.height * 0.12, 110, 80), const Radius.circular(16)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.52, size.height * 0.52, 90, 110), const Radius.circular(16)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.05, size.height * 0.72, 70, 70), const Radius.circular(12)), parkPaint);

    // 2. Draw River (Blue Winding line)
    final riverPaint = Paint()
      ..color = const Color(0xFFD0E1FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    Path river = Path();
    river.moveTo(0, size.height * 0.85);
    river.quadraticBezierTo(size.width * 0.4, size.height * 0.76, size.width * 0.7, size.height * 0.9);
    river.lineTo(size.width, size.height * 0.85);
    canvas.drawPath(river, riverPaint);

    // 3. Draw Buildings (light gray blocks)
    final bldgPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.05, size.height * 0.48, 50, 40), const Radius.circular(6)), bldgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.75, size.height * 0.15, 60, 50), const Radius.circular(6)), bldgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.8, size.height * 0.65, 45, 60), const Radius.circular(6)), bldgPaint);

    // 4. Roads Styling & Painting
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
