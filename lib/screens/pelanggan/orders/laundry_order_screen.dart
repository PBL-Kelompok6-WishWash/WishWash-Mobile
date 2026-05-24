import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/alamat_service.dart';
import 'package:mobile/screens/pelanggan/home/alamat_screen.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/screens/pelanggan/main_pelanggan.dart';
import 'package:mobile/screens/karyawan/main_karyawan.dart';
import 'package:mobile/utils/constants.dart';

class LaundryOrderScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic>? selectedCustomer;

  const LaundryOrderScreen({super.key, required this.service, this.selectedCustomer});

  @override
  State<LaundryOrderScreen> createState() => _LaundryOrderScreenState();
}

class _LaundryOrderScreenState extends State<LaundryOrderScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color textGrey = const Color(0xFF596063);
  final Color activeSelectionColor = const Color(0xFF1A56A6);

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

  Widget _buildServiceImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 20),
      );
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64Content = imagePath.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image, size: 20),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 20);
      }
    } else if (imagePath.startsWith('/uploads/')) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      return Image.network(
        '$staticHost$imagePath',
        fit: BoxFit.cover,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 20),
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 20),
      );
    }
  }

  Map<String, dynamic>? selectedPackageMap;
  String selectedPerfume = 'Lavender Bliss';
  int selectedDateIndex = 0;
  String selectedTime = 'Morning';

  List<dynamic> addresses = [];
  Map<String, dynamic>? selectedPickupAddress;
  bool isLoadingAddresses = true;
  final TextEditingController instructionController = TextEditingController();
  List<Map<String, String>> dates = [];
  bool _isPlacingOrder = false;

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

    // Automatically switch default selectedTime to Afternoon if today is already past 12:00 PM
    if (DateTime.now().hour >= 12) {
      selectedTime = 'Afternoon';
    }
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
      final list = await AlamatService.getAlamat(
        idPelanggan: widget.selectedCustomer?['id_pelanggan'],
      );
      setState(() {
        addresses = list;
        if (list.isNotEmpty) {
          final primary = list.firstWhere(
            (element) => element['is_primary'] == true,
            orElse: () => list.first,
          );
          selectedPickupAddress = primary;
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
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          // Background Gradient matching Service Color
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [themeColor.withOpacity(0.22), const Color(0xFFF6F8FB)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom Premium AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: navyColor,
                              size: 16,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              serviceName,
                              style: GoogleFonts.poppins(
                                color: navyColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 44), // Balances the row
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Service Header Info Card
                        _buildServiceHeaderCard(serviceName, themeColor),
                        const SizedBox(height: 20),

                        // Section 1: Paket Laundry
                        _buildCardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                TranslationService.currentLang == 'en'
                                    ? 'Select Laundry Package'
                                    : 'Pilih Paket Laundry',
                              ),
                              const SizedBox(height: 16),
                              _buildExpressBanner(),
                              const SizedBox(height: 16),
                              _buildPackageCheckboxes(themeColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Parfum
                        _buildCardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                TranslationService.currentLang == 'en'
                                    ? 'Select Fabric Perfume'
                                    : 'Pilih Parfum Pakaian',
                              ),
                              const SizedBox(height: 16),
                              _buildPerfumeGrid(themeColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Instruksi Khusus
                        _buildCardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                TranslationService.currentLang == 'en'
                                    ? 'Care Instruction (Optional)'
                                    : 'Instruksi Khusus (Opsional)',
                              ),
                              const SizedBox(height: 16),
                              _buildCareInstruction(themeColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 4: Lokasi Penjemputan
                        _buildCardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                TranslationService.currentLang == 'en'
                                    ? 'Pick Up Location'
                                    : 'Lokasi Penjemputan',
                              ),
                              const SizedBox(height: 16),
                              _buildLocationCard(themeColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 5: Tanggal & Waktu Jemput
                        _buildCardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                TranslationService.currentLang == 'en'
                                    ? 'Pick Up Date & Time'
                                    : 'Tanggal & Waktu Jemput',
                              ),
                              const SizedBox(height: 16),
                              _buildDateSelection(themeColor),
                              const SizedBox(height: 16),
                              _buildTimeSelection(themeColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit order button
                        _buildReviewOrderButton(),
                        const SizedBox(height: 24),
                      ],
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
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: navyColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: navyColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceHeaderCard(String serviceName, Color themeColor) {
    final String rawName = widget.service['nama_layanan'] ?? '';
    final String imagePath = widget.service['gambar_layanan'] ?? 'assets/images/services/wash_only.png';
    final double price = (widget.service['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final String unit = widget.service['jenis_satuan'] ?? 'Kg';
    final String priceText = '${_formatPrice(price)} / $unit';

    // Multi-language translation support for service description
    final String dbDesc = widget.service['deskripsi_layanan'] ?? '';
    String description = dbDesc;
    final key = rawName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('&', 'and');
    final localKey = '${key}_desc';
    if (TranslationService.translate(localKey) != localKey) {
      description = TranslationService.translate(localKey);
    }
    if (description.isEmpty) {
      description = TranslationService.currentLang == 'en'
          ? 'Premium service wash, clean & hygienic'
          : 'Layanan premium cuci bersih, wangi & higienis';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Title, Description, and Unit Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  serviceName,
                  style: GoogleFonts.poppins(
                    color: navyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: textGrey,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeSelectionColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${TranslationService.currentLang == 'en' ? 'Unit Price' : 'Harga Satuan'}: $priceText',
                    style: GoogleFonts.poppins(
                      color: activeSelectionColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: Service Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildServiceImage(imagePath),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPackageCheckboxes(Color themeColor) {
    final List<dynamic> dbPackages = widget.service['paket_layanan'] ?? [];
    if (dbPackages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            TranslationService.currentLang == 'en' ? 'No packages available' : 'Tidak ada paket tersedia.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      children: dbPackages.map<Widget>((pkg) {
        return _buildPackageItem(pkg, themeColor);
      }).toList(),
    );
  }

  Widget _buildPackageItem(Map<String, dynamic> pkg, Color themeColor) {
    final name = pkg['nama_paket'] ?? '';
    final additionalFee = (pkg['biaya_tambahan'] as num?)?.toDouble() ?? 0.0;
    final duration = pkg['durasi_jam'] ?? 0;
    final isSelected =
        selectedPackageMap?['id_paket_layanan'] == pkg['id_paket_layanan'];

    return GestureDetector(
      onTap: () => setState(() => selectedPackageMap = pkg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeSelectionColor.withOpacity(0.04) : Colors.white,
          border: Border.all(
            color: isSelected ? activeSelectionColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? activeSelectionColor.withOpacity(0.06) 
                  : Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? activeSelectionColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activeSelectionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.grey.shade500, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        TranslationService.currentLang == 'en' 
                            ? 'Processing: $duration Hours' 
                            : 'Estimasi: $duration Jam',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: additionalFee > 0 
                    ? const Color(0xFFE8F5E9) 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                additionalFee > 0 ? '+Rp ${additionalFee.toInt()}' : 'Gratis',
                style: GoogleFonts.poppins(
                  color: additionalFee > 0 
                      ? const Color(0xFF2E7D32) 
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfumeGrid(Color themeColor) {
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? activeSelectionColor : Colors.grey.shade100,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? activeSelectionColor.withOpacity(0.08) 
                      : Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? activeSelectionColor.withOpacity(0.12) 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            perfume['icon'], 
                            color: isSelected ? activeSelectionColor : Colors.grey.shade600, 
                            size: 16
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            perfume['name'],
                            style: GoogleFonts.poppins(
                              color: navyColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: activeSelectionColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
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

  Widget _buildCareInstruction(Color themeColor) {
    final List<String> tags = TranslationService.currentLang == 'en'
        ? ['Do not mix colors', 'Gentle fabric', 'Extra perfume', 'No hangers', 'Flat dry']
        : ['Jangan campur warna', 'Bahan sensitif', 'Parfum ekstra', 'Setrika licin', 'Gantung saja'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Icon(Icons.edit_note_rounded, color: activeSelectionColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: instructionController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 12, color: textGrey),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: TranslationService.currentLang == 'en'
                        ? 'Special care instructions for Courier or Washer...'
                        : 'Instruksi khusus untuk Kurir atau Washer...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tags.map((tag) {
              return GestureDetector(
                onTap: () {
                  final text = instructionController.text.trim();
                  if (text.isEmpty) {
                    instructionController.text = tag;
                  } else if (!text.contains(tag)) {
                    instructionController.text = '$text, $tag';
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        tag,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Color themeColor) {
    final address = selectedPickupAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map Placeholder
        Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0D253F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: MapLinesPainter()),
              ),
              Positioned(
                bottom: 10,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF42C6D4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GPS ACTIVE',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Pulsing Center Locator Pin
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: activeSelectionColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF42C6D4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF42C6D4).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF42C6D4),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activeSelectionColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_rounded, color: activeSelectionColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.currentLang == 'en' ? 'Pick Up Address' : 'Alamat Penjemputan',
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoadingAddresses
                        ? (TranslationService.currentLang == 'en' ? 'Loading address...' : 'Memuat alamat...')
                        : address != null
                        ? '${address['alamat_lengkap']} (${address['tipe_alamat']}) - Penerima: ${address['nama_penerima']}'
                        : (TranslationService.currentLang == 'en' 
                            ? 'Address not set. Tap button to add.' 
                            : 'Alamat belum disetel. Ketuk tombol untuk menambahkan.'),
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _chooseAddress(false),
                    icon: Icon(
                      address != null ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                      size: 14,
                    ),
                    label: Text(
                      address != null 
                          ? (TranslationService.currentLang == 'en' ? 'Change Address' : 'Ubah Alamat')
                          : (TranslationService.currentLang == 'en' ? 'Add Address' : 'Tambah Alamat'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeSelectionColor,
                      side: BorderSide(color: activeSelectionColor.withOpacity(0.5), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelection(Color themeColor) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = selectedDateIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDateIndex = index;
                if (index == 0 && DateTime.now().hour >= 12) {
                  selectedTime = 'Afternoon';
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [activeSelectionColor, activeSelectionColor.withOpacity(0.8)],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                  width: isSelected ? 0 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? activeSelectionColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date['month']!,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date['date']!,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : navyColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date['day']!,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
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

  Widget _buildTimeSelection(Color themeColor) {
    return Row(
      children: [
        Expanded(child: _buildTimeOption('Morning', '08:00 - 12:00 am', themeColor)),
        const SizedBox(width: 12),
        Expanded(child: _buildTimeOption('Afternoon', '12:00 - 16:00 pm', themeColor)),
      ],
    );
  }

  Widget _buildTimeOption(String title, String time, Color themeColor) {
    final isSelected = selectedTime == title;
    final isMorning = title == 'Morning';
    final bool isToday = selectedDateIndex == 0;
    final bool isPastMidday = DateTime.now().hour >= 12;
    final bool isOptionDisabled = isToday && isPastMidday && isMorning;

    Color cardBgColor = Colors.white;
    Color borderCol = Colors.grey.shade200;
    double borderW = 1.0;

    if (isOptionDisabled) {
      cardBgColor = Colors.grey.shade50;
      borderCol = Colors.grey.shade300;
    } else if (isSelected) {
      cardBgColor = activeSelectionColor.withOpacity(0.04);
      borderCol = activeSelectionColor;
      borderW = 2.0;
    }

    return GestureDetector(
      onTap: isOptionDisabled
          ? null
          : () => setState(() => selectedTime = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderCol,
            width: borderW,
          ),
          boxShadow: isSelected && !isOptionDisabled
              ? [
                  BoxShadow(
                    color: activeSelectionColor.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOptionDisabled
                    ? Colors.grey.shade200
                    : (isSelected ? activeSelectionColor : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMorning ? Icons.wb_sunny_rounded : Icons.wb_twilight_rounded,
                color: isOptionDisabled
                    ? Colors.grey.shade500
                    : (isSelected ? Colors.white : Colors.grey.shade600),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.currentLang == 'en' ? title : (isMorning ? 'Pagi' : 'Siang'),
                    style: GoogleFonts.poppins(
                      color: isOptionDisabled ? Colors.grey.shade600 : navyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      color: isOptionDisabled ? Colors.grey.shade500 : textGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isOptionDisabled) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.grey.shade500,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpressBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5D5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B3B9C).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B3B9C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF6B3B9C),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationService.currentLang == 'en' ? 'Express / Fast Service' : 'Layanan Express / Kilat',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B3B9C),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  TranslationService.currentLang == 'en'
                      ? 'Select the Express or Kilat package above for super fast turnaround times.'
                      : 'Pilih paket Express atau Kilat di bagian atas untuk waktu pengerjaan yang super cepat.',
                  style: GoogleFonts.poppins(
                    color: textGrey,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    try {
      final perf = perfumes.firstWhere(
        (p) => p['name'] == selectedPerfume,
        orElse: () => perfumes.first,
      );
      final dateStr =
          dates[selectedDateIndex]['fullDate'] ??
          DateTime.now().toIso8601String().split('T')[0];

      final double basePrice = (widget.service['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;

      final orderData = {
        if (widget.selectedCustomer != null)
          'id_pelanggan': widget.selectedCustomer!['id_pelanggan'],
        'id_layanan': widget.service['id_layanan'],
        'id_paket_layanan': selectedPackageMap!['id_paket_layanan'],
        'id_alamat_pengambilan': selectedPickupAddress!['id_alamat'],
        'id_alamat_penyerahan': null,
        'id_parfum': perf['id'],
        'keterangan_lokasi': selectedPickupAddress!['tipe_alamat'] ?? 'Rumah',
        'jadwal_pickup': '$dateStr ${selectedTime == 'Morning' ? '08:00' : '13:00'}',
        'tipe_logistik': 'Courier Delivery',
        'harga_saat_ini': basePrice,
        'kuantitas': 0.0,
        'total_bayar': 0.0,
        'catatan_order': instructionController.text,
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
            content: Text(TranslationService.currentLang == 'en' 
                ? 'Failed to request pickup: $e' 
                : 'Gagal mengajukan penjemputan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Beautiful Checkmark Accent
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF2E7D32),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  TranslationService.currentLang == 'en'
                      ? 'Request Submitted Successfully!'
                      : 'Pengajuan Berhasil!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: navyColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  TranslationService.currentLang == 'en'
                      ? 'Wait for your order to be confirmed by our admin.'
                      : 'Mohon tunggu konfirmasi pesanan Anda dari admin kami.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.selectedCustomer != null) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainKaryawan(),
                          ),
                          (route) => false,
                        );
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainPelanggan(
                              showOrderSuccessNotification: true,
                            ),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Ok',
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
        );
      },
    );
  }

  Widget _buildReviewOrderButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9D58), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F9D58).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isPlacingOrder
            ? null
            : () {
                if (selectedPickupAddress == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(TranslationService.currentLang == 'en'
                          ? 'Please select pickup address first!'
                          : 'Silakan pilih alamat penjemputan terlebih dahulu!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (selectedPackageMap == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(TranslationService.currentLang == 'en'
                          ? 'Please select laundry package first!'
                          : 'Silakan pilih paket laundry terlebih dahulu!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                _placeOrder();
              },
        icon: _isPlacingOrder
            ? const SizedBox.shrink()
            : const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
        label: _isPlacingOrder
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  TranslationService.currentLang == 'en'
                      ? 'Request Pick Up'
                      : 'Ajukan Penjemputan',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final paintRoad = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintAccentRoad = Paint()
      ..color = const Color(0xFF42C6D4).withOpacity(0.4)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double j = 0; j < size.height; j += 20) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paintGrid);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.3, size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height)
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.2, size.height)
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.7);

    canvas.drawPath(path, paintRoad);

    final routePath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width, size.height * 0.8);
    canvas.drawPath(routePath, paintAccentRoad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
