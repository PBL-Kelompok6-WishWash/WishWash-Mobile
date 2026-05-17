import 'package:flutter/material.dart';
import 'package:mobile/screens/splash_screen.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/notifikasi.dart';
import 'package:mobile/screens/pelanggan/chat/chat_screen.dart';
import 'package:mobile/screens/pelanggan/profile/profile_screen.dart';
import 'package:mobile/screens/pelanggan/home/alamat_screen.dart';
import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/services/layanan_service.dart';
import 'package:mobile/screens/pelanggan/orders/create_order_screen.dart';
import 'dart:convert';

void main() {
  runApp(
    const MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class PelangganHomeScreen extends StatefulWidget {
  final bool showNavbar;
  const PelangganHomeScreen({super.key, this.showNavbar = true});

  @override
  State<PelangganHomeScreen> createState() => PelangganHomeScreenState();
}

class PelangganHomeScreenState extends State<PelangganHomeScreen> {
  final Color _cyan = const Color(0xFF42C6D4);

  int _currentPromoIndex = 0;
  bool _isLocationMenuOpen = false;

  // Perubahan 1: Gunakan viewportFraction agar kartu berikutnya sedikit terlihat
  final PageController _promoController = PageController(viewportFraction: 0.9);

  String _namaLengkap = 'User';
  String _alamatLengkap = 'Memuat alamat...';
  String _tipeAlamat = 'Rumah';
  bool _isLoadingProfile = true;
  List<dynamic> _services = [];
  bool _isLoadingServices = true;
  bool _isSeeAllPressed = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchServicesData();
  }

  void closeDropdown() {
    if (mounted && _isLocationMenuOpen) {
      setState(() {
        _isLocationMenuOpen = false;
      });
    }
  }

  Future<void> _fetchServicesData() async {
    try {
      final servicesData = await LayananService.getLayanan();
      if (mounted) {
        setState(() {
          _services = servicesData;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil data layanan: $e");
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF00BCD4); // fallback
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
            _tipeAlamat = data['tipe_alamat'] ?? 'Rumah';
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLocationMenuOpen = !_isLocationMenuOpen;
                                });
                              },
                              child: _buildLocationCard(context),
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
                      if (_isLocationMenuOpen)
                        Positioned(
                          top: 64, // Positioned tepat di bawah location card
                          left: 20,
                          right: 20,
                          child: _buildExpandedLocationCard(),
                        ),
                    ],
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

  IconData _getIconForTipeAlamat() {
    switch (_tipeAlamat) {
      case 'Rumah':
        return Icons.home_outlined;
      case 'Kantor':
        return Icons.business_outlined;
      default:
        return Icons.bookmark_border_rounded;
    }
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
              '$_tipeAlamat - $_alamatLengkap',
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
            GestureDetector(
              onTap: () {
                setState(() => _isLocationMenuOpen = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlamatScreen()),
                ).then((_) => _fetchProfileData());
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_getIconForTipeAlamat(), color: const Color(0xFF0D47A1), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_tipeAlamat - $_alamatLengkap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          GestureDetector(
            onTap: () {
              setState(() {
                _isLocationMenuOpen = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlamatScreen()),
              ).then((_) {
                _fetchProfileData();
              });
            },
            child: Container(
              width: double.infinity,
              color: Colors.transparent,
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                '+ Add New Address',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Our Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0D47A1),
              ),
            ),
            GestureDetector(
              onTapDown: (_) {
                setState(() {
                  _isSeeAllPressed = true;
                });
              },
              onTapUp: (_) {
                setState(() {
                  _isSeeAllPressed = false;
                });
              },
              onTapCancel: () {
                setState(() {
                  _isSeeAllPressed = false;
                });
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _cyan,
                    decoration: _isSeeAllPressed ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: _cyan,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoadingServices
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            : _services.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Tidak ada layanan yang tersedia',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final String name = service['nama_layanan'] ?? '';
                      final String hexColor = service['warna_layanan'] ?? '#00BCD4';
                      final String imagePath = service['gambar_layanan'] ?? 'assets/images/services/wash_only.png';

                      // Parse hex color to Flutter Color
                      final Color baseColor = _parseHexColor(hexColor);
                      // Generate background color (soft 15% opacity) & text color
                      final Color bgColor = baseColor.withOpacity(0.15);
                      final Color textColor = _getDarkenedTextColor(baseColor);

                      // Format name to display with newlines
                      String formattedName = name;
                      if (name.contains(' & ')) {
                        formattedName = name.replaceAll(' & ', ' &\n');
                      } else if (name.contains(' ')) {
                        formattedName = name.replaceAll(' ', '\n');
                      }

                      return _buildServiceCard(
                        formattedName,
                        bgColor,
                        textColor,
                        imagePath,
                      );
                    },
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
                child: _buildServiceImage(imagePath),
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

  Color getActiveOrderColor() {
    for (var service in _services) {
      final name = (service['nama_layanan'] ?? '').toString().toLowerCase();
      if ((name.contains('cuci') && name.contains('setrika')) || (name.contains('wash') && name.contains('iron'))) {
        return _parseHexColor(service['warna_layanan'] ?? '#9C27B0');
      }
    }
    return const Color(0xFF9C27B0); // Purple default for "Wash & Iron"
  }

  Widget _buildOrderStatusSection() {
    final baseOrderColor = getActiveOrderColor();
    final orderColor = _getDarkenedTextColor(baseOrderColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Order Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: baseOrderColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: orderColor.withOpacity(0.3), width: 1),
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
                      color: orderColor,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Est: 30 April 2026',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.redAccent,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: orderColor,
                ),
              ),
              const SizedBox(height: 16),

              // Stepper Tracker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepItem('Pick Up', Icons.check, true, true, orderColor),
                  _buildStepLine(true, orderColor),
                  _buildStepItem(
                    'Wash',
                    Icons.circle,
                    true,
                    false,
                    orderColor,
                    isCurrent: true,
                  ),
                  _buildStepLine(false, orderColor),
                  _buildStepItem('Iron', null, false, false, orderColor),
                  _buildStepLine(false, orderColor),
                  _buildStepItem('Delivery', null, false, false, orderColor),
                  _buildStepLine(false, orderColor),
                  _buildStepItem('Success', null, false, false, orderColor),
                ],
              ),

              const SizedBox(height: 16),
              // Tombol View More
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: orderColor,
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
    bool isDone,
    Color themeColor, {
    bool isCurrent = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDone ? themeColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? themeColor : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: isCurrent
              ? Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: themeColor,
                )
              : Icon(
                  icon ?? Icons.circle,
                  size: 8,
                  color: isDone
                      ? Colors.white
                      : (isActive
                            ? themeColor
                            : Colors.transparent),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isCurrent || isDone
                ? FontWeight.bold
                : FontWeight.normal,
            color: isActive ? themeColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Widget Helper Garis
  Widget _buildStepLine(bool isActive, Color themeColor) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        color: isActive ? themeColor : Colors.grey.shade300,
      ),
    );
  }
}
