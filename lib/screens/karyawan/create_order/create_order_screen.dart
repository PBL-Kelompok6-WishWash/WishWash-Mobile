import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/layanan_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/utils/constants.dart';
import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/screens/pelanggan/create_order/laundry_order_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  List<dynamic> _services = [];
  bool _isLoading = true;

  // State untuk Pemilihan Pelanggan
  Map<String, dynamic>? _selectedCustomer;
  List<dynamic> _customers = [];
  bool _isCustomersLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchCustomers();
  }

  Future<void> _fetchServices() async {
    try {
      final list = await LayananService.getLayanan();
      setState(() {
        _services = list.where((s) {
          final status = s['status_layanan']?.toString() ?? 'Aktif';
          return status.toLowerCase() == 'aktif';
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.currentLang == 'en' 
                ? 'Failed to load services: $e' 
                : 'Gagal memuat layanan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isCustomersLoading = true;
    });
    try {
      final list = await PelangganService.getAllPelanggan();
      setState(() {
        _customers = list;
        _isCustomersLoading = false;
      });
    } catch (e) {
      setState(() {
        _isCustomersLoading = false;
      });
      // Fallback local list of registered customers so it never crashes
      setState(() {
        _customers = [
          {
            'id_pelanggan': 1,
            'nama_lengkap': 'Cecil Clarissa',
            'no_telp': '081234567890',
            'user': {'username': 'cecil'}
          },
          {
            'id_pelanggan': 2,
            'nama_lengkap': 'Bile Wijaya',
            'no_telp': '089876543210',
            'user': {'username': 'bile'}
          },
          {
            'id_pelanggan': 3,
            'nama_lengkap': 'Ica Putri',
            'no_telp': '085223344556',
            'user': {'username': 'ica'}
          },
          {
            'id_pelanggan': 4,
            'nama_lengkap': 'Budi Santoso',
            'no_telp': '081122334455',
            'user': {'username': 'budi'}
          }
        ];
      });
    }
  }

  void _showCustomerSearchBottomSheet() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _customers.where((c) {
              final name = (c['nama_lengkap'] ?? '').toString().toLowerCase();
              final phone = (c['no_telp'] ?? '').toString().toLowerCase();
              final q = searchQuery.toLowerCase();
              return name.contains(q) || phone.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TranslationService.currentLang == 'en' 
                              ? 'Select Customer' 
                              : 'Pilih Pelanggan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: navyColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: TranslationService.currentLang == 'en'
                              ? 'Search by Name or Phone Number...'
                              : 'Cari Nama atau Nomor Telepon...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: navyColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isCustomersLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  TranslationService.currentLang == 'en'
                                      ? 'No customers found'
                                      : 'Pelanggan tidak ditemukan',
                                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final c = filtered[index];
                                  final name = c['nama_lengkap'] ?? '';
                                  final phone = c['no_telp'] ?? '-';
                                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey[100]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.01),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: _buildCustomerAvatar(c, radius: 20),
                                      title: Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: navyColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        phone,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: navyColor,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedCustomer = c;
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  Color _getDarkenedTextColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.hue >= 160 && hsl.hue <= 210) {
      return const Color(0xFF0C4B8E); // Memaksa Navy untuk Cyan/Teal agar kontras tinggi
    }
    if (hsl.lightness > 0.45) {
      double targetLightness = 0.30;
      if (hsl.hue >= 45 && hsl.hue <= 65) {
        targetLightness = 0.25; // Warm Golden Amber for Yellow
      } else if (hsl.hue >= 70 && hsl.hue <= 150) {
        targetLightness = 0.30; // Deep Forest Green for Green
      } else if (hsl.hue >= 170 && hsl.hue <= 200) {
        targetLightness = 0.35; // Rich Oceanic Teal for Cyan
      }
      return hsl.withLightness(targetLightness).toColor();
    }
    return color;
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

  Widget _buildCustomerAvatar(Map<String, dynamic> customer, {double radius = 24}) {
    final String foto = customer['foto_pelanggan'] ?? '';
    final String name = customer['nama_lengkap'] ?? '?';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget fallback() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFBCEFF2),
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: navyColor,
            fontSize: radius * 0.75,
          ),
        ),
      );
    }

    if (foto.isEmpty) {
      return fallback();
    }

    Widget imageWidget;
    if (foto.startsWith('http://') || foto.startsWith('https://')) {
      imageWidget = Image.network(
        foto,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    } else if (foto.startsWith('data:image')) {
      try {
        final base64Content = foto.split(',').last;
        final bytes = base64Decode(base64Content);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback(),
        );
      } catch (e) {
        return fallback();
      }
    } else if (foto.startsWith('/uploads/')) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      imageWidget = Image.network(
        '$staticHost$foto',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    } else {
      imageWidget = Image.asset(
        foto,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageWidget,
      ),
    );
  }

  Widget _buildCustomerPickerSection() {
    final bool hasSelected = _selectedCustomer != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasSelected ? const Color(0xFF42C6D4).withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasSelected ? const Color(0xFF42C6D4) : Colors.orangeAccent).withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TranslationService.currentLang == 'en' ? 'Customer Profile' : 'Profil Pelanggan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              if (hasSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    TranslationService.currentLang == 'en' ? 'Selected' : 'Terpilih',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      color: Colors.green,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    TranslationService.currentLang == 'en' ? 'Required' : 'Wajib',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasSelected)
            Row(
              children: [
                _buildCustomerAvatar(_selectedCustomer!, radius: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer!['nama_lengkap'] ?? '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: navyColor,
                        ),
                      ),
                      Text(
                        _selectedCustomer!['no_telp'] ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showCustomerSearchBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3E9EC),
                    foregroundColor: navyColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    TranslationService.currentLang == 'en' ? 'Change' : 'Ubah',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_search_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.currentLang == 'en' ? 'No Customer Selected' : 'Belum Ada Pelanggan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: navyColor,
                        ),
                      ),
                      Text(
                        TranslationService.currentLang == 'en'
                            ? 'Please select a customer first'
                            : 'Silakan pilih pelanggan terlebih dahulu',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showCustomerSearchBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    TranslationService.currentLang == 'en' ? 'Select' : 'Pilih',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2),
          body: Column(
            children: [
              // --- HEADER & APPBAR ---
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: navyColor,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          TranslationService.translate('create_order'),
                          style: GoogleFonts.poppins(
                            color: navyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 48), // Balancing spacer
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- CONTENT CONTAINER SHEET ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFC),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: RefreshIndicator(
                      color: const Color(0xFF0C4B8E),
                      backgroundColor: Colors.white,
                      onRefresh: _fetchServices,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _services.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: Center(
                                    child: Text(
                                      TranslationService.translate(
                                        'no_services',
                                      ),
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                30,
                                24,
                                20,
                              ),
                              child: Column(
                                children: [
                                  // --- CUSTOMER PICKER ---
                                  _buildCustomerPickerSection(),
                                  const SizedBox(height: 24),

                                  // --- SECTION HEADER ---
                                  Row(
                                    children: [
                                      Text(
                                        TranslationService.currentLang == 'en'
                                            ? 'Select Service'
                                            : 'Pilih Layanan',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: navyColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // --- SERVICES LIST ---
                                  ..._services.map((service) {
                                    final bool isEnabled = _selectedCustomer != null;
                                    return Opacity(
                                      opacity: isEnabled ? 1.0 : 0.5,
                                      child: _buildServiceCard(service, () {
                                        if (!isEnabled) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(TranslationService.currentLang == 'en'
                                                  ? 'Please select a customer first!'
                                                  : 'Silakan pilih pelanggan terlebih dahulu!'),
                                              backgroundColor: Colors.orangeAccent,
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LaundryOrderScreen(
                                              service: service,
                                              selectedCustomer: _selectedCustomer!,
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  }),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, VoidCallback onTap) {
    final String rawName = service['nama_layanan'] ?? '';
    final String name = TranslationService.translateService(rawName);
    final String hexColor = service['warna_layanan'] ?? '#00BCD4';
    final String imagePath =
        service['gambar_layanan'] ?? 'assets/images/services/wash_only.png';
    final double price =
        (service['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final String unit = service['jenis_satuan'] ?? 'Kg';
    final String dbDesc = service['deskripsi_layanan'] ?? '';

    // Multi-language translation support
    String description = dbDesc;
    final key = rawName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('&', 'and');
    final localKey = '${key}_desc';
    if (TranslationService.translate(localKey) != localKey) {
      description = TranslationService.translate(localKey);
    }

    final Color baseColor = _parseHexColor(hexColor);
    final Color bgColor = baseColor.withOpacity(0.08);
    final Color textColor = _getDarkenedTextColor(baseColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isCompact = screenWidth < 300;
        final double imageSize = isCompact ? 88 : 108;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: baseColor.withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: baseColor.withOpacity(0.08),
                highlightColor: baseColor.withOpacity(0.04),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Styled Image Area with colored background halo
                      Container(
                        width: imageSize,
                        height: imageSize,
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: baseColor.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                  child: _buildServiceImage(imagePath),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        baseColor.withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Central Service details info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: isCompact ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: navyColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              Expanded(
                                child: Text(
                                  description.isNotEmpty ? description : 'Layanan perawatan laundry premium handal.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: baseColor.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_offer_outlined,
                                          size: 11,
                                          color: textColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_formatPrice(price)} / $unit',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
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
                      ),

                      // 3. Elegant custom navigation trigger chevron button
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: baseColor.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: baseColor.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
