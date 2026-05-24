import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:mobile/screens/karyawan/orders/order_detail_screen.dart';

class OrderScreenKaryawan extends StatefulWidget {
  const OrderScreenKaryawan({super.key});

  @override
  State<OrderScreenKaryawan> createState() => _OrderScreenKaryawanState();
}

class _OrderScreenKaryawanState extends State<OrderScreenKaryawan> {
  int _activeTabIndex = 0; // 0: Semua, 1: Logistik, 2: Outlet, 3: Selesai
  int _activeLogistikSubIndex = 0; // 0: Semua, 1: Pickup, 2: Delivery
  int _activeOutletSubIndex = 0; // 0: Semua, 1: Timbang, 2: Cuci & Kering, 3: Lipat & Setrika
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgGrey = const Color(0xFFF8FBFC);
  final Color softTeal = const Color(0xFFBCEFF2);

  // High-fidelity Mock Orders berstruktur persis seperti database/JSON API riil
  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id_order': 1,
      'kode_order': 'WW-H78F2',
      'tgl_pesanan': '2026-05-24T08:15:00Z',
      'jadwal_pickup': '2026-05-25T08:00:00Z',
      'kuantitas': 4.5,
      'total_bayar': 48000.0,
      'catatan_order': 'Tolong dipisah pakaian putih dengan yang berwarna ya.',
      'tipe_logistik': 'Courier Delivery',
      'Layanan': {
        'nama_layanan': 'Cuci & Setrika',
        'harga_per_satuan': 8000.0,
      },
      'PaketLayanan': {
        'nama_paket': 'Express',
        'biaya_tambahan': 12000.0,
        'durasi_jam': 24,
      },
      'Pelanggan': {
        'nama_lengkap': 'Cecil Clarissa',
        'no_hp': '081234567890',
        'foto_profil': '',
      },
      'AlamatPengambilan': {
        'alamat_lengkap': 'Kost Mulawarman No. 24, Tembalang, Semarang',
      },
      'AlamatPenyerahan': {
        'alamat_lengkap': 'Kost Mulawarman No. 24, Tembalang, Semarang',
      },
      'Parfum': {
        'nama_parfum': 'Lavender Bliss',
      },
      'Pembayaran': {
        'status_pembayaran': 'Lunas',
      },
      'status_operasional': 'proses cuci', // 'pesanan diterima', 'penjemputan', 'proses timbang', 'proses cuci', 'proses kering', 'proses lipat', 'proses setrika', 'siap diantar', 'selesai'
    },
    {
      'id_order': 2,
      'kode_order': 'WW-K92B1',
      'tgl_pesanan': '2026-05-24T09:30:00Z',
      'jadwal_pickup': '2026-05-24T13:00:00Z',
      'kuantitas': 0.0, // Belum ditimbang
      'total_bayar': 0.0,
      'catatan_order': 'Pakaian kerja disetrika extra rapi.',
      'tipe_logistik': 'Courier Delivery',
      'Layanan': {
        'nama_layanan': 'Setrika Saja',
        'harga_per_satuan': 5000.0,
      },
      'PaketLayanan': {
        'nama_paket': 'Reguler',
        'biaya_tambahan': 0.0,
        'durasi_jam': 72,
      },
      'Pelanggan': {
        'nama_lengkap': 'Abilah Budi',
        'no_hp': '089876543210',
        'foto_profil': '',
      },
      'AlamatPengambilan': {
        'alamat_lengkap': 'Perumahan Gondang Indah Blok C-12, Tembalang',
      },
      'AlamatPenyerahan': {
        'alamat_lengkap': 'Perumahan Gondang Indah Blok C-12, Tembalang',
      },
      'Parfum': {
        'nama_parfum': 'Ocean Breeze',
      },
      'Pembayaran': {
        'status_pembayaran': 'Belum Lunas',
      },
      'status_operasional': 'penjemputan',
    },
    {
      'id_order': 3,
      'kode_order': 'WW-T33G4',
      'tgl_pesanan': '2026-05-23T14:00:00Z',
      'jadwal_pickup': '2026-05-23T15:00:00Z',
      'kuantitas': 3.0,
      'total_bayar': 24000.0,
      'catatan_order': '',
      'tipe_logistik': 'Self Pickup',
      'Layanan': {
        'nama_layanan': 'Cuci Kering Lipat',
        'harga_per_satuan': 6000.0,
      },
      'PaketLayanan': {
        'nama_paket': 'Reguler',
        'biaya_tambahan': 6000.0,
        'durasi_jam': 48,
      },
      'Pelanggan': {
        'nama_lengkap': 'Clarissa Ica',
        'no_hp': '082345678901',
        'foto_profil': '',
      },
      'AlamatPengambilan': {
        'alamat_lengkap': 'Apartemen Altiz Tembalang Tower B Lt. 10 No. 5',
      },
      'AlamatPenyerahan': {
        'alamat_lengkap': 'Apartemen Altiz Tembalang Tower B Lt. 10 No. 5',
      },
      'Parfum': {
        'nama_parfum': 'Sakura Garden',
      },
      'Pembayaran': {
        'status_pembayaran': 'Belum Lunas',
      },
      'status_operasional': 'siap diantar',
    },
    {
      'id_order': 4,
      'kode_order': 'WW-P11A9',
      'tgl_pesanan': '2026-05-22T10:00:00Z',
      'jadwal_pickup': '2026-05-22T11:00:00Z',
      'kuantitas': 5.0,
      'total_bayar': 40000.0,
      'catatan_order': 'Jangan pakai pewangi Lavender ya alergi.',
      'tipe_logistik': 'Courier Delivery',
      'Layanan': {
        'nama_layanan': 'Cuci Kering Lipat',
        'harga_per_satuan': 6000.0,
      },
      'PaketLayanan': {
        'nama_paket': 'Express',
        'biaya_tambahan': 10000.0,
        'durasi_jam': 24,
      },
      'Pelanggan': {
        'nama_lengkap': 'Devi Ajeng',
        'no_hp': '085678901234',
        'foto_profil': '',
      },
      'AlamatPengambilan': {
        'alamat_lengkap': 'Kost Banyumanik Asri No. 5A, Semarang',
      },
      'AlamatPenyerahan': {
        'alamat_lengkap': 'Kost Banyumanik Asri No. 5A, Semarang',
      },
      'Parfum': {
        'nama_parfum': 'Vanilla Dream',
      },
      'Pembayaran': {
        'status_pembayaran': 'Lunas',
      },
      'status_operasional': 'selesai',
    },
    {
      'id_order': 5,
      'kode_order': 'WW-S09R4',
      'tgl_pesanan': '2026-05-24T11:45:00Z',
      'jadwal_pickup': '2026-05-24T12:30:00Z',
      'kuantitas': 2.0,
      'total_bayar': 15000.0,
      'catatan_order': '',
      'tipe_logistik': 'Courier Delivery',
      'Layanan': {
        'nama_layanan': 'Setrika Saja',
        'harga_per_satuan': 5000.0,
      },
      'PaketLayanan': {
        'nama_paket': 'Express',
        'biaya_tambahan': 5000.0,
        'durasi_jam': 24,
      },
      'Pelanggan': {
        'nama_lengkap': 'Anindya R',
        'no_hp': '087890123456',
        'foto_profil': '',
      },
      'AlamatPengambilan': {
        'alamat_lengkap': 'Jl. Sirojudin No. 8, Tembalang, Semarang',
      },
      'AlamatPenyerahan': {
        'alamat_lengkap': 'Jl. Sirojudin No. 8, Tembalang, Semarang',
      },
      'Parfum': {
        'nama_parfum': 'Lavender Bliss',
      },
      'Pembayaran': {
        'status_pembayaran': 'Lunas',
      },
      'status_operasional': 'proses kering',
    },
    {
      'id_order': 6,
      'kode_order': 'WW-Z12V7',
      'tgl_pesanan': '2026-05-24T07:15:00Z',
      'jadwal_pickup': '2026-05-24T08:00:00Z',
      'kuantitas': 3.5,
      'total_bayar': 21000.0,
      'catatan_order': '',
      'tipe_logistik': 'Self Pickup',
      'Layanan': {
        'nama_layanan': 'Cuci Kering Saja',
        'harga_per_satuan': 6000.0,
      },
      'PaketLayanan': {
        'nama_paket': 'Reguler',
        'biaya_tambahan': 0.0,
        'durasi_jam': 48,
      },
      'Pelanggan': {
        'nama_lengkap': 'Mark Lee',
        'no_hp': '089882113344',
        'foto_profil': '',
      },
      'AlamatPengambilan': {
        'alamat_lengkap': 'Perumahan Tembalang Pesona Blok D-9, Semarang',
      },
      'AlamatPenyerahan': {
        'alamat_lengkap': 'Perumahan Tembalang Pesona Blok D-9, Semarang',
      },
      'Parfum': {
        'nama_parfum': 'Ocean Breeze',
      },
      'Pembayaran': {
        'status_pembayaran': 'Lunas',
      },
      'status_operasional': 'proses timbang',
    }
  ];

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoString.split('T')[0];
    }
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pesanan diterima':
        return Colors.blue.shade700;
      case 'penjemputan':
        return const Color(0xFFFBC02D); // Amber
      case 'proses timbang':
        return Colors.cyan.shade700;
      case 'proses cuci':
      case 'proses kering':
      case 'proses lipat':
      case 'proses setrika':
        return const Color(0xFF9C27B0); // Purple
      case 'siap diantar':
        return const Color(0xFF0288D1); // Light Blue
      case 'selesai':
        return const Color(0xFF2E7D32); // Green
      default:
        return Colors.grey;
    }
  }

  bool _isOutletOrder(String status) {
    final s = status.toLowerCase();
    return s == 'pesanan diterima' ||
        s == 'proses timbang' ||
        s == 'proses cuci' ||
        s == 'proses kering' ||
        s == 'proses lipat' ||
        s == 'proses setrika';
  }

  bool _isLogistikOrder(String status) {
    final s = status.toLowerCase();
    return s == 'penjemputan' || s == 'siap diantar';
  }

  bool _isSelesaiOrder(String status) {
    return status.toLowerCase() == 'selesai';
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _mockOrders.where((order) {
      final status = order['status_operasional'] as String;
      final pelanggan = order['Pelanggan'] as Map<String, dynamic>;
      final customerName = pelanggan['nama_lengkap'].toString().toLowerCase();
      final orderCode = order['kode_order'].toString().toLowerCase();

      // 1. Check Primary Tab Filter
      bool matchesTab = false;
      if (_activeTabIndex == 0) {
        // Semua (Menampilkan semua pesanan aktif, yaitu yang belum selesai)
        matchesTab = !_isSelesaiOrder(status);
      } else if (_activeTabIndex == 1) {
        // Logistik
        matchesTab = _isLogistikOrder(status);
        if (matchesTab) {
          // Sub-Filter Logistik
          if (_activeLogistikSubIndex == 1) {
            matchesTab = status.toLowerCase() == 'penjemputan';
          } else if (_activeLogistikSubIndex == 2) {
            matchesTab = status.toLowerCase() == 'siap diantar';
          }
        }
      } else if (_activeTabIndex == 2) {
        // Outlet
        matchesTab = _isOutletOrder(status);
        if (matchesTab) {
          // Sub-Filter Outlet
          if (_activeOutletSubIndex == 1) {
            matchesTab = status.toLowerCase() == 'pesanan diterima' ||
                status.toLowerCase() == 'proses timbang';
          } else if (_activeOutletSubIndex == 2) {
            matchesTab = status.toLowerCase() == 'proses cuci' ||
                status.toLowerCase() == 'proses kering';
          } else if (_activeOutletSubIndex == 3) {
            matchesTab = status.toLowerCase() == 'proses lipat' ||
                status.toLowerCase() == 'proses setrika';
          }
        }
      } else {
        // Selesai
        matchesTab = _isSelesaiOrder(status);
      }

      // 2. Check Search Query
      bool matchesSearch = _searchQuery.isEmpty ||
          customerName.contains(_searchQuery.toLowerCase()) ||
          orderCode.contains(_searchQuery.toLowerCase());

      return matchesTab && matchesSearch;
    }).toList();
  }

  int get _outletCount => _mockOrders.where((o) => _isOutletOrder(o['status_operasional'])).length;
  int get _logistikCount => _mockOrders.where((o) => _isLogistikOrder(o['status_operasional'])).length;
  int get _selesaiCount => _mockOrders.where((o) => _isSelesaiOrder(o['status_operasional'])).length;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER OPERASIONAL ---
              _buildHeaderSection(),
              const SizedBox(height: 10),

              // --- METRIC RINGKASAN CARD ---
              _buildSummaryMetrics(),

              // --- BILAH PENCARIAN & FILTER TAB ---
              _buildSearchAndFilters(),

              // --- DAFTAR KARTU PESANAN OPERASIONAL ---
              Expanded(
                child: _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          // Simulasi refresh singkat
                          await Future.delayed(const Duration(seconds: 1));
                          if (mounted) setState(() {});
                        },
                        color: navyColor,
                        backgroundColor: Colors.white,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            TranslationService.translate('orders'),
            style: GoogleFonts.poppins(
              color: navyColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    // Selalu tampilkan kartu metrik di semua tab agar karyawan dapat memantau ringkasan global
    // setiap saat dengan mudah.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: navyColor.withValues(alpha: 0.08), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: navyColor.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildMetricItem(
              icon: Icons.store_mall_directory_outlined,
              color: const Color(0xFF9C27B0),
              label: 'Outlet',
              count: _outletCount,
            ),
            Container(width: 1.5, height: 40, color: Colors.grey.shade200),
            _buildMetricItem(
              icon: Icons.local_shipping_outlined,
              color: const Color(0xFF0288D1),
              label: 'Logistik',
              count: _logistikCount,
            ),
            Container(width: 1.5, height: 40, color: Colors.grey.shade200),
            _buildMetricItem(
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF2E7D32),
              label: 'Selesai',
              count: _selesaiCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: navyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar Pencarian
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: navyColor.withOpacity(0.12), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: navyColor.withOpacity(0.6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama pelanggan atau kode...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = "";
                      });
                    },
                    child: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu Utama Segmented Card (Level 1 - Premium Sliding Capsule Design)
          Container(
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: navyColor.withValues(alpha: 0.06), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                final double tabWidth = totalWidth / 4; 

                return Stack(
                  children: [
                    // 1. Sliding Pill Background Container
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      left: _activeTabIndex * tabWidth,
                      width: tabWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: navyColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: navyColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Row of Typography Text Buttons
                    Row(
                      children: List.generate(4, (index) {
                        final String label = ['Semua', 'Logistik', 'Outlet', 'Selesai'][index];
                        final isSelected = _activeTabIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeTabIndex = index;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.grey.shade500,
                                ),
                                child: Text(label),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),

          // Sub-Filter Dinamis (Level 2)
          if (_activeTabIndex == 1 || _activeTabIndex == 2) ...[
            const SizedBox(height: 14),
            _buildSubFilterChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubFilterChips() {
    if (_activeTabIndex == 1) {
      // Logistik Sub-Filters
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildSubChip(0, 'Semua Logistik', isLogistik: true),
            const SizedBox(width: 8),
            _buildSubChip(1, 'Pickup', isLogistik: true),
            const SizedBox(width: 8),
            _buildSubChip(2, 'Delivery', isLogistik: true),
          ],
        ),
      );
    } else if (_activeTabIndex == 2) {
      // Outlet Sub-Filters
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildSubChip(0, 'Semua Proses', isLogistik: false),
            const SizedBox(width: 8),
            _buildSubChip(1, 'Timbang', isLogistik: false),
            const SizedBox(width: 8),
            _buildSubChip(2, 'Cuci & Kering', isLogistik: false),
            const SizedBox(width: 8),
            _buildSubChip(3, 'Lipat & Setrika', isLogistik: false),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSubChip(int index, String label, {required bool isLogistik}) {
    final isSelected = isLogistik 
        ? _activeLogistikSubIndex == index 
        : _activeOutletSubIndex == index;
        
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isLogistik) {
            _activeLogistikSubIndex = index;
          } else {
            _activeOutletSubIndex = index;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? navyColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? navyColor : navyColor.withOpacity(0.12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? navyColor : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final pelanggan = order['Pelanggan'] as Map<String, dynamic>;
    final layanan = order['Layanan'] as Map<String, dynamic>;
    final paket = order['PaketLayanan'] as Map<String, dynamic>;
    final pembayaran = order['Pembayaran'] as Map<String, dynamic>;
    final status = order['status_operasional'] as String;

    final String orderCode = order['kode_order'] ?? 'WW-${order['id_order']}';
    final String customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
    final String serviceName = TranslationService.translateService(layanan['nama_layanan'] ?? 'Layanan');
    final String packageName = paket['nama_paket'] ?? 'Reguler';
    final double totalBayar = order['total_bayar'] as double;
    final String priceStr = totalBayar == 0.0 ? '-' : _formatPrice(totalBayar);

    final statusColor = _getStatusColor(status);
    final String translatedStatus = TranslationService.translateStatus(status);

    final bool isLunas = pembayaran['status_pembayaran'] == 'Lunas';
    final Color paymentBg = isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final Color paymentText = isLunas ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final String paymentLabel = isLunas ? 'Lunas' : 'Belum Lunas';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: navyColor.withOpacity(0.08), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: navyColor.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailScreenKaryawan(
                  order: order,
                  onOrderUpdated: (updatedOrder) {
                    setState(() {
                      final idx = _mockOrders.indexWhere((o) => o['id_order'] == updatedOrder['id_order']);
                      if (idx != -1) {
                        _mockOrders[idx] = updatedOrder;
                      }
                    });
                  },
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: navyColor.withOpacity(0.04),
          highlightColor: navyColor.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kode Order & Tanggal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderCode,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cyanColor,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(order['tgl_pesanan']),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. Nama Pelanggan
                Text(
                  customerName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: navyColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // 3. Layanan & Paket
                Row(
                  children: [
                    Icon(Icons.local_laundry_service_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      '$serviceName ($packageName)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Status Badges & Harga
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badges (Operasional & Pembayaran)
                    Row(
                      children: [
                        // Status Operasional
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: statusColor.withOpacity(0.15), width: 1),
                          ),
                          child: Text(
                            translatedStatus,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Pembayaran
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: paymentBg,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: paymentText.withOpacity(0.15), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: paymentText,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                paymentLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: paymentText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Harga Total
                    Text(
                      priceStr,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: totalBayar == 0.0 ? Colors.grey.shade400 : const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: navyColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment_late_outlined, size: 50, color: navyColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak Ada Pesanan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daftar pesanan operasional kosong atau tidak cocok.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOperationalDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final pelanggan = order['Pelanggan'] as Map<String, dynamic>;
        final layanan = order['Layanan'] as Map<String, dynamic>;
        final paket = order['PaketLayanan'] as Map<String, dynamic>;
        final parfum = order['Parfum'] as Map<String, dynamic>;
        final pembayaran = order['Pembayaran'] as Map<String, dynamic>;
        final alamatAmbil = order['AlamatPengambilan'] as Map<String, dynamic>;
        final status = order['status_operasional'] as String;

        final String orderCode = order['kode_order'] ?? 'WW-${order['id_order']}';
        final String customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
        final String customerPhone = pelanggan['no_hp'] ?? '-';
        final String serviceName = TranslationService.translateService(layanan['nama_layanan'] ?? 'Layanan');
        final String packageName = paket['nama_paket'] ?? 'Reguler';
        final double kuantitas = (order['kuantitas'] as num).toDouble();
        final double totalBayar = order['total_bayar'] as double;
        final String careNote = order['catatan_order'] ?? '';

        final bool isLunas = pembayaran['status_pembayaran'] == 'Lunas';
        final statusColor = _getStatusColor(status);
        final String translatedStatus = TranslationService.translateStatus(status);

        // Timeline stepper database-aligned
        final List<String> allSteps = [
          'Pesanan Diterima',
          'Penjemputan',
          'Proses Timbang',
          'Proses Cuci',
          'Proses Kering',
          'Proses Lipat',
          'Siap Diantar',
          'Selesai'
        ];

        int currentStepIdx = allSteps.indexWhere((s) => s.toLowerCase() == status.toLowerCase());
        if (currentStepIdx == -1) currentStepIdx = 0;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Indikator Seret
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Konten Scrollable
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      children: [
                        // Header Detail
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Operational Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: cyanColor,
                                  ),
                                ),
                                Text(
                                  orderCode,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: navyColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: statusColor.withOpacity(0.2), width: 1.2),
                              ),
                              child: Text(
                                translatedStatus,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section 1: Customer Profile
                        _buildSectionTitle('Customer Information'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgGrey,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: navyColor.withOpacity(0.1),
                                child: Icon(Icons.person, color: navyColor, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: navyColor,
                                      ),
                                    ),
                                    Text(
                                      customerPhone,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone_outlined, color: Colors.green),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 2: Stepper Timeline (Visual & Mudah Dipahami)
                        _buildSectionTitle('Tracking Progress'),
                        const SizedBox(height: 16),
                        _buildDetailedStepper(allSteps, currentStepIdx),
                        const SizedBox(height: 24),

                        // Section 3: Layanan & Alamat
                        _buildSectionTitle('Order Summary'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRowDetail('Layanan', '$serviceName ($packageName)'),
                              _buildRowDetail('Berat Cucian', kuantitas > 0.0 ? '$kuantitas Kg' : 'Menunggu Timbang'),
                              _buildRowDetail('Parfum Pilihan', parfum['nama_parfum'] ?? 'Lavender Bliss'),
                              _buildRowDetail('Metode Penjemputan', order['tipe_logistik']),
                              _buildRowDetail('Alamat Pengambilan', alamatAmbil['alamat_lengkap']),
                              if (careNote.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 16),
                                    Text(
                                      'Instruksi Khusus:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: navyColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      careNote,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.red.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 4: Nota Pembayaran (Invoice)
                        _buildSectionTitle('Payment Details'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isLunas ? 'LUNAS (PAID)' : 'BELUM BAYAR (UNPAID)',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isLunas ? Colors.green.shade700 : Colors.orange.shade700,
                                    ),
                                  ),
                                  Text(
                                    _formatPrice(totalBayar),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: isLunas ? Colors.green.shade700 : navyColor,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              
                              // Barcode Nota (Sangat Profesional)
                              Center(
                                child: Column(
                                  children: [
                                    BarcodeWidget(
                                      barcode: Barcode.code128(),
                                      data: orderCode,
                                      width: 220,
                                      height: 60,
                                      drawText: true,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: navyColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '*Cetak struk nota untuk proses penimbangan outlet',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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
        Expanded(child: Divider(color: Colors.grey.shade200)),
      ],
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: navyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStepper(List<String> steps, int activeIndex) {
    return Column(
      children: List.generate(steps.length, (idx) {
        final bool isCompleted = idx <= activeIndex;
        final bool isCurrent = idx == activeIndex;
        final bool isLast = idx == steps.length - 1;

        final Color stepColor = isCompleted ? cyanColor : Colors.grey.shade300;
        final Color textStyleColor = isCompleted ? navyColor : Colors.grey.shade500;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line & Dot
            Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isCompleted ? stepColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: stepColor,
                      width: 2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: cyanColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : const SizedBox.shrink(),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    color: idx < activeIndex ? cyanColor : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Teks Tahap
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  TranslationService.translateStatus(steps[idx]),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                    color: textStyleColor,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}