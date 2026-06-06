import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/utils/constants.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/services/translation_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;
  bool _isFetchingOrder = false;

  // ── Fetch order by kode_order from API (multi-strategy) ─────────────────
  Future<Map<String, dynamic>?> _fetchOrderByCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return null;

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Strategy 1: dedicated /order/by-kode/:kode endpoint (try uppercase)
      try {
        final upperCode = code.toUpperCase();
        final uri1 = Uri.parse('${Constants.baseUrl}/order/by-kode/${Uri.encodeComponent(upperCode)}');
        final res1 = await http.get(uri1, headers: headers).timeout(const Duration(seconds: 5));
        if (res1.statusCode == 200) {
          final data = jsonDecode(res1.body);
          final orderData = data['data'];
          if (orderData != null && orderData is Map && (orderData as Map).isNotEmpty) {
            return Map<String, dynamic>.from(orderData);
          }
        }
      } catch (_) {}

      // Strategy 2: only if code is pure numeric or "ww-{number}" format → use /order/:id
      try {
        // Only try numeric lookup for purely numeric codes or "ww-{digit}" patterns
        final pureNumeric = RegExp(r'^\d+$').hasMatch(code);
        final wwNumericMatch = RegExp(r'^ww-(\d+)$', caseSensitive: false).firstMatch(code);
        int? idOrder;
        if (pureNumeric) {
          idOrder = int.tryParse(code);
        } else if (wwNumericMatch != null) {
          idOrder = int.tryParse(wwNumericMatch.group(1) ?? '');
        }
        if (idOrder != null) {
          final uri2 = Uri.parse('${Constants.baseUrl}/order/$idOrder');
          final res2 = await http.get(uri2, headers: headers).timeout(const Duration(seconds: 5));
          if (res2.statusCode == 200) {
            final data = jsonDecode(res2.body);
            final orderData = data['data'];
            if (orderData != null && orderData is Map) {
              return Map<String, dynamic>.from(orderData);
            }
          }
        }
      } catch (_) {}

      // Strategy 3: fetch all orders → filter client-side
      try {
        final uri3 = Uri.parse('${Constants.baseUrl}/order');
        final res3 = await http.get(uri3, headers: headers).timeout(const Duration(seconds: 8));
        if (res3.statusCode == 200) {
          final data = jsonDecode(res3.body);
          final List<dynamic> list = data['data'] ?? [];
          final lowerCode = code.toLowerCase();
          for (final item in list) {
            if (item is Map) {
              final kode = (item['kode_order'] ?? '').toString().toLowerCase();
              final idStr = 'ww-${item['id_order']}'.toLowerCase();
              if (kode == lowerCode || idStr == lowerCode || kode.contains(lowerCode)) {
                return Map<String, dynamic>.from(item);
              }
            }
          }
        }
      } catch (_) {}

      return null;
    } catch (e) {
      debugPrint('Error fetching order by code: $e');
      return null;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned || _isFetchingOrder) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanned = true;
          _isFetchingOrder = true;
        });

        final String scannedCode = barcode.rawValue!;
        _processScannedCode(scannedCode);
        break;
      }
    }
  }

  Future<void> _processScannedCode(String scannedCode) async {
    // Show loading dialog immediately
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42C6D4), Color(0xFF0C4B8E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Memuat Data Pesanan...',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0C4B8E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mengambil informasi pesanan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Fetch order data
    final String cleanCode = scannedCode.replaceAll('Order#', '').trim();
    final orderData = await _fetchOrderByCode(cleanCode);

    if (!mounted) return;
    Navigator.pop(context); // close loading dialog

    setState(() => _isFetchingOrder = false);

    // Debug: log what we got
    if (orderData != null) {
      debugPrint('✅ Scanner found order: kode=${orderData['kode_order']}, id=${orderData['id_order']}');
      debugPrint('   Pelanggan: ${orderData['Pelanggan']}');
      debugPrint('   total_bayar: ${orderData['total_bayar']}');
      debugPrint('   Layanan: ${orderData['Layanan']}');
    } else {
      debugPrint('❌ Scanner: order not found for code=$cleanCode');
    }

    // Show result dialog
    _showResultDialog(scannedCode, cleanCode, orderData);
  }

  void _showResultDialog(String scannedCode, String cleanCode, Map<String, dynamic>? orderData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: _buildResultDialogContent(dialogCtx, scannedCode, cleanCode, orderData),
        );
      },
    );
  }

  Widget _buildResultDialogContent(
    BuildContext dialogCtx,
    String scannedCode,
    String cleanCode,
    Map<String, dynamic>? orderData,
  ) {
    final bool found = orderData != null;

    // ── Extract order data ──────────────────────────────────────────────
    String customerName = '-';
    String serviceName = '-';
    String packageName = '-';
    String weightStr = '-';
    String totalPrice = '-';
    String statusLabel = '-';
    String orderDate = '-';
    String paymentStatus = '-';
    bool isPaid = false;

    if (found) {
      // Customer — field is 'nama_lengkap' in Go Pelanggan model
      final pelanggan = orderData['Pelanggan'] ?? orderData['pelanggan'];
      if (pelanggan is Map) {
        final raw = pelanggan['nama_lengkap']?.toString() ??
            pelanggan['nama_pelanggan']?.toString() ??
            pelanggan['nama']?.toString() ??
            '';
        customerName = raw.isNotEmpty ? raw : '-';
      }

      // Service / Layanan
      final layanan = orderData['Layanan'] ?? orderData['layanan'];
      if (layanan is Map) {
        serviceName = layanan['nama_layanan']?.toString() ??
            layanan['nama']?.toString() ??
            '-';
      }

      // Package / PaketLayanan
      final paket = orderData['PaketLayanan'] ?? orderData['paket_layanan'];
      if (paket is Map) {
        packageName = paket['nama_paket']?.toString() ??
            paket['nama']?.toString() ??
            '-';
      }

      // Berat/Kuantitas — field is 'kuantitas' in Go Order model
      final berat = orderData['kuantitas'] ??
          orderData['berat_kg'] ??
          orderData['berat'];
      if (berat != null) {
        final double beratVal = (berat as num).toDouble();
        // Get satuan from layanan
        final layananForUnit = orderData['Layanan'] ?? orderData['layanan'];
        String satuan = 'kg';
        if (layananForUnit is Map) {
          satuan = layananForUnit['jenis_satuan']?.toString() ?? 'kg';
        }
        weightStr = '${beratVal % 1 == 0 ? beratVal.toInt() : beratVal} $satuan';
      }

      // Total Harga — field is 'total_bayar' in Go Order model
      final totalRaw = orderData['total_bayar'] ??
          orderData['total_harga'] ??
          orderData['total'];
      if (totalRaw != null) {
        final double total = (totalRaw as num).toDouble();
        if (total > 0) {
          String valStr = total.toStringAsFixed(0);
          RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
          String formatted = valStr.replaceAllMapped(reg, (m) => '${m[1]}.');
          totalPrice = 'Rp $formatted';
        } else {
          totalPrice = 'Belum ditimbang';
        }
      } else {
        totalPrice = 'Belum ditimbang';
      }

      // Status
      final historyList = orderData['RiwayatStatusDetail'];
      if (historyList is List && historyList.isNotEmpty) {
        final sorted = List.from(historyList)
          ..sort((a, b) {
            final idA = (a['id_riwayat_status_detail'] as num?)?.toInt() ?? 0;
            final idB = (b['id_riwayat_status_detail'] as num?)?.toInt() ?? 0;
            return idA.compareTo(idB);
          });
        final latest = sorted.last;
        final refSt = latest['ReferensiStatus'];
        if (refSt is Map) {
          statusLabel = refSt['nama_status']?.toString() ?? '-';
        } else {
          statusLabel = latest['nama_status']?.toString() ?? '-';
        }
      }

      // Tanggal Pesanan
      final tgl = orderData['tgl_pesanan']?.toString() ??
          orderData['created_at']?.toString();
      if (tgl != null && tgl.isNotEmpty) {
        try {
          final dt = DateTime.parse(tgl).toLocal();
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
            'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
          ];
          final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
          final ampm = dt.hour >= 12 ? 'PM' : 'AM';
          orderDate =
              '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
        } catch (_) {
          orderDate = tgl.split('T').first;
        }
      }

      // Payment
      final pembayaran = orderData['Pembayaran'];
      if (pembayaran is Map) {
        final st = pembayaran['status_pembayaran']?.toString() ?? '';
        isPaid = st == 'Lunas' || st == 'Paid';
        paymentStatus = isPaid ? 'Lunas' : 'Belum Lunas';
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header Icon ─────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: found
                    ? const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFFF5722), Color(0xFFD32F2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (found ? Colors.green : Colors.red)
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                found ? Icons.verified_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ────────────────────────────────────────────────────
            Text(
              found ? 'Resi Terverifikasi' : 'Pesanan Tidak Ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0C4B8E),
              ),
            ),
            const SizedBox(height: 4),

            // ── Scanned Code Chip ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF42C6D4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF42C6D4).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_rounded,
                    color: Color(0xFF42C6D4),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cleanCode.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0C4B8E),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            if (found) ...[
              const SizedBox(height: 20),

              // ── Info Card ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE0EAF6),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF0C4B8E),
                      label: 'Pelanggan',
                      value: customerName,
                      isFirst: true,
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.local_laundry_service_rounded,
                      iconColor: const Color(0xFF42C6D4),
                      label: 'Layanan',
                      value: serviceName,
                    ),
                    if (packageName != '-') ...[
                      _divider(),
                      _infoRow(
                        icon: Icons.inventory_2_rounded,
                        iconColor: const Color(0xFF7B61FF),
                        label: 'Paket',
                        value: packageName,
                      ),
                    ],
                    if (weightStr != '-') ...[
                      _divider(),
                      _infoRow(
                        icon: Icons.scale_rounded,
                        iconColor: const Color(0xFF00897B),
                        label: 'Berat',
                        value: weightStr,
                      ),
                    ],
                    _divider(),
                    _infoRow(
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFFFF8C00),
                      label: 'Total',
                      value: totalPrice,
                      valueBold: true,
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.payments_rounded,
                      iconColor: isPaid
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5722),
                      label: 'Pembayaran',
                      value: paymentStatus,
                      valueColor: isPaid
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFB71C1C),
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.flag_rounded,
                      iconColor: const Color(0xFF1976D2),
                      label: 'Status',
                      value: statusLabel,
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.calendar_today_rounded,
                      iconColor: Colors.grey.shade500,
                      label: 'Tgl Pesanan',
                      value: orderDate,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Question text ────────────────────────────────────────────
              Text(
                'Apakah laundry sudah diserahkan ke pelanggan dan siap ditandai selesai?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Tidak ada pesanan dengan kode "$cleanCode". Pastikan barcode yang dipindai benar.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Action Buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      setState(() => _isScanned = false);
                    },
                    child: Text(
                      'Scan Ulang',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                if (found) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        // Show a loading dialog during update
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF42C6D4),
                            ),
                          ),
                        );

                        try {
                          final String nextSt = _getNextStatus(orderData);
                          final updated = await OrderService.updateOrder(
                            orderData['id_order'],
                            {'status': nextSt.isNotEmpty ? nextSt : 'selesai'},
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // pop loading dialog
                            Navigator.pop(dialogCtx); // pop info dialog
                            Navigator.pop(context, updated); // pop scanner screen returning updated order map
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // pop loading dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memperbarui status: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Serahkan Laundry',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Info Row widget ────────────────────────────────────────────────────────
  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 12, 16, isLast ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight:
                        valueBold ? FontWeight.bold : FontWeight.w600,
                    color: valueColor ?? const Color(0xFF0C4B8E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: const Color(0xFFE8EEF6),
        indent: 16,
        endIndent: 16,
      );

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan Resi Pelanggan',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0C4B8E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.white);
                }
              },
            ),
            onPressed: () async {
              try {
                await cameraController.toggleTorch();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menyalakan flash: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  default:
                    return const Icon(Icons.flip_camera_ios);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: BarcodeScannerOverlayShape(
                borderColor: const Color(0xFF42C6D4),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 8,
                cutOutWidth: MediaQuery.of(context).size.width * 0.85,
                cutOutHeight: 120,
              ),
            ),
          ),
          // Animated scanning laser line
          Positioned(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 120,
              child: const ScanningLine(
                width: double.infinity,
                height: 120,
              ),
            ),
          ),
          // Bottom hint
          Positioned(
            bottom: 50,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF42C6D4),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Arahkan kamera ke barcode resi pelanggan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  String _getNextStatus(Map<String, dynamic> order) {
    final status = _getOrderStatus(order).toLowerCase().trim();
    
    // Sort reference statuses
    final layanan = order['Layanan'];
    final List<dynamic>? refList = layanan != null
        ? (layanan['referensi_status'] ?? layanan['ReferensiStatus'])
        : null;

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
        if (nameLower.contains('diterima') ||
            nameLower.contains('received') ||
            nameLower.contains('batal') ||
            nameLower.contains('cancel') ||
            nameLower.contains('tolak') ||
            nameLower.contains('reject')) {
          continue;
        }
        sortedList.add(item);
      }
    }

    final currentStatusIdx = sortedList.indexWhere(
      (element) =>
          (element['nama_status'] ?? '').toString().toLowerCase().trim() ==
          status,
    );

    if (currentStatusIdx != -1 && currentStatusIdx < sortedList.length - 1) {
      final nextRef = sortedList[currentStatusIdx + 1];
      return (nextRef['nama_status'] ?? '').toString().toLowerCase().trim();
    }
    return '';
  }
}

