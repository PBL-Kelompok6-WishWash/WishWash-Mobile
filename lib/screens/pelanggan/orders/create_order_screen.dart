import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/layanan_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'laundry_order_screen.dart';
import 'package:mobile/utils/constants.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
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
            content: Text('Gagal memuat layanan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
                    horizontal: 10,
                    vertical: 10,
                  ),
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
                                children: _services.map((service) {
                                  return _buildServiceCard(service, () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LaundryOrderScreen(
                                              service: service,
                                            ),
                                      ),
                                    );
                                  });
                                }).toList(),
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
        // Adjust elements dynamically for smaller screens
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
                              // Smooth artistic dark/light gradient overlay
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
                              
                              // Middle description
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
                              
                              // Bottom price pill with custom tag icon
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
