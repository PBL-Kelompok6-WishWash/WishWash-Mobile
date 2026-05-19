import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/alamat_service.dart';
import 'package:mobile/screens/pelanggan/home/pilih_alamat_screen.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/widgets/custom_dialog.dart';

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
      _detailController.text = a['alamat_lengkap'] ?? '';
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
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
              widget.alamatToEdit != null 
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
                // Pilih Alamat Button
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PilihAlamatScreen()),
                    );
                    if (result != null && result is Map) {
                      setState(() {
                        _detailController.text = result['alamat'];
                        _latitude = result['latitude'];
                        _longitude = result['longitude'];
                      });
                    }
                  },
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
            const SizedBox(height: 24),

            // Form Container
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
                    color: const Color(0xFFFFF9E6), // Light yellow tint
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
                    isRequired: true,
                  ),
                  Divider(color: Colors.grey.shade200, height: 1),
                  _buildTextField(
                    label: TranslationService.translate('phone_number'),
                    hint: 'Contoh: 081234567890',
                    controller: _phoneController,
                    isRequired: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tandai Sebagai
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
            const SizedBox(height: 40),
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
                    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _detailController.text.isEmpty || (_selectedLabel == 'Lainnya' && _customLabelController.text.isEmpty)) {
                      CustomDialog.showError(
                        context: context,
                        title: 'Formulir Belum Lengkap',
                        message: TranslationService.translate('fill_all_fields'),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    try {
                      final data = {
                        'alamat_lengkap': _detailController.text,
                        'nama_penerima': _nameController.text,
                        'nohp_penerima': _phoneController.text,
                        'tipe_alamat': _selectedLabel == 'Lainnya' ? _customLabelController.text : _selectedLabel,
                        'latitude': _latitude ?? '-7.3305',
                        'longitude': _longitude ?? '110.5084',
                      };

                      if (widget.alamatToEdit != null) {
                        await AlamatService.updateAlamat(widget.alamatToEdit!['id_alamat'], data);
                      } else {
                        await AlamatService.createAlamat(data);
                      }
                      
                      if (context.mounted) {
                        CustomDialog.showSuccess(
                          context: context,
                          title: 'Berhasil Disimpan',
                          message: widget.alamatToEdit != null 
                              ? TranslationService.translate('address_updated') 
                              : TranslationService.translate('address_added'),
                        ).then((_) {
                          if (mounted) Navigator.pop(context, true); // return true to indicate success
                        });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        CustomDialog.showError(
                          context: context,
                          title: 'Simpan Gagal',
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
