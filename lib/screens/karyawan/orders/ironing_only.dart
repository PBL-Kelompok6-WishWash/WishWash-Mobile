import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'review_ironing_only.dart';

class IroningOnlyScreen extends StatefulWidget {
  final Map<String, dynamic> selectedCustomer;
  const IroningOnlyScreen({super.key, required this.selectedCustomer});

  @override
  State<IroningOnlyScreen> createState() => _IroningOnlyScreenState();
}

class _IroningOnlyScreenState extends State<IroningOnlyScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color textGrey = const Color(0xFF596063);

  String selectedType = 'Daily Wear';
  String selectedPackage = 'Standard';
  String selectedPerfume = 'Lavender';
  int selectedDateIndex = 0;
  String selectedTime = 'Morning';

  final List<Map<String, dynamic>> perfumes = [
    {
      'name': 'Lavender',
      'desc': 'Calming botanical notes for deep relaxation.',
      'icon': Icons.local_florist_outlined
    },
    {
      'name': 'Aqua',
      'desc': 'Crisp, salt-air freshness for active wear.',
      'icon': Icons.water_drop_outlined
    },
    {
      'name': 'Vanilla',
      'desc': 'Warm, sweet comforting notes for linens.',
      'icon': Icons.spa_outlined
    },
    {
      'name': 'Unscented',
      'desc': 'Hypoallergenic purity for sensitive skin.',
      'icon': Icons.block
    },
  ];

  final List<Map<String, String>> dates = [
    {'month': 'APR', 'date': '14', 'day': 'MON'},
    {'month': 'APR', 'date': '15', 'day': 'TUE'},
    {'month': 'APR', 'date': '16', 'day': 'WED'},
    {'month': 'APR', 'date': '17', 'day': 'THU'},
    {'month': 'APR', 'date': '18', 'day': 'FRI'},
  ];

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
                            'Ironing Only',
                            style: GoogleFonts.poppins(
                              color: navyColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Balances the row
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Select Laundry Package'),
                          const SizedBox(height: 16),
                          _buildTypeSelection(),
                          const SizedBox(height: 16),
                          _buildPackageCheckboxes(),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Select Fabric Perfume'),
                          const SizedBox(height: 16),
                          _buildPerfumeGrid(),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Care Instruction'),
                          const SizedBox(height: 16),
                          _buildCareInstruction(),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Pick Up Location'),
                          const SizedBox(height: 16),
                          _buildLocationCard(isDelivery: false),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Pick Up Date & Time'),
                          const SizedBox(height: 16),
                          _buildDateSelection(),
                          const SizedBox(height: 16),
                          _buildTimeSelection(),
                          const SizedBox(height: 16),
                          _buildExpressBanner(),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Delivery Location'),
                          const SizedBox(height: 16),
                          _buildLocationCard(isDelivery: true),
                          const SizedBox(height: 12),
                          _buildPickUpStoreButton(),
                          const SizedBox(height: 32),

                          _buildReviewOrderButton(),
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

  Widget _buildTypeSelection() {
    return Row(
      children: [
        Expanded(child: _buildTypeOption('Daily Wear')),
        const SizedBox(width: 16),
        Expanded(child: _buildTypeOption('Bedding')),
      ],
    );
  }

  Widget _buildTypeOption(String title) {
    final isSelected = selectedType == title;
    return GestureDetector(
      onTap: () => setState(() => selectedType = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: navyColor, width: isSelected ? 1.2 : 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: navyColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: navyColor,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCheckboxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCheckbox('Standard'),
        _buildCheckbox('Premium'),
        _buildCheckbox('Express'),
      ],
    );
  }

  Widget _buildCheckbox(String title) {
    final isSelected = selectedPackage == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPackage = title),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: textGrey.withOpacity(0.5), width: 1.5),
              color: isSelected ? textGrey.withOpacity(0.1) : Colors.transparent,
            ),
            child: isSelected ? Icon(Icons.check, size: 14, color: textGrey) : null,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: navyColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfumeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: perfumes.length,
      itemBuilder: (context, index) {
        final perfume = perfumes[index];
        final isSelected = selectedPerfume == perfume['name'];
        return GestureDetector(
          onTap: () => setState(() => selectedPerfume = perfume['name']),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.grey.shade300 : Colors.transparent, width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(perfume['icon'], color: textGrey, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        perfume['name'],
                        style: GoogleFonts.poppins(
                          color: textGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  perfume['desc'],
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 9.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCareInstruction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        maxLines: 3,
        decoration: InputDecoration.collapsed(
          hintText: 'Special instructions for the Courier or Washer ....',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 11),
        ),
        style: GoogleFonts.poppins(fontSize: 12, color: textGrey),
      ),
    );
  }

  Widget _buildLocationCard({required bool isDelivery}) {
    final String customerName = widget.selectedCustomer['nama_lengkap'] ?? '';
    final String customerPhone = widget.selectedCustomer['no_telp'] ?? '';
    final String customerAddress = 'Jl. Kenanga No. 8, Perum WishWash, Semarang - Alamat $customerName';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Placeholder
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF5A9B93),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Simulated map lines for placeholder effect
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: CustomPaint(painter: MapLinesPainter()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, color: navyColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDelivery ? 'Delivery Address' : 'Pick Up Address',
                      style: GoogleFonts.poppins(
                        color: textGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$customerName ($customerPhone)',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerAddress,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3E9EC),
                        foregroundColor: textGrey,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Edit Address',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = selectedDateIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedDateIndex = index),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? navyColor : Colors.transparent, width: isSelected ? 1 : 0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date['month']!,
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date['date']!,
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date['day']!,
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildTimeOption('Morning', '08:00 - 12:00 am'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTimeOption('Afternoon', '12:00 - 04:00 pm'),
        ),
      ],
    );
  }

  Widget _buildTimeOption(String title, String time) {
    final isSelected = selectedTime == title;
    return GestureDetector(
      onTap: () => setState(() => selectedTime = title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: navyColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? navyColor.withOpacity(0.5) : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: GoogleFonts.poppins(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Express Cleaning',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B3B9C),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select a morning slot for same-day delivery on all "Everyday Essentials" items. ',
            style: GoogleFonts.poppins(
              color: textGrey,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          Text(
            'Learn more',
            style: GoogleFonts.poppins(
              color: textGrey,
              fontSize: 10,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickUpStoreButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, color: textGrey, size: 20),
          const SizedBox(width: 8),
          Text(
            'Pick Up in Store',
            style: GoogleFonts.poppins(
              color: textGrey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewIroningOnlyScreen(
                selectedCustomer: widget.selectedCustomer,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD6F6D5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Review Order',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E821B),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// A simple painter to draw some arbitrary lines resembling a map pattern
class MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < 20; i++) {
      path.moveTo(i * 25.0, 0);
      path.lineTo(size.width, size.height - (i * 20.0));
      
      path.moveTo(0, i * 20.0);
      path.lineTo(size.width - (i * 25.0), size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

