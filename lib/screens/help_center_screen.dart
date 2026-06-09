import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterScreen extends StatefulWidget {
  final String userRole; // 'pelanggan' or 'karyawan'

  const HelpCenterScreen({super.key, required this.userRole});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgGrey = const Color(0xFFF8FBFC);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKaryawanTabActive = widget.userRole == 'karyawan';

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Elegant pastel circles in background for premium layout
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: cyanColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: navyColor.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBanner(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildCategoryFilter(isKaryawanTabActive),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                _buildFAQListSliver(isKaryawanTabActive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.arrow_back_ios_rounded, color: navyColor, size: 16),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        'Pertanyaan Umum',
        style: GoogleFonts.poppins(
          color: navyColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [navyColor, const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navyColor.withOpacity(0.24),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cyanColor.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bantuan Mandiri',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB2EBF2),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pertanyaan Populer',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Temukan jawaban instan untuk kendala laundry Anda.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: cyanColor,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.toLowerCase();
          });
        },
        style: GoogleFonts.poppins(color: navyColor, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: cyanColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Icon(Icons.close_rounded, color: navyColor.withOpacity(0.5)),
                )
              : null,
          hintText: 'Cari kendala atau pertanyaan...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isKaryawan) {
    final categories = isKaryawan ? _getEmployeeCategories() : _getCustomerCategories();
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _selectedCategory = cat['id'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? navyColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey.shade200,
                    ),
                    boxShadow: isSelected 
                        ? [
                            BoxShadow(
                              color: navyColor.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cat['icon'],
                        size: 14,
                        color: isSelected ? Colors.white : navyColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat['label'],
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : navyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQListSliver(bool isKaryawan) {
    final faqs = isKaryawan ? _getEmployeeFAQs() : _getCustomerFAQs();
    
    // Filter by category and search query
    final filteredFaqs = faqs.where((faq) {
      final matchesCategory = _selectedCategory == 'all' || faq['category'] == _selectedCategory;
      final matchesSearch = faq['q'].toLowerCase().contains(_searchQuery) ||
                            faq['a'].toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    if (filteredFaqs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cyanColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search_off_rounded, size: 48, color: cyanColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada hasil ditemukan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cobalah mencari dengan kata kunci lain atau pilih kategori berbeda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: navyColor.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final faq = filteredFaqs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: cyanColor.withOpacity(0.05),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cyanColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.help_center_rounded, color: cyanColor, size: 18),
                  ),
                  title: Text(
                    faq['q'],
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  iconColor: cyanColor,
                  textColor: cyanColor,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Divider(color: bgGrey, thickness: 1.5),
                    const SizedBox(height: 8),
                    Text(
                      faq['a'],
                      style: GoogleFonts.poppins(
                        color: navyColor.withOpacity(0.75),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: filteredFaqs.length,
        ),
      ),
    );
  }

  // --- DATA SOURCES ---

  // FAQ Items
  List<Map<String, dynamic>> _getCustomerFAQs() {
    return [
      {
        'category': 'general',
        'q': 'Apa itu WishWash Laundry?',
        'a': 'WishWash Laundry adalah layanan laundry premium berbasis aplikasi yang melayani cuci kering lipat, cuci setrika, hingga setrika saja dengan layanan penjemputan dan pengantaran langsung ke pintu Anda.',
      },
      {
        'category': 'general',
        'q': 'Bagaimana cara memesan lewat aplikasi?',
        'a': 'Cukup masuk ke halaman Beranda, klik tombol "Buat Pesanan Baru", pilih jenis layanan, atur alamat jemput dan antar, lalu selesaikan pemesanan. Kurir kami akan segera menjemput pakaian Anda.',
      },
      {
        'category': 'orders',
        'q': 'Bagaimana cara melacak cucian saya?',
        'a': 'Anda dapat memantau status cucian Anda secara real-time melalui halaman "Pesanan" di aplikasi, mulai dari penjemputan, penimbangan, proses cuci, pengeringan, hingga pengantaran.',
      },
      {
        'category': 'orders',
        'q': 'Apakah saya bisa membatalkan pesanan yang sudah dibuat?',
        'a': 'Pembatalan pesanan dapat dilakukan sebelum kurir melakukan penjemputan pakaian. Jika kurir sudah dalam perjalanan atau pakaian sudah diambil, silakan hubungi CS kami.',
      },
      {
        'category': 'payments',
        'q': 'Apa saja metode pembayaran yang didukung?',
        'a': 'Kami mendukung pembayaran tunai (Cash on Delivery), transfer bank (Virtual Account), dan berbagai e-wallet seperti GoPay, OVO, ShopeePay, dan Dana.',
      },
      {
        'category': 'payments',
        'q': 'Mengapa status pembayaran saya masih pending?',
        'a': 'Jika Anda membayar via transfer bank, proses verifikasi manual memerlukan waktu 5-10 menit. Pastikan Anda mengunggah bukti pembayaran yang valid di aplikasi.',
      },
      {
        'category': 'delivery',
        'q': 'Berapa biaya penjemputan dan pengantaran?',
        'a': 'Biaya pengiriman dihitung secara otomatis berdasarkan jarak lokasi Anda dari outlet terdekat. Tarif standar berkisar antara Rp 5.000 - Rp 15.000.',
      },
      {
        'category': 'delivery',
        'q': 'Bagaimana jika saya tidak ada di rumah saat kurir datang?',
        'a': 'Kurir akan menghubungi Anda sebelum datang. Jika Anda tidak berada di tempat, Anda bisa meminta kurir menitipkan pakaian ke tetangga, satpam, atau menjadwal ulang pengiriman.',
      },
    ];
  }

  List<Map<String, dynamic>> _getEmployeeFAQs() {
    return [
      {
        'category': 'general',
        'q': 'Bagaimana cara memproses pesanan masuk?',
        'a': 'Buka dasbor Karyawan, pilih pesanan di tab "Order Masuk", lalu klik "Terima". Lakukan penimbangan dan update status ke "Diproses" setelah pakaian diterima di outlet.',
      },
      {
        'category': 'general',
        'q': 'Bagaimana cara mengubah status ketersediaan saya?',
        'a': 'Masuk ke halaman Profil Anda, lalu ketuk badge status di bagian atas (Aktif/Sibuk) untuk memperbarui ketersediaan Anda dalam menerima tugas pengantaran.',
      },
      {
        'category': 'operations',
        'q': 'Langkah saat menjemput pakaian pelanggan?',
        'a': '1. Pastikan kecocokan nama & alamat pelanggan. 2. Periksa kelayakan pakaian (robek/luntur). 3. Konfirmasi jenis layanan yang dipilih. 4. Update status pesanan ke "Diambil" di aplikasi.',
      },
      {
        'category': 'operations',
        'q': 'Bagaimana cara menyelesaikan pesanan yang siap diantar?',
        'a': 'Buka pesanan di tab "Siap Diantar", klik "Mulai Pengantaran" saat berangkat. Setibanya di tujuan, minta konfirmasi penerima, ambil foto bukti penyerahan, dan klik "Selesai".',
      },
      {
        'category': 'issues',
        'q': 'Bagaimana jika pelanggan tidak dapat dihubungi?',
        'a': 'Tunggu di lokasi maksimal 10 menit sambil mencoba menelepon. Jika tetap gagal, koordinasikan dengan admin outlet untuk menjadwal ulang pengantaran dan bawa pakaian kembali ke outlet.',
      },
      {
        'category': 'issues',
        'q': 'Bagaimana jika terjadi kerusakan pada kendaraan operasional?',
        'a': 'Segera pinggirkan kendaraan ke tempat aman. Hubungi Manager Operasional via menu "Hubungi Manager" di aplikasi, laporkan koordinat lokasi Anda, dan tim rescue akan segera dikirim.',
      },
      {
        'category': 'policies',
        'q': 'Standar penanganan jika pakaian rusak di outlet?',
        'a': 'Jangan lanjutkan pencucian jika ada pakaian yang berisiko merusak pakaian lain. Segera pisahkan, dokumentasikan kerusakannya, dan laporkan kepada Manager Outlet untuk persetujuan solusi ke pelanggan.',
      },
    ];
  }

  // Categories list
  List<Map<String, dynamic>> _getCustomerCategories() {
    return [
      {'id': 'all', 'label': 'Semua Kategori', 'icon': Icons.grid_view_rounded},
      {'id': 'general', 'label': 'Umum', 'icon': Icons.info_outline_rounded},
      {'id': 'orders', 'label': 'Pesanan', 'icon': Icons.shopping_bag_outlined},
      {'id': 'payments', 'label': 'Pembayaran', 'icon': Icons.credit_card_rounded},
      {'id': 'delivery', 'label': 'Pengiriman', 'icon': Icons.local_shipping_outlined},
    ];
  }

  List<Map<String, dynamic>> _getEmployeeCategories() {
    return [
      {'id': 'all', 'label': 'Semua Kategori', 'icon': Icons.grid_view_rounded},
      {'id': 'general', 'label': 'Umum', 'icon': Icons.info_outline_rounded},
      {'id': 'operations', 'label': 'Operasional', 'icon': Icons.assignment_outlined},
      {'id': 'issues', 'label': 'Kendala', 'icon': Icons.warning_amber_rounded},
      {'id': 'policies', 'label': 'Kebijakan', 'icon': Icons.gavel_rounded},
    ];
  }
}
