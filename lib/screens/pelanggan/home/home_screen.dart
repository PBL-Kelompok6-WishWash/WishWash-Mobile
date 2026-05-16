import 'package:flutter/material.dart';
import 'package:mobile/screens/splash_screen.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/notifikasi.dart';
import 'package:mobile/screens/pelanggan/chat/chat_screen.dart';
import 'package:mobile/screens/pelanggan/profile/profile_screen.dart';
import 'package:mobile/services/pelanggan_service.dart';

void main() {
  runApp(
    const MaterialApp(
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class PelangganHomeScreen extends StatefulWidget {
  final bool showNavbar;
  const PelangganHomeScreen({super.key, this.showNavbar = true});

  @override
  State<PelangganHomeScreen> createState() => _PelangganHomeScreenState();
}

class _PelangganHomeScreenState extends State<PelangganHomeScreen> {
  final Color _darkBlue = const Color(0xFF0F2F53);
  final Color _cyan = const Color(0xFF42C6D4);
  final Color _lightCyanBg = const Color(0xFFEAF9FA);
  final Color _greyText = const Color(0xFF7A8D9C);

  int _currentPromoIndex = 0;
  bool _isLocationMenuOpen = false;

  // Perubahan 1: Gunakan viewportFraction agar kartu berikutnya sedikit terlihat
  final PageController _promoController = PageController(viewportFraction: 0.9);

  String _namaLengkap = 'User';
  String _alamatLengkap = 'Memuat alamat...';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await PelangganService.getProfile();
      if (response['success'] == true) {
        final data = response['data'];
        final pelanggan = data['pelanggan'] ?? {};
        
        if (mounted) {
          setState(() {
            _namaLengkap = pelanggan['nama_lengkap'] ?? 'User';
            final alamat = data['alamat_lengkap'];
            _alamatLengkap = (alamat == null || alamat.toString().trim().isEmpty) 
                ? 'Alamat belum diatur' 
                : alamat.toString();
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _alamatLengkap = 'Gagal memuat alamat';
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alamatLengkap = 'Koneksi bermasalah';
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8FBFC),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD4F0F7), Color(0xFFF8FBFC)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 65),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildHeader(),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLocationMenuOpen = !_isLocationMenuOpen;
                            });
                          },
                          child: _buildLocationCard(context),
                        ),
                        if (_isLocationMenuOpen) ...[
                          const SizedBox(height: 8),
                          _buildExpandedLocationCard(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Slider diletakkan di luar padding horizontal utama agar bisa 'bleeding' ke pinggir
                  _buildPromoSlider(),
                  const SizedBox(height: 12),
                  _buildDotIndicator(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _buildServicesSection(),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _buildOrderStatusSection(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showNavbar ? BottomNavbar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const PelangganHomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const ChatScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const ProfileScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
      ) : null,
    );
  }

  // --- REVISI UTAMA: PROMO SLIDER ---
  Widget _buildPromoSlider() {
    return SizedBox(
      height: 180,
      child: PageView(
        controller: _promoController,
        onPageChanged: (index) => setState(() => _currentPromoIndex = index),
        children: [
          _buildPromoItem(
            '20% Off Your First Order',
            'Enjoy a special discount\non your first laundry service.',
            const Color(0xFFE3F9FD),
            const Color(0xFF42C6D4),
            'assets/images/promos/diskon.png',
            const Color(0xFF0D47A1), // Teks biru untuk kartu biru
          ),
          _buildPromoItem(
            'Free Pickup Available',
            'Get your laundry picked up\nfor free in selected areas.',
            const Color(0xFFFDEEF6),
            const Color(0xFFE91E63),
            'assets/images/promos/free_deliv.png',
            const Color(
              0xFF880E4F,
            ), // Teks pink gelap agar nyambung dengan kartu pink
          ),
        ],
      ),
    );
  }

  Widget _buildPromoItem(
    String title,
    String subtitle,
    Color bgColor,
    Color btnColor,
    String imagePath,
    Color textColor, // Tambah parameter warna teks
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ), // Vertical margin untuk ruang shadow
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        // SHADOW TIPIS DI BAGIAN BAWAH
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gambar di pojok kanan bawah
          Positioned(
            right: -10,
            bottom: 0,
            child: SizedBox(
              width: 140,
              height: 140,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: btnColor.withOpacity(0.2),
                ),
              ),
            ),
          ),
          // Teks di sisi kiri
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor, // Menggunakan warna adaptif
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(
                      0.7,
                    ), // Mengikuti warna teks utama
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                // Tombol
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: btnColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(100, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      title.contains('Free') ? 'Check Now' : 'Claim Now',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

  // --- SISANYA TETAP SAMA (WIDGET LAINNYA) ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $_namaLengkap!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Which service do you need?',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF0D47A1).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        _buildNotificationIcon(),
      ],
    );
  }

