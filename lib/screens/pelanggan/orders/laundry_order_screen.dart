import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/alamat_service.dart';
import 'package:mobile/screens/pelanggan/home/alamat_screen.dart';
import 'package:mobile/services/translation_service.dart';
import 'review_order_screen.dart';

class LaundryOrderScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const LaundryOrderScreen({super.key, required this.service});

  @override
  State<LaundryOrderScreen> createState() => _LaundryOrderScreenState();
}

class _LaundryOrderScreenState extends State<LaundryOrderScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color textGrey = const Color(0xFF596063);

  Map<String, dynamic>? selectedPackageMap;
  String selectedPerfume = 'Lavender Bliss';
  int selectedDateIndex = 0;
  String selectedTime = 'Morning';

  List<dynamic> addresses = [];
  Map<String, dynamic>? selectedPickupAddress;
  Map<String, dynamic>? selectedDeliveryAddress;
  bool isLoadingAddresses = true;
  final TextEditingController instructionController = TextEditingController();
  List<Map<String, String>> dates = [];

  // Consistent 4 Perfumes mapping from GORM Database seeder IDs
  final List<Map<String, dynamic>> perfumes = [
    {
      'id': 2,
      'name': 'Lavender Bliss',
      'desc': 'Aroma bunga lavender premium untuk relaksasi mendalam.',
      'icon': Icons.local_florist_outlined,
    },
    {
      'id': 5,
      'name': 'Ocean Breeze',
      'desc': 'Kesegaran hembusan laut segar untuk pakaian aktif.',
      'icon': Icons.water_drop_outlined,
    },
    {
      'id': 4,
      'name': 'Fresh Cotton',
      'desc': 'Keharuman kapas bersih lembut dan hipoalergenik.',
      'icon': Icons.block,
    },
    {
      'id': 1,
      'name': 'Malaikat Subuh',
      'desc': 'Aroma tradisional yang mewah, menenangkan, dan hangat.',
      'icon': Icons.spa_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadAddresses();
    _initDefaultPackage();
  }

  void _initDefaultPackage() {
    final List<dynamic> dbPackages = widget.service['paket_layanan'] ?? [];
    if (dbPackages.isNotEmpty) {
      // Prioritize "Reguler" or standard first
      final regulerIndex = dbPackages.indexWhere(
        (p) => (p['nama_paket']?.toString() ?? '').toLowerCase().contains(
          'reguler',
        ),
      );
      if (regulerIndex != -1) {
        selectedPackageMap = dbPackages[regulerIndex];
      } else {
        selectedPackageMap = dbPackages.first;
      }
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await AlamatService.getAlamat();
      setState(() {
        addresses = list;
        if (list.isNotEmpty) {
          final primary = list.firstWhere(
            (element) => element['is_primary'] == true,
            orElse: () => list.first,
          );
          selectedPickupAddress = primary;
          selectedDeliveryAddress = primary;
        }
        isLoadingAddresses = false;
      });
    } catch (e) {
      setState(() {
        isLoadingAddresses = false;
      });
    }
  }

  void _generateDates() {
    final now = DateTime.now();
    final List<String> months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final List<String> days = [
      '',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    List<Map<String, String>> tempDates = [];
    for (int i = 0; i < 5; i++) {
      final date = now.add(Duration(days: i));
      tempDates.add({
        'month': months[date.month - 1],
        'date': date.day.toString(),
        'day': days[date.weekday],
        'fullDate': date.toIso8601String().split('T')[0],
      });
    }
    setState(() {
      dates = tempDates;
    });
  }

  Future<void> _chooseAddress(bool isDelivery) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlamatScreen()),
    );
    _loadAddresses();
  }

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: navyColor,
                          size: 20,
                        ),
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
                      const SizedBox(width: 40), // Balances the row
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
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
        Expanded(child: Container(height: 1.5, color: navyColor)),
      ],
    );
  }



  Widget _buildPackageCheckboxes() {
    final List<dynamic> dbPackages = widget.service['paket_layanan'] ?? [];
    if (dbPackages.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada paket tersedia.',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dbPackages.map<Widget>((pkg) {
        return Expanded(child: _buildCheckbox(pkg));
      }).toList(),
    );
  }

  Widget _buildCheckbox(Map<String, dynamic> pkg) {
    final name = pkg['nama_paket'] ?? '';
    final additionalFee = (pkg['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;
    final duration = pkg['durasi_jam'] ?? 0;
    final isSelected =
        selectedPackageMap?['id_paket_layanan'] == pkg['id_paket_layanan'];

    return GestureDetector(
      onTap: () => setState(() => selectedPackageMap = pkg),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? navyColor.withOpacity(0.04) : Colors.transparent,
          border: Border.all(
            color: isSelected ? navyColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? navyColor : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: navyColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              additionalFee > 0 ? '+Rp ${additionalFee.toInt()}' : 'Gratis',
              style: GoogleFonts.poppins(
                color: additionalFee > 0
                    ? const Color(0xFF1E821B)
                    : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            Text(
              '$duration Jam',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 9,
              ),
            ),
          ],
        ),
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
              border: Border.all(
                color: isSelected
                    ? navyColor.withOpacity(0.5)
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
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
                        color: navyColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(perfume['icon'], color: navyColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        perfume['name'],
                        style: GoogleFonts.poppins(
                          color: textGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    perfume['desc'],
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 9,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: instructionController,
        maxLines: 3,
        decoration: InputDecoration.collapsed(
          hintText: 'Instruksi khusus untuk Kurir atau Washer ....',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 11,
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 12, color: textGrey),
      ),
    );
  }

  Widget _buildLocationCard({required bool isDelivery}) {
    final address = isDelivery
        ? selectedDeliveryAddress
        : selectedPickupAddress;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
              color: const Color(0xFF0C4B8E).withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
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
                      isLoadingAddresses
                          ? 'Loading address...'
                          : address != null
                          ? '${address['alamat_lengkap']} (${address['tipe_alamat']}) - Penerima: ${address['nama_penerima']}'
                          : 'Alamat belum disetel. Ketuk tombol untuk menambahkan.',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _chooseAddress(isDelivery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3E9EC),
                        foregroundColor: textGrey,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        address != null ? 'Change Address' : 'Add Address',
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
                border: Border.all(
                  color: isSelected ? navyColor : Colors.transparent,
                  width: isSelected ? 1.5 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
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
        Expanded(child: _buildTimeOption('Morning', '08:00 - 12:00 am')),
        const SizedBox(width: 12),
        Expanded(child: _buildTimeOption('Afternoon', '12:00 - 04:00 pm')),
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
              border: Border.all(
                color: isSelected
                    ? navyColor.withOpacity(0.5)
                    : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
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
            'Layanan Express / Kilat',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B3B9C),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih paket Express atau Kilat di bagian atas untuk waktu pengerjaan yang super cepat.',
            style: GoogleFonts.poppins(
              color: textGrey,
              fontSize: 10,
              height: 1.4,
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
          if (selectedPickupAddress == null ||
              selectedDeliveryAddress == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Silakan pilih alamat terlebih dahulu!'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
          if (selectedPackageMap == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Silakan pilih paket laundry terlebih dahulu!'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }

          final perf = perfumes.firstWhere(
            (p) => p['name'] == selectedPerfume,
            orElse: () => perfumes.first,
          );
          final dateStr =
              dates[selectedDateIndex]['fullDate'] ??
              DateTime.now().toIso8601String().split('T')[0];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewOrderScreen(
                service: widget.service,
                package: selectedPackageMap!,
                pickupAddress: selectedPickupAddress!,
                deliveryAddress: selectedDeliveryAddress!,
                perfume: perf,
                date: dateStr,
                timeSlot: selectedTime,
                instruction: instructionController.text,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD6F6D5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
