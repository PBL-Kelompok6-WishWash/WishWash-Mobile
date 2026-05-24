import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/screens/karyawan/main_karyawan.dart';

class ReviewWashIronScreen extends StatefulWidget {
  final Map<String, dynamic> selectedCustomer;
  const ReviewWashIronScreen({super.key, required this.selectedCustomer});

  @override
  State<ReviewWashIronScreen> createState() => _ReviewWashIronScreenState();
}

class _ReviewWashIronScreenState extends State<ReviewWashIronScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color textGrey = const Color(0xFF596063);
  String selectedPayment = 'Cash on Delivery';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC7F3F5), Colors.white],
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
                            'Wash & Iron',
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
                          _buildServiceDetailsCard(),
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

  Widget _buildServiceDetailsCard() {
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
                  color: const Color(0xFFF0F5FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_laundry_service_outlined, color: navyColor, size: 20),
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
                    Text('16 April 2026', style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('08:00 - 12:00 am', style: GoogleFonts.poppins(color: navyColor, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pick Up Address', style: GoogleFonts.poppins(color: navyColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(widget.selectedCustomer['nama_lengkap'] ?? '', style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Jl. Kenanga No. 8, Perum WishWash, Semarang - Alamat ${widget.selectedCustomer['nama_lengkap']}', style: GoogleFonts.poppins(color: navyColor, fontSize: 10)),
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
          Row(
            children: [
              _buildTag('Daily Wear', const Color(0xFFF3E5F5), const Color(0xFF8E24AA)),
              const SizedBox(width: 8),
              _buildTag('Standard', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Fabric Perfume', style: GoogleFonts.poppins(color: navyColor, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.local_florist_outlined, color: Color(0xFF8E24AA), size: 14),
              const SizedBox(width: 4),
              Text('Lavender', style: GoogleFonts.poppins(color: const Color(0xFF8E24AA), fontSize: 11, fontWeight: FontWeight.w600)),
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
            child: Text('-', style: GoogleFonts.poppins(color: const Color(0xFF8E24AA), fontSize: 12, fontWeight: FontWeight.bold)),
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
                  Text('20 April 2026', style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('08:00 - 12:00 am', style: GoogleFonts.poppins(color: navyColor, fontSize: 10)),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: GoogleFonts.poppins(color: navyColor, fontSize: 10)),
                  Text('${widget.selectedCustomer['nama_lengkap']} (${widget.selectedCustomer['no_telp']})', style: GoogleFonts.poppins(color: navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Jl. Kenanga No. 8, Perum WishWash, Semarang - Alamat ${widget.selectedCustomer['nama_lengkap']}', style: GoogleFonts.poppins(color: navyColor, fontSize: 10)),
                ],
              ),
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
        onPressed: () {
          _showConfirmationDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD6F6D5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
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
                        builder: (context) => const MainKaryawan(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF42C6D4), // Cyan color from previous UI
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

