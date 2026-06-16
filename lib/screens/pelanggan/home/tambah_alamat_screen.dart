import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/alamat_service.dart';
import 'package:mobile/screens/pelanggan/home/pilih_alamat_screen.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/widgets/custom_dialog.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;


class TambahAlamatScreen extends StatefulWidget {
  final Map<String, dynamic>? alamatToEdit;

  const TambahAlamatScreen({super.key, this.alamatToEdit});

  @override
  State<TambahAlamatScreen> createState() => _TambahAlamatScreenState();
}

class _TambahAlamatScreenState extends State<TambahAlamatScreen> {
  final Color _navyColor = const Color(0xFF0C4B8E);
  final Color _cyanColor = const Color(0xFF42C6D4);
  final Color _bgColor = const Color(0xFFF8FBFC);

  String _selectedLabel = 'Rumah';
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customLabelController = TextEditingController();
  bool _isLoading = false;
  
  String? _latitude;
  String? _longitude;
  String? _selectedMapAddress;

  bool get _isEditMode => widget.alamatToEdit != null && widget.alamatToEdit!['id_alamat'] != null;

  @override
  void initState() {
    super.initState();
    if (widget.alamatToEdit != null) {
      final a = widget.alamatToEdit!;
      final tipe = a['tipe_alamat'] ?? 'Rumah';
      if (tipe == 'Rumah' || tipe == 'Kantor') {
        _selectedLabel = tipe;
      } else {
        _selectedLabel = 'Lainnya';
        _customLabelController.text = tipe;
      }
      
      final String full = a['alamat_lengkap'] ?? '';
      
      // Parse composite address string to separate map address from custom details note
      if (full.contains('(') && full.endsWith(')')) {
        final idx = full.indexOf('(');
        _selectedMapAddress = full.substring(0, idx).trim();
        _detailController.text = full.substring(idx + 1, full.length - 1).trim();
      } else {
        _selectedMapAddress = full;
        _detailController.text = '';
      }
      
      _nameController.text = a['nama_penerima'] ?? '';
      _phoneController.text = a['nohp_penerima'] ?? '';
      _latitude = a['latitude'];
      _longitude = a['longitude'];
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PilihAlamatScreen()),
    );
    if (result != null && result is Map) {
      setState(() {
        _selectedMapAddress = result['alamat'];
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        final isEn = TranslationService.currentLang == 'en';
        
        return Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: _navyColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _isEditMode 
                ? TranslationService.translate('edit_address') 
                : TranslationService.translate('add_new_address'),
              style: GoogleFonts.poppins(
                color: _navyColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // 1. Premium Shopee-style Address Picker Card & Mini-Map Preview
                if (_selectedMapAddress == null) ...[
                  // Original clean "Pilih Alamat" button
                  InkWell(
                    onTap: _openMapPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: _cyanColor, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              TranslationService.translate('select_address'),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _navyColor,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Gorgeous Shopee-style Map Card Container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_latitude != null && _longitude != null) ...[
                          // Mini Map Preview (OSM Tile Engine with centered static pin)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: SizedBox(
                              height: 140,
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(
                                        double.parse(_latitude!),
                                        double.parse(_longitude!),
                                      ),
                                      initialZoom: 15.0,
                                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Disable dragging on mini map
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                        subdomains: const ['a', 'b', 'c', 'd'],
                                      ),
                                    ],
                                  ),
                                  // Clickable map gesture layer
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _openMapPicker,
                                      ),
                                    ),
                                  ),
                                  // Pin Marker sitting geographically centered on the mini-map
                                  Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 20.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                          ],
                                        ),
                                        child: Icon(Icons.location_on, color: _cyanColor, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        // Clickable Address Card Info Section
                        InkWell(
                          onTap: _openMapPicker,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _cyanColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.location_on_rounded, color: _cyanColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedMapAddress!.contains(',')
                                            ? _selectedMapAddress!.split(',').first
                                            : _selectedMapAddress!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _navyColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _selectedMapAddress!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),

                // 2. Comprehensive Details Note & Recipient Form Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: TranslationService.translate('address_details'),
                        hint: TranslationService.translate('address_details_hint'),
                        controller: _detailController,
                        maxLines: 2,
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: const Color(0xFFFFF9E6), // Light yellow warning tint
                        child: Text(
                          TranslationService.translate('address_helper_text'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Divider(color: Colors.grey.shade200, height: 1),
                      _buildTextField(
                        label: TranslationService.translate('recipient_name'),
                        hint: TranslationService.translate('recipient_name_hint'),
                        controller: _nameController,
                        isRequired: false,
                      ),
                      Divider(color: Colors.grey.shade200, height: 1),
                      _buildTextField(
                        label: TranslationService.translate('phone_number'),
                        hint: isEn ? 'Example: 081234567890' : 'Contoh: 081234567890',
                        controller: _phoneController,
                        isRequired: false,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // 3. Location Label Tag Chip Selection (Rumah / Kantor / Lainnya)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.translate('tag_as'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildLabelChip('Rumah', Icons.home_outlined),
                          _buildLabelChip('Kantor', Icons.business_outlined),
                          _buildLabelChip('Lainnya', Icons.bookmark_border_rounded),
                        ],
                      ),
                      if (_selectedLabel == 'Lainnya') ...[
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade200, height: 1),
                        _buildTextField(
                          label: TranslationService.translate('tag_as'),
                          hint: TranslationService.translate('custom_tag_hint'),
                          controller: _customLabelController,
                          isRequired: true,
                          horizontalPadding: 0,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
          
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_selectedMapAddress == null || (_selectedLabel == 'Lainnya' && _customLabelController.text.isEmpty)) {
                          CustomDialog.showError(
                            context: context,
                            title: isEn ? 'Incomplete Form' : 'Formulir Belum Lengkap',
                            message: isEn ? 'Please pin your location on the map.' : 'Harap tandai lokasi peta Anda.',
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        try {
                          String finalName = _nameController.text.trim();
                          String finalPhone = _phoneController.text.trim();

                          // If recipient name or phone number is empty, automatically fill from account profile
                          if (finalName.isEmpty || finalPhone.isEmpty) {
                            final profileRes = await PelangganService.getProfile();
                            if (profileRes['success'] == true) {
                              final pData = profileRes['data']?['pelanggan'] ?? {};
                              if (finalName.isEmpty) {
                                finalName = pData['nama_lengkap'] ?? '';
                              }
                              if (finalPhone.isEmpty) {
                                finalPhone = pData['no_telp'] ?? '';
                              }
                            }
                          }

                          // If still empty as a hard fallback
                          if (finalName.isEmpty) {
                            finalName = 'User';
                          }
                          if (finalPhone.isEmpty) {
                            finalPhone = '-';
                          }

                          // Combine the selected street address with the user's detailed notes (House No, Patokan) dynamically
                          final String compositeAddress = _detailController.text.trim().isNotEmpty
                              ? '$_selectedMapAddress (${_detailController.text.trim()})'
                              : _selectedMapAddress!;

                          final data = {
                            'alamat_lengkap': compositeAddress,
                            'nama_penerima': finalName,
                            'nohp_penerima': finalPhone,
                            'tipe_alamat': _selectedLabel == 'Lainnya' ? _customLabelController.text : _selectedLabel,
                            'latitude': _latitude ?? '-6.1753924',
                            'longitude': _longitude ?? '106.8271528',
                          };

                          if (_isEditMode) {
                            await AlamatService.updateAlamat(widget.alamatToEdit!['id_alamat'], data);
                          } else {
                            await AlamatService.createAlamat(data);
                          }
                          
                          if (context.mounted) {
                            CustomDialog.showSuccess(
                              context: context,
                              title: _isEditMode
                                  ? (isEn ? 'Updated Successfully' : 'Berhasil Diubah')
                                  : (isEn ? 'Saved Successfully' : 'Berhasil Disimpan'),
                              message: _isEditMode 
                                  ? TranslationService.translate('address_updated') 
                                  : TranslationService.translate('address_added'),
                            ).then((_) {
                              if (mounted) Navigator.pop(context, true);
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            CustomDialog.showError(
                              context: context,
                              title: _isEditMode
                                  ? (isEn ? 'Update Failed' : 'Gagal Mengubah')
                                  : (isEn ? 'Save Failed' : 'Simpan Gagal'),
                              message: e.toString(),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navyColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      TranslationService.translate('save_address'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    double horizontalPadding = 16,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(
                text: label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _navyColor,
                ),
                children: [
                  if (isRequired)
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                ],
              ),
            ),
          ),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _navyColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChip(String value, IconData icon) {
    final bool isSelected = _selectedLabel == value;
    String displayLabel = value;
    if (value == 'Rumah') displayLabel = TranslationService.translate('home_tag');
    else if (value == 'Kantor') displayLabel = TranslationService.translate('office_tag');
    else if (value == 'Lainnya') displayLabel = TranslationService.translate('other_tag');

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLabel = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _navyColor : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? _navyColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
