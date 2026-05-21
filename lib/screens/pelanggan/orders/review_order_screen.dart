import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/pelanggan/main_pelanggan.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/services/translation_service.dart';

class ReviewOrderScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> package;
  final Map<String, dynamic> pickupAddress;
  final Map<String, dynamic> deliveryAddress;
  final Map<String, dynamic> perfume;
  final String date; // YYYY-MM-DD
  final String timeSlot; // "Morning" or "Afternoon"
  final String instruction;

  const ReviewOrderScreen({
    super.key,
    required this.service,
    required this.package,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.perfume,
    required this.date,
    required this.timeSlot,
    required this.instruction,
  });

  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color textGrey = const Color(0xFF596063);
  String selectedPayment = 'Cash on Delivery';
  bool _isPlacingOrder = false;

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    try {
      return Color(int.parse('0x$hexColor'));
    } catch (e) {
      return const Color(0xFF00BCD4);
    }
  }

  String formatFriendlyDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      if (parts.length < 3) return isoDate;
      final year = parts[0];
      final monthInt = int.parse(parts[1]);
      final day = parts[2];
      final List<String> months = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '$day ${months[monthInt]} $year';
    } catch (e) {
      return isoDate;
    }
  }

  String calculateDeliveryDate(String isoDate, int durationHours) {
    try {
      final date = DateTime.parse(isoDate);
      final deliveryDate = date.add(Duration(hours: durationHours));
      return deliveryDate.toIso8601String().split('T')[0];
    } catch (e) {
      return isoDate;
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

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    try {
      final double basePrice = (widget.service['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
      final double packageFee = (widget.package['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;
      final double totalBayar = basePrice + packageFee;

      final orderData = {
        'id_layanan': widget.service['id_layanan'],
        'id_paket_layanan': widget.package['id_paket_layanan'],
        'id_alamat_pengambilan': widget.pickupAddress['id_alamat'],
        'id_alamat_penyerahan': widget.deliveryAddress['id_alamat'],
        'id_parfum': widget.perfume['id'],
        'keterangan_lokasi': widget.pickupAddress['tipe_alamat'] ?? 'Rumah',
        'jadwal_pickup': '${widget.date} ${widget.timeSlot == 'Morning' ? '08:00' : '13:00'}',
        'tipe_logistik': 'Courier Delivery',
        'harga_saat_ini': basePrice,
        'kuantitas': 0.0,
        'total_bayar': totalBayar,
        'catatan_order': widget.instruction,
      };

      await OrderService.createOrder(orderData);
      
      setState(() => _isPlacingOrder = false);
      if (mounted) {
        _showConfirmationDialog();
      }
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rawName = widget.service['nama_layanan'] ?? 'Layanan';
    final String serviceName = TranslationService.translateService(rawName);
    final String hexColor = widget.service['warna_layanan'] ?? '#00BCD4';
    final Color themeColor = _parseHexColor(hexColor);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient matching Service Color
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [themeColor.withOpacity(0.25), Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            serviceName,
                            style: GoogleFonts.poppins(
                              color: navyColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Review Order'),
                          const SizedBox(height: 16),
                          _buildServiceDetailsCard(themeColor),
                          const SizedBox(height: 24),

                          _buildPromoCodeCard(),
                          const SizedBox(height: 24),

                          _buildSectionTitleNoLine('Choose Payment Method'),
                          const SizedBox(height: 16),
                          _buildPaymentOption('Cash on Delivery', Icons.payments_outlined),
                          const SizedBox(height: 12),
                          _buildPaymentOption('QRIS', Icons.qr_code_scanner),
                          const SizedBox(height: 32),

                          _buildMakeOrderButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: navyColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1.5,
            color: navyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitleNoLine(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: navyColor,
      ),
    );
  }

  Widget _buildServiceDetailsCard(Color themeColor) {
    final friendlyPickUpDate = formatFriendlyDate(widget.date);
    final int durationHours = widget.package['durasi_jam'] ?? 72;
    final friendlyDeliveryDate = formatFriendlyDate(calculateDeliveryDate(widget.date, durationHours));
    final double basePrice = (widget.service['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final double packageFee = (widget.package['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;
    final double totalBayar = basePrice + packageFee;
    final String unit = widget.service['jenis_satuan'] ?? 'Kg';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_laundry_service_outlined, color: themeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Service Details',
                style: GoogleFonts.poppins(
                  color: navyColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pick Up', style: GoogleFonts.poppins(color: navyColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(friendlyPickUpDate, style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(widget.timeSlot == 'Morning' ? '08:00 - 12:00 am' : '12:00 - 04:00 pm', style: GoogleFonts.poppins(color: navyColor, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pick Up Address', style: GoogleFonts.poppins(color: navyColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(widget.pickupAddress['alamat_lengkap'] ?? '', style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),
          
          Text('Selected Services', style: GoogleFonts.poppins(color: navyColor, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildTag(widget.package['nama_paket'] ?? 'Reguler', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          Text('Fabric Perfume', style: GoogleFonts.poppins(color: navyColor, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.local_florist_outlined, color: Color(0xFF8E24AA), size: 14),
              const SizedBox(width: 4),
              Text(widget.perfume['name'] ?? '', style: GoogleFonts.poppins(color: const Color(0xFF8E24AA), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Care Instruction', style: GoogleFonts.poppins(color: navyColor, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(widget.instruction.isNotEmpty ? widget.instruction : '-', style: GoogleFonts.poppins(color: const Color(0xFF8E24AA), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),

          Text('Estimated Delivery', style: GoogleFonts.poppins(color: navyColor, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF2E7D32), size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friendlyDeliveryDate, style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(widget.timeSlot == 'Morning' ? '08:00 - 12:00 am' : '12:00 - 04:00 pm', style: GoogleFonts.poppins(color: navyColor, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined, color: Color(0xFFFBC02D), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Address', style: GoogleFonts.poppins(color: navyColor, fontSize: 10)),
                    Text(widget.deliveryAddress['alamat_lengkap'] ?? '', style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),

          // dynamic pricing details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Base Price (${widget.service['nama_layanan']})', style: GoogleFonts.poppins(color: textGrey, fontSize: 12)),
              Text('${_formatPrice(basePrice)} / $unit', style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Package Fee (${widget.package['nama_paket']})', style: GoogleFonts.poppins(color: textGrey, fontSize: 12)),
              Text(packageFee > 0 ? _formatPrice(packageFee) : 'Gratis', style: GoogleFonts.poppins(color: packageFee > 0 ? const Color(0xFF1E821B) : textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Price', style: GoogleFonts.poppins(color: navyColor, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(_formatPrice(totalBayar), style: GoogleFonts.poppins(color: const Color(0xFF1E821B), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPromoCodeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleNoLine('Promo Code'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter Code',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: GoogleFonts.poppins(fontSize: 12, color: navyColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  'Apply',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.grey.shade300 : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textGrey, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? navyColor : Colors.grey.shade400, width: 1.5),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: navyColor, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMakeOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD6F6D5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isPlacingOrder
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E821B)),
                ),
              )
            : Text(
                'Make Order',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E821B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Wait for your order to be\nconfirmed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: navyColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainPelanggan(
                          showOrderSuccessNotification: true,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF42C6D4),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text(
                    'Ok',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
}