// ── Overlay Shape ──────────────────────────────────────────────────────────────
class BarcodeScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  BarcodeScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutWidth = 300,
    this.cutOutHeight = 120,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final _cutOutWidth = cutOutWidth < width ? cutOutWidth : width - 20;
    final _cutOutHeight = cutOutHeight < height ? cutOutHeight : height - 20;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromCenter(
      center: Offset(rect.left + width / 2, rect.top + height / 2),
      width: _cutOutWidth,
      height: _cutOutHeight,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        boxPaint,
      )
      ..restore();

    // Subtle guide box
    final guidePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      guidePaint,
    );

    // Techy L-shaped corners
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final double radius = borderRadius;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.left, cutOutRect.top + radius)
        ..arcToPoint(
          Offset(cutOutRect.left + radius, cutOutRect.top),
          radius: Radius.circular(radius),
        )
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
        ..lineTo(cutOutRect.right - radius, cutOutRect.top)
        ..arcToPoint(
          Offset(cutOutRect.right, cutOutRect.top + radius),
          radius: Radius.circular(radius),
        )
        ..lineTo(cutOutRect.right, cutOutRect.top + borderLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.left, cutOutRect.bottom - radius)
        ..arcToPoint(
          Offset(cutOutRect.left + radius, cutOutRect.bottom),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLength, cutOutRect.bottom)
        ..lineTo(cutOutRect.right - radius, cutOutRect.bottom)
        ..arcToPoint(
          Offset(cutOutRect.right, cutOutRect.bottom - radius),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(cutOutRect.right, cutOutRect.bottom - borderLength),
      cornerPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return BarcodeScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
      cutOutWidth: cutOutWidth,
      cutOutHeight: cutOutHeight,
    );
  }
}

// ── Scanning Line Animation ────────────────────────────────────────────────────
class ScanningLine extends StatefulWidget {
  final double width;
  final double height;
  const ScanningLine(
      {super.key, required this.width, required this.height});

  @override
  State<ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double value = _controller.value;
        final double topOffset = value * (widget.height - 4);
        return Stack(
          children: [
            Positioned(
              top: topOffset,
              left: 4,
              right: 4,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF42C6D4),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF42C6D4).withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF42C6D4).withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
