import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PelangganHomeScreen extends StatefulWidget {
  const PelangganHomeScreen({super.key});

  @override
  State<PelangganHomeScreen> createState() => _PelangganHomeScreenState();
}

class _PelangganHomeScreenState extends State<PelangganHomeScreen> {
  // Warna-warna khusus sesuai UI Design
  final Color _darkBlue = const Color(0xFF0F2F53);
  final Color _cyan = const Color(0xFF42C6D4);
  final Color _lightCyanBg = const Color(0xFFEAF9FA);
  final Color _greyText = const Color(0xFF7A8D9C);

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 💡 1. BODY DENGAN BACKGROUND GRADIENT
      body: Stack(
        children: [
          // Background Gradient Biru ke Putih di atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD4F0F7), // Biru sangat muda
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          
          // Konten Utama yang bisa di-scroll
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // Ruang untuk Bottom Nav
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildLocationCard(),
                    const SizedBox(height: 24),
                    _buildPromoBanner(),
                    const SizedBox(height: 16),
                    _buildDotIndicator(),
                    const SizedBox(height: 32),
                    _buildServicesSection(),
                    const SizedBox(height: 32),
                    _buildOrderStatusSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 💡 2. CUSTOM BOTTOM NAVIGATION BAR & FAB
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _cyan.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: _cyan,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_filled, 'Home', 0),
              _buildNavItem(Icons.receipt_long, 'Orders', 1),
              const SizedBox(width: 48), // Ruang kosong untuk FAB di tengah
              _buildNavItem(Icons.chat_bubble_outline, 'Message', 2),
              _buildNavItem(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // KOMPONEN-KOMPONEN UI
  // =========================================================================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, Mark Lee!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _darkBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Which laundry service do you need today?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _darkBlue.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        // Ikon Lonceng Notifikasi dengan Badge Merah
        Stack(
          children: [
            Icon(Icons.notifications_none_rounded, color: _darkBlue, size: 32),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: _darkBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Jalan Kesana Kesini',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _darkBlue,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: _darkBlue),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEDFBFE), Color(0xFFD3F2F7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '20% Off Your First Order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _darkBlue,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 200,
                child: Text(
                  'Enjoy a special discount on your first laundry service. Limited time only.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _greyText,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _cyan,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Claim Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          // Placeholder untuk gambar 3D amplop (Kamu harus siapkan gambarnya di assets)
          const Positioned(
            right: -10,
            top: -10,
            bottom: -10,
            child: Icon(Icons.email, size: 100, color: Colors.blueAccent), // Ganti dengan Image.asset nanti
          )
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _darkBlue, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blueGrey.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildServiceCard('Wash &\nIroning', const Color(0xFFE0F7FA), const Color(0xFFB2EBF2), _darkBlue)),
            const SizedBox(width: 12),
            Expanded(child: _buildServiceCard('Wash\nOnly', const Color(0xFFF3E5F5), const Color(0xFFE1BEE7), const Color(0xFF6A1B9A))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildServiceCard('Ironing\nOnly', const Color(0xFFFFF3E0), const Color(0xFFFFE0B2), const Color(0xFFE65100))),
            const SizedBox(width: 12),
            Expanded(child: _buildServiceCard('Dry\nClean', const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), const Color(0xFF2E7D32))),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(String title, Color gradStart, Color gradEnd, Color textColor) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          // Placeholder ikon/gambar background (Harus diganti aset gambar cucian nanti)
          Positioned(
            left: -10,
            top: 0,
            bottom: 0,
            child: Icon(Icons.local_laundry_service, size: 60, color: Colors.white.withValues(alpha: 0.5)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _lightCyanBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _cyan.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #1234',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _darkBlue),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Color(0xFFD65B5B)),
                      const SizedBox(width: 4),
                      const Text(
                        'Est: 30 April 2026',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD65B5B)),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Wash & Iron (1 kg)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkBlue),
              ),
              const SizedBox(height: 24),
              
              // Custom Stepper
              Row(
                children: [
                  _buildStep(label: 'Pick Up', isDone: true),
                  _buildLine(isActive: true),
                  _buildStep(label: 'Wash', isCurrent: true),
                  _buildLine(isActive: false),
                  _buildStep(label: 'Iron', isDone: false),
                  _buildLine(isActive: false),
                  _buildStep(label: 'Delivery', isDone: false),
                  _buildLine(isActive: false),
                  _buildStep(label: 'Success', isDone: false),
                ],
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _darkBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View More', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  // Komponen pembantu untuk garis Custom Stepper
  Widget _buildLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? _darkBlue : Colors.white,
      ),
    );
  }

  // Komponen pembantu untuk titik Custom Stepper
  Widget _buildStep({required String label, bool isDone = false, bool isCurrent = false}) {
    return Column(
      children: [
        if (isDone)
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: _darkBlue, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          )
        else if (isCurrent)
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _darkBlue, width: 2),
            ),
            child: Center(
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: _darkBlue, shape: BoxShape.circle),
              ),
            ),
          )
        else
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: (isDone || isCurrent) ? FontWeight.bold : FontWeight.normal,
            color: (isDone || isCurrent) ? _darkBlue : _greyText,
          ),
        )
      ],
    );
  }

  // Komponen pembantu untuk Bottom Navigation Item
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? _cyan : _greyText.withValues(alpha: 0.5),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _cyan : _greyText.withValues(alpha: 0.5),
              ),
            )
          ],
        ),
      ),
    );
  }
}