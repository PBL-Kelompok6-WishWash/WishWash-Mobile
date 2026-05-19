import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/layanan_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'wash_ironing.dart';
import 'wash_only.dart';
import 'ironing_only.dart';
import 'dry_clean.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final Color navyColor = const Color(0xFF0F2F53);
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
        _services = list;
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
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();
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
          backgroundColor: const Color(0xFFF8FBFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F2F53), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              TranslationService.translate('create_order'),
              style: GoogleFonts.poppins(
                color: navyColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _services.isEmpty
              ? Center(
                  child: Text(
                    TranslationService.translate('no_services'),
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _services.map((service) {
                      final String name = service['nama_layanan'] ?? '';
                      return _buildServiceCard(service, () {
                        final String lowerName = name.toLowerCase();
                        if (lowerName.contains('ironing') && lowerName.contains('wash')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WashIroningScreen()),
                          );
                        } else if (lowerName.contains('wash')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WashOnlyScreen()),
                          );
                        } else if (lowerName.contains('ironing')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const IroningOnlyScreen()),
                          );
                        } else if (lowerName.contains('dry') || lowerName.contains('clean')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DryCleanScreen()),
                          );
                        }
                      });
                    }).toList(),
                  ),
                ),
    );
  },
);
  }

  Widget _buildServiceCard(
    Map<String, dynamic> service,
    VoidCallback onTap,
  ) {
    final String name = service['nama_layanan'] ?? '';
    final String hexColor = service['warna_layanan'] ?? '#00BCD4';
    final String imagePath = service['gambar_layanan'] ?? 'assets/images/services/wash_only.png';
    final double price = (service['harga_per_satuan'] as num?)?.toDouble() ?? 0.0;
    final String unit = service['jenis_satuan'] ?? 'Kg';

    final Color baseColor = _parseHexColor(hexColor);
    final Color bgColor = baseColor.withOpacity(0.12);
    final Color textColor = _getDarkenedTextColor(baseColor);

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                // Image on left with fade shader
                SizedBox(
                  width: 120,
                  height: double.infinity,
                  child: Container(
                    color: bgColor,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.black, Colors.transparent],
                        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                      },
                      blendMode: BlendMode.dstIn,
                      child: _buildServiceImage(imagePath),
                    ),
                  ),
                ),
                // Text details in center
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatPrice(price)} / $unit',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Chevron icon on right
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
