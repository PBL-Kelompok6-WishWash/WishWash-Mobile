import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/pelanggan/home/tambah_alamat_screen.dart';
import 'package:mobile/services/alamat_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setPrimary(int idAlamat) async {
    try {
      final success = await AlamatService.setPrimaryAlamat(idAlamat);
      if (success && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengatur alamat utama: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              hintText: 'Cari lokasi',
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Alamat Saya',
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
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Icon(Icons.add_circle, color: navyColor, size: 18),
                      Text(
                        'Tambahkan Alamat Baru',
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
                  'Belum ada alamat tersimpan.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ..._alamatList.map((alamat) {
              return Column(
                children: [
                  InkWell(
                    onTap: () => _setPrimary(alamat['id_alamat']),
                    child: _buildSavedAddressItem(
                      alamat: alamat,
                      icon: alamat['tipe_alamat'] == 'Kantor' 
                          ? Icons.business_outlined 
                          : (alamat['tipe_alamat'] == 'Rumah' ? Icons.home_outlined : Icons.bookmark_border_rounded),
                      label: alamat['tipe_alamat'] ?? 'Rumah',
                      isPrimary: alamat['is_primary'] ?? false,
                      address: alamat['alamat_lengkap'] ?? '',
                      contact: '${alamat['nama_penerima'] ?? ''} | ${alamat['nohp_penerima'] ?? ''}',
                    ),
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
    return Padding(
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
                          color: cyanColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: cyanColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Terakhir Digunakan',
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
          // Edit Icon
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TambahAlamatScreen(alamatToEdit: alamat)),
              );
              if (result == true) {
                _fetchAlamat(); // Refresh list after edit
              }
            },
            alignment: Alignment.topRight,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
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
              'Saran Lokasi Terdekat',
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
                    'Belum ada saran lokasi terdekat.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saran lokasi akan muncul ketika Anda mengaktifkan GPS dan sering menggunakan aplikasi di area ini.',
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