Widget _buildNotificationIcon() {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NotificationScreen()),
      );
    },
    child: Stack(
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          color: Color(0xFF0D47A1),
          size: 28,
        ),
        Positioned(
          right: 1,
          top: 1,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLocationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
      child: Row(
        children: [
          Image.asset('assets/images/icons/icon_location.png', width: 20, height: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _alamatLengkap,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D47A1),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            _isLocationMenuOpen 
                ? Icons.keyboard_arrow_up_rounded 
                : Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF0D47A1),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          if (_alamatLengkap != 'Alamat belum diatur') ...[
            Row(
              children: [
                const Icon(Icons.home_outlined, color: Color(0xFF0D47A1), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _alamatLengkap,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          GestureDetector(
            onTap: () {
              // Aksi tambah alamat
            },
            child: Text(
              '+ Add New Address',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D47A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: _currentPromoIndex == index ? 12 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _currentPromoIndex == index
                ? const Color(0xFF0D47A1)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: [
            _buildServiceCard(
              'Wash &\nIroning',
              const Color(0xFFD1F1F8),
              const Color(0xFF0D47A1),
              'assets/images/services/wash_iron.png',
            ),
            _buildServiceCard(
              'Wash\nOnly',
              const Color(0xFFF1E1FB),
              const Color(0xFF6A1B9A),
              'assets/images/services/wash_only.png',
            ),
            _buildServiceCard(
              'Ironing\nOnly',
              const Color(0xFFFCECDD),
              const Color(0xFFE65100),
              'assets/images/services/ironing.png',
            ),
            _buildServiceCard(
              'Dry\nClean',
              const Color(0xFFE2F3E4),
              const Color(0xFF2E7D32),
              'assets/images/services/dry_clean.png',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    String title,
    Color bgColor,
    Color textColor,
    String imagePath,
  ) {
    // Mengubah radius menjadi 12 agar tidak terlalu bulat
    final double cardRadius = 12.0;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black, Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 20),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Order Status',
          style: TextStyle(
            fontSize: 16, // Ukuran font diperkecil sedikit
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ), // Padding dirapatkan
          decoration: BoxDecoration(
            color: const Color(0xFFD1F1F8).withOpacity(0.4),
            borderRadius: BorderRadius.circular(
              16,
            ), // Radius diperkecil agar lebih rapi
            border: Border.all(color: const Color(0xFFB2EBF2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Order ID & Estimasi (Warna Merah)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #1234',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0D47A1),
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.redAccent, // Icon Jam Merah
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Est: 30 April 2026',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.redAccent, // Teks Estimasi Merah
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Jenis Layanan
              Text(
                'Wash & Iron (1 kg)',
                style: TextStyle(
                  fontSize: 15, // Lebih proporsional
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 16),

              // Stepper Tracker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepItem('Pick Up', Icons.check, true, true),
                  _buildStepLine(true),
                  _buildStepItem(
                    'Wash',
                    Icons.circle,
                    true,
                    false,
                    isCurrent: true,
                  ),
                  _buildStepLine(false),
                  _buildStepItem('Iron', null, false, false),
                  _buildStepLine(false),
                  _buildStepItem('Delivery', null, false, false),
                  _buildStepLine(false),
                  _buildStepItem('Success', null, false, false),
                ],
              ),

              const SizedBox(height: 16),
              // Tombol View More
              SizedBox(
                width: double.infinity,
                height: 40, // Tinggi tombol dikunci agar tidak kebesaran
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D47A1),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'View More',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget Helper Ikon + Label
  Widget _buildStepItem(
    String label,
    IconData? icon,
    bool isActive,
    bool isDone, {
    bool isCurrent = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3), // Ukuran bulatan diperkecil
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF0D47A1) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: isCurrent
              ? const Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: Color(0xFF0D47A1),
                )
              : Icon(
                  icon ?? Icons.circle,
                  size: 8,
                  color: isDone
                      ? Colors.white
                      : (isActive
                            ? const Color(0xFF0D47A1)
                            : Colors.transparent),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9, // Font label diperkecil
            fontWeight: isCurrent || isDone
                ? FontWeight.bold
                : FontWeight.normal,
            color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Widget Helper Garis
  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(
          bottom: 14,
        ), // Disesuaikan dengan ukuran font label baru
        color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade300,
      ),
    );
  }
}
