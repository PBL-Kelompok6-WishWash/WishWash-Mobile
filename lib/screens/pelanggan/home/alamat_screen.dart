import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/pelanggan/home/tambah_alamat_screen.dart';
import 'package:mobile/services/alamat_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/widgets/custom_dialog.dart';

class AlamatScreen extends StatefulWidget {
  const AlamatScreen({super.key});

  @override
  State<AlamatScreen> createState() => _AlamatScreenState();
}

class _AlamatScreenState extends State<AlamatScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgColor = const Color(0xFFF8FBFC);

  List<dynamic> _alamatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlamat();
  }

  Future<void> _fetchAlamat() async {
    setState(() => _isLoading = true);
    try {
      final alamats = await AlamatService.getAlamat();
      setState(() {
        _alamatList = alamats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        CustomDialog.showError(
          context: context,
          title: 'Error',
          message: e.toString(),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setPrimary(int idAlamat) async {
    try {
      final success = await AlamatService.setPrimaryAlamat(idAlamat);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showError(
          context: context,
          title: 'Gagal',
          message: 'Gagal mengatur alamat utama: $e',
        );
      }
    }
  }

  Future<void> _deleteAlamat(int idAlamat) async {
    final confirm = await CustomDialog.showConfirm(
      context: context,
      title: 'Hapus Alamat',
      message: 'Apakah Anda yakin ingin menghapus alamat ini dari daftar?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await AlamatService.deleteAlamat(idAlamat);
      if (success && mounted) {
        CustomDialog.showSuccess(
          context: context,
          title: 'Hapus Berhasil',
          message: 'Alamat Anda telah berhasil dihapus dari sistem.',
        );
        _fetchAlamat();
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showError(
          context: context,
          title: 'Gagal Menghapus',
          message: e.toString(),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Container(
              height: 42,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: TextField(
                style: GoogleFonts.poppins(fontSize: 14, color: navyColor),
                decoration: InputDecoration(
                  hintText: TranslationService.translate('search_location'),
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.map_outlined, color: cyanColor, size: 26),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cyanColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildMyAddressSection(context),
                  const SizedBox(height: 16),
                  _buildSuggestedLocationsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  },
);
  }

  Widget _buildMyAddressSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslationService.translate('my_address'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TambahAlamatScreen()),
                    );
                    if (result == true) {
                      _fetchAlamat(); // Refresh list jika berhasil nambah
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle, color: navyColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        TranslationService.translate('add_new_address'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
          if (_alamatList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  TranslationService.translate('no_saved_addresses'),
                  style: GoogleFonts.poppins(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ..._alamatList.map((alamat) {
              final String tipe = alamat['tipe_alamat'] ?? 'Rumah';
              String displayLabel = tipe;
              if (tipe == 'Rumah') {
                displayLabel = TranslationService.translate('home_tag');
              } else if (tipe == 'Kantor') {
                displayLabel = TranslationService.translate('office_tag');
              } else if (tipe == 'Lainnya') {
                displayLabel = TranslationService.translate('other_tag');
              }

              return Column(
                children: [
                  _buildSavedAddressItem(
                    alamat: alamat,
                    icon: tipe == 'Kantor' 
                        ? Icons.business_outlined 
                        : (tipe == 'Rumah' ? Icons.home_outlined : Icons.bookmark_border_rounded),
                    label: displayLabel,
                    isPrimary: alamat['is_primary'] ?? false,
                    address: alamat['alamat_lengkap'] ?? '',
                    contact: '${alamat['nama_penerima'] ?? ''} | ${alamat['nohp_penerima'] ?? ''}',
                  ),
                  Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSavedAddressItem({
    required Map<String, dynamic> alamat,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required String address,
    required String contact,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setPrimary(alamat['id_alamat']),
        splashColor: cyanColor.withOpacity(0.12),
        highlightColor: cyanColor.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Icon(icon, color: navyColor, size: 24),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Address Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: navyColor,
                          ),
                        ),
                        if (isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cyanColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: cyanColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              TranslationService.translate('last_used'),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cyanColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contact,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
                      splashColor: cyanColor.withOpacity(0.2),
                      highlightColor: cyanColor.withOpacity(0.1),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TambahAlamatScreen(alamatToEdit: alamat)),
                        );
                        if (result == true) {
                          _fetchAlamat(); // Refresh list after edit
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      splashColor: Colors.redAccent.withOpacity(0.2),
                      highlightColor: Colors.redAccent.withOpacity(0.1),
                      onPressed: () => _deleteAlamat(alamat['id_alamat']),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedLocationsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              TranslationService.translate('suggested_locations'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: navyColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.location_disabled_rounded, color: Colors.grey.shade300, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    TranslationService.translate('no_suggested_locations'),
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TranslationService.translate('suggested_locations_desc'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
