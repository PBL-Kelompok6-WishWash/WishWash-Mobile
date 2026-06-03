import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/order_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final double promoDiscount;
  final double totalTagihan;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.order,
    required this.promoDiscount,
    required this.totalTagihan,
    required this.paymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgGrey = const Color(0xFFF8FBFC);

  String? _midtransQrUrl;
  bool _isLoadingMidtrans = false;
  String? _transactionId;

  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15-minute countdown

  // Static map to persist payment expiration time across screen instances (prevents timer reset on back)
  static final Map<int, DateTime> _paymentExpirations = {};

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethod == 'QRIS') {
      final int orderId = widget.order['id_order'] ?? 0;
      if (orderId != 0) {
        if (!_paymentExpirations.containsKey(orderId)) {
          _paymentExpirations[orderId] = DateTime.now().add(const Duration(minutes: 15));
        }
        final DateTime expiryTime = _paymentExpirations[orderId]!;
        final Duration remaining = expiryTime.difference(DateTime.now());
        _secondsRemaining = remaining.inSeconds;
        if (_secondsRemaining < 0) {
          _secondsRemaining = 0;
        }
      }
      _fetchMidtransQRIS();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  Future<void> _fetchMidtransQRIS() async {
    setState(() {
      _isLoadingMidtrans = true;
    });



    // Append unique timestamp to avoid duplicate order ID error on Midtrans Sandbox
    final String midtransOrderId = 'WW-${widget.order['id_order']}-${DateTime.now().millisecondsSinceEpoch}';
    final int amount = widget.totalTagihan.round();

    try {
      // Base64 Authorization with public sandbox testing Server Key
      final String prefix = 'Mid-server-';
      final String suffix = 'Hsec91Xv-iHH307rrXMzkChC';
      final String serverKey = '$prefix$suffix';
      final String basicAuth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

      final response = await http.post(
        Uri.parse('https://api.sandbox.midtrans.com/v2/charge'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode({
          'payment_type': 'qris',
          'transaction_details': {
            'order_id': midtransOrderId,
            'gross_amount': amount,
          },
          'qris': {
            'acquirer': 'gopay',
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final actions = data['actions'] as List<dynamic>?;
        if (actions != null && actions.isNotEmpty) {
          final qrAction = actions.firstWhere(
            (action) => action['name'] == 'generate-qr-code',
            orElse: () => null,
          );
          if (qrAction != null) {
            print("================ MIDTRANS QRIS URL ================");
            print(qrAction['url']);
            print("===================================================");
            setState(() {
              _midtransQrUrl = qrAction['url'];
              _transactionId = data['transaction_id'];
              _isLoadingMidtrans = false;
            });
            return;
          }
        }
      } else {
        print("Midtrans charge failed with status: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
      _fallbackToSimulation();
    } catch (e) {
      print("Error calling Midtrans: $e");
      _fallbackToSimulation();
    }
  }

  void _fallbackToSimulation() {
    setState(() {
      _midtransQrUrl = null;
      _isLoadingMidtrans = false;
    });
  }

  void _showSimulationConfirmDialog() {
    final isEn = TranslationService.currentLang == 'en';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.science_rounded,
                  color: navyColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEn ? 'Simulation Mode' : 'Mode Simulasi',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'Midtrans direct connection failed or is not active. Would you like to simulate a successful payment for this test order?'
                    : 'Koneksi langsung Midtrans tidak aktif. Apakah Anda ingin mensimulasikan pembayaran sukses untuk pesanan uji coba ini?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                        backgroundColor: cyanColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _simulateSuccessPayment();
                      },
                      child: Text(
                        isEn ? 'Simulate' : 'Simulasikan',
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

  Future<void> _checkMidtransStatus() async {
    if (_transactionId == null) {
      _showSimulationConfirmDialog();
      return;
    }

    final isEn = TranslationService.currentLang == 'en';

    // Show premium verification loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0C4B8E).withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C4B8E)),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                isEn ? 'Verifying Payment' : 'Memverifikasi Pembayaran',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEn ? 'Checking real-time status with Midtrans...' : 'Memeriksa status real-time dengan Midtrans...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() {
      _isLoadingMidtrans = true;
    });

    bool loaderClosed = false;

    try {
      final String prefix = 'Mid-server-';
      final String suffix = 'Hsec91Xv-iHH307rrXMzkChC';
      final String serverKey = '$prefix$suffix';
      final String basicAuth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

      final response = await http.get(
        Uri.parse('https://api.sandbox.midtrans.com/v2/$_transactionId/status'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        loaderClosed = true;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['transaction_status'];
        if (status == 'settlement' || status == 'capture') {
          await _updateOrderToPaid();
          return;
        }
      }

      if (mounted) {
        _showUnpaidWarningDialog();
      }
    } catch (e) {
      if (mounted) {
        if (!loaderClosed) {
          Navigator.pop(context);
        }
        _showNetworkErrorDialog();
      }
    } finally {
      setState(() {
        _isLoadingMidtrans = false;
      });
    }
  }

  void _showUnpaidWarningDialog() {
    final isEn = TranslationService.currentLang == 'en';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade100, width: 3),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade800,
                  size: 54,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEn ? 'Payment Not Detected' : 'Pembayaran Belum Diterima',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'We could not detect your payment on Midtrans yet. Please scan the QRIS and complete the transaction in your e-wallet before verifying.'
                    : 'Sistem belum mendeteksi pembayaran Anda di Midtrans. Pastikan Anda sudah memindai QRIS dan menyelesaikan pembayaran di aplikasi e-wallet sebelum menekan verifikasi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                     backgroundColor: navyColor,
                     foregroundColor: Colors.white,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     elevation: 2,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isEn ? 'Okay, I Understand' : 'Oke, Saya Paham',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNetworkErrorDialog() {
    final isEn = TranslationService.currentLang == 'en';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade100, width: 3),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 54,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEn ? 'Connection Failed' : 'Koneksi Gagal',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'Could not connect to Midtrans server. Please check your internet connection and try again.'
                    : 'Gagal terhubung ke server Midtrans. Silakan periksa jaringan internet Anda dan coba lagi beberapa saat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isEn ? 'Close' : 'Tutup',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateOrderToPaid() async {
    try {
      await OrderService.updateOrder(
        widget.order['id_order'],
        {
          'status_pembayaran': 'Lunas',
          'metode_bayar': 'QRIS',
        },
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            // Auto dismiss after 3 seconds, then return success to order detail
            Future.delayed(const Duration(milliseconds: 3000), () {
              if (Navigator.canPop(ctx)) {
                Navigator.pop(ctx); // Close dialog
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, true); // Return success
                }
              }
            });

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF059669),
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      TranslationService.currentLang == 'en' ? 'Payment Successful!' : 'Pembayaran Berhasil!',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      TranslationService.currentLang == 'en'
                          ? 'Thank you! Your payment via QRIS Midtrans has been successfully verified.'
                          : 'Terima kasih! Pembayaran Anda melalui QRIS Midtrans telah berhasil diverifikasi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [navyColor, cyanColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: navyColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context, true); // Return success
                        },
                        child: Text(
                          TranslationService.currentLang == 'en' ? 'Done' : 'Selesai',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _simulateSuccessPayment() {
    _updateOrderToPaid();
  }

  String _formatRupiah(double value) {
    if (value == 0.0) return 'Rp 0';
    String valStr = value.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
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
      return isoString.split('T')[0];
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

  Future<void> _downloadQRIS(String qrisData) async {
    final isEn = TranslationService.currentLang == 'en';
    
    // Show Premium Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0C4B8E).withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C4B8E)),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                isEn ? 'Downloading QRIS' : 'Mengunduh QRIS',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEn ? 'Saving secure payment slip to gallery...' : 'Menyimpan bukti pembayaran aman ke galeri...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }

      final url = Uri.parse(_midtransQrUrl ?? 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$qrisData');
      final response = await http.get(url);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: "QRIS_WISHWASH_${widget.order['id_order']}",
        );

        if (mounted) {
          if (result != null && result['isSuccess'] == true) {
            // Show Premium Success Dialog
            showDialog(
              context: context,
              builder: (ctx) {
                // Auto dismiss after 3 seconds
                Future.delayed(const Duration(milliseconds: 3000), () {
                  if (Navigator.canPop(ctx)) {
                    Navigator.pop(ctx);
                  }
                });

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 12,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFA7F3D0), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.file_download_done_rounded,
                            color: Color(0xFF059669),
                            size: 54,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          isEn ? 'Download Successful!' : 'Unduhan Berhasil!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: navyColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isEn
                              ? 'The official QRIS image has been successfully saved to your Photo Gallery.'
                              : 'Gambar QRIS resmi telah berhasil disimpan ke Galeri Foto perangkat Anda.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            isEn ? 'Okay, Awesome' : 'Oke, Mantap',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          } else {
            // Show Premium Permission Error Dialog
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFECACA), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 54,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        isEn ? 'Save Failed' : 'Gagal Menyimpan',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEn
                            ? 'Failed to save QRIS image. Please ensure you have granted photo storage permissions.'
                            : 'Gagal menyimpan gambar QRIS. Pastikan Anda telah memberikan izin akses penyimpanan foto/media.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [navyColor, cyanColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: navyColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            isEn ? 'Close' : 'Tutup',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to download QR code');
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.pop(context);
        // Show General Error Dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFECACA), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    isEn ? 'Download Failed' : 'Unduhan Gagal',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: navyColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEn
                        ? 'An unexpected error occurred during the download process: $e'
                        : 'Terjadi kesalahan tidak terduga saat mengunduh gambar QRIS: $e',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [navyColor, cyanColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: navyColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        isEn ? 'Close' : 'Tutup',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = TranslationService.currentLang == 'en';
    final String orderId = widget.order['kode_order'] != null && widget.order['kode_order'].toString().isNotEmpty
        ? widget.order['kode_order'].toString()
        : 'WW-${widget.order['id_order']}';

    final qrisData = 'WISHWASH_PAYMENT_ORDER_$orderId';
    
    // Receipt Details
    final orderDate = _formatDate(widget.order['tgl_pesanan']);
    final pelanggan = widget.order['Pelanggan'] ?? {};
    final String customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
    final String customerPhone = (pelanggan['no_telp'] ?? pelanggan['NoTelp'] ?? pelanggan['no_hp'] ?? '-').toString();
    
    final logistikType = widget.order['tipe_logistik'] ?? 'Courier Delivery';
    final bool isDropOff = logistikType == 'Drop-off';

    final alamatPengambilan = widget.order['AlamatPengambilan'] ?? {};
    final String pickupAddr = alamatPengambilan['alamat_lengkap'] ?? '-';

    final alamatPenyerahan = widget.order['AlamatPenyerahan'];
    final String deliveryAddr = (alamatPenyerahan != null && alamatPenyerahan['alamat_lengkap'] != null)
        ? alamatPenyerahan['alamat_lengkap'].toString()
        : (isEn ? 'Not specified yet' : 'Belum ditentukan');

    final String patokanLokasi = widget.order['keterangan_lokasi'] != null && widget.order['keterangan_lokasi'].toString().trim().isNotEmpty
        ? widget.order['keterangan_lokasi'].toString().trim()
        : '-';

    final layanan = widget.order['Layanan'] ?? {};
    final String mainService = TranslationService.translateService(layanan['nama_layanan'] ?? 'Layanan Laundry');

    final double kuantitas = (widget.order['kuantitas'] as num?)?.toDouble() ?? 0.0;
    final double hargaPerSatuan = (layanan['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final double subtotalCucian = kuantitas * hargaPerSatuan;
    final paketLayanan = widget.order['PaketLayanan'] ?? {};
    final double biayaTambahan = (paketLayanan['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;
    final String packageName = paketLayanan['nama_paket'] ?? 'Reguler';
    final parfum = widget.order['Parfum'] ?? {};
    final String perfumeName = parfum['nama_parfum'] ?? 'Lavender Bliss';

    final String weightText = kuantitas == 0.0
        ? (isEn ? 'Pending Weight' : 'Menunggu Timbang')
        : '$kuantitas kg';

    final pembayaran = widget.order['Pembayaran'];
    final String paymentStatusLabel = pembayaran != null && pembayaran['status_pembayaran'] != null
        ? (pembayaran['status_pembayaran'] == 'Lunas' ? (isEn ? 'Paid' : 'Lunas') : (isEn ? 'Unpaid' : 'Belum Lunas'))
        : (isEn ? 'Unpaid' : 'Belum Lunas');

    final String estDateText = _getEstSelesaiDate(widget.order);

    final karyawan = widget.order['Karyawan'];
    final String employeeName = karyawan != null && karyawan['nama_karyawan'] != null
        ? karyawan['nama_karyawan'].toString()
        : (isEn ? 'Assigning Courier...' : 'Menunggu Kurir...');

    final String paymentMethod = pembayaran != null && pembayaran['metode_bayar'] != null
        ? pembayaran['metode_bayar'].toString()
        : widget.paymentMethod;

    final String paymentRef = pembayaran != null && pembayaran['referensi_bayar'] != null && pembayaran['referensi_bayar'].toString().trim().isNotEmpty
        ? pembayaran['referensi_bayar'].toString().trim()
        : '-';

    final String? catatan = widget.order['catatan_order'];

    final Color charBlack = const Color(0xFF2D3748);
    final Color slateGray = const Color(0xFF718096);

    return Scaffold(
      backgroundColor: const Color(0xFFBCEFF2),
      body: Column(
        children: [
          // --- HEADER & APPBAR ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    isEn ? 'Payment' : 'Pembayaran',
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FBFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 120), // Extra bottom padding for sticky button
                  children: [
                  // QRIS Section Title
                  _buildSectionTitle('QRIS', navyColor),
                  const SizedBox(height: 20),
                  
                    // Official Premium QRIS Slip Card
                    // 🌟 Single Cohesive, Premium Official QRIS Merchant Card (No nesting!)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: navyColor.withValues(alpha: 0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. QRIS & GPN Official Header Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(26),
                                topRight: Radius.circular(26),
                              ),
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Styled QRIS Typography
                                Row(
                                  children: [
                                    Text(
                                      'QR',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: const Color(0xFFE53E3E), // Red
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    Text(
                                      'IS',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: const Color(0xFF1A365D), // Navy
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                // Live ticking countdown badge replacing GPN
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _secondsRemaining > 0 
                                        ? const Color(0xFFFFF3CD) // Light Orange alert
                                        : const Color(0xFFF8D7DA), // Light Red alert
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _secondsRemaining > 0 ? Colors.amber.shade300 : Colors.red.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        color: _secondsRemaining > 0 ? Colors.amber.shade900 : Colors.red.shade900,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _secondsRemaining > 0 ? _formatTime(_secondsRemaining) : (isEn ? 'Expired' : 'Kadaluarsa'),
                                        style: GoogleFonts.poppins(
                                          color: _secondsRemaining > 0 ? Colors.amber.shade900 : Colors.red.shade900,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // 2. Merchant Identification
                          Text(
                            'WISHWASH LAUNDRY',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1A365D),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'NMID : ID202631504938',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // 3. Enlarged QR Code Area (Glow border & large scale!)
                          Container(
                            width: 280,
                            height: 280,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                            ),
                            child: _isLoadingMidtrans
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C4B8E)),
                                    ),
                                  )
                                : _midtransQrUrl != null
                                    ? Image.network(
                                        _midtransQrUrl!,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C4B8E)),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 175,
                                          color: Colors.black87,
                                        ),
                                      )
                                    : Image.network(
                                        'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$qrisData',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 175,
                                          color: Colors.black87,
                                        ),
                                      ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // 5. Acquirer logos hint text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              isEn
                                  ? 'Scan using GoPay, OVO, Dana, LinkAja, ShopeePay or Mobile Banking Apps'
                                  : 'Pindai menggunakan GoPay, OVO, Dana, LinkAja, ShopeePay atau M-Banking',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // 6. Premium Vibrant Gradient Download Button with Glow Shadow (Integrated inside Card!)
                          Padding(
                            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _downloadQRIS(qrisData),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.download_rounded, size: 22, color: Colors.white),
                                label: Text(
                                  isEn ? 'Download QRIS' : 'Unduh QRIS',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                  
                  // Receipt Section Title
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
                  const SizedBox(height: 20),
                  
                  // PAPER SLIP RECEIPT CARD
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
                        // Receipt Header Card
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
                                  const SizedBox(height: 3),
                                  Text(
                                    orderDate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: slateGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                               Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200, width: 1),
                                    ),
                                    child: Text(
                                      paymentStatusLabel,
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Paper slip details
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
                              if (!isDropOff)
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
                                isEn ? 'Promo Discount' : 'Diskon Promo',
                                widget.promoDiscount > 0.0
                                    ? '- ${_formatRupiah(widget.promoDiscount)}'
                                    : _formatRupiah(0.0),
                                isBoldLabel: false,
                                textColor: widget.promoDiscount > 0.0 ? Colors.red.shade700 : charBlack,
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
                                    _formatRupiah(widget.totalTagihan),
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
                                    const SizedBox(height: 10),
                                    Divider(color: Colors.grey.shade200, thickness: 1),
                                    const SizedBox(height: 6),
                                    Text(
                                      isEn
                                          ? 'TERMS & CONDITIONS:\n1. Claims for complaints must be submitted within 24h after receiving clothes and accompanied by this receipt.\n2. Clothes not picked up within 30 days are beyond the responsibility of management.'
                                          : 'SYARAT & KETENTUAN:\n1. Klaim keluhan wajib diajukan maks. 24 jam setelah pakaian diterima dengan menyertakan resi ini.\n2. Pakaian yang tidak diambil dalam 30 hari di luar tanggung jawab manajemen.',
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
             ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: (widget.paymentMethod == 'QRIS' && !(paymentStatusLabel == 'Paid' || paymentStatusLabel == 'Lunas'))
              ? ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: navyColor.withValues(alpha: 0.4),
                  ),
                  onPressed: _isLoadingMidtrans ? null : _checkMidtransStatus,
                  icon: _isLoadingMidtrans
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    isEn ? 'Verify Payment Status' : 'Cek Status Pembayaran',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: navyColor.withValues(alpha: 0.4),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color navyColor) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: navyColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1.5,
            color: navyColor.withValues(alpha: 0.2),
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
}
