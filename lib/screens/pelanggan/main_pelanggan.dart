import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'chat/chat_screen.dart';
import 'profile/profile_screen.dart';
import 'orders/orders_screen.dart';
import '../../widgets/navbar_pelanggan.dart';

class MainPelanggan extends StatefulWidget {
  final int initialIndex;
  const MainPelanggan({super.key, this.initialIndex = 0});

  @override
  State<MainPelanggan> createState() => _MainPelangganState();
}

class _MainPelangganState extends State<MainPelanggan> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const PelangganHomeScreen(showNavbar: false),
    const OrdersScreen(showNavbar: false),
    const Center(child: Text('Add Screen')),    // Placeholder for Plus Action
    const ChatScreen(showNavbar: false),
    const ProfileScreen(showNavbar: false),
  ];

  void _onTap(int index) {
    if (index == 2) {
      // Tampilkan Menu Buat Pesanan (Bottom Sheet)
      _showOrderMenu(context);
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showOrderMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        const Color cyanColor = Color(0xFF42C6D4);
        const Color navyColor = Color(0xFF0F2F53);
        
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Buat Pesanan Baru',
                style: TextStyle(
                  color: navyColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),
              _buildOrderOption(
                icon: Icons.local_laundry_service,
                title: 'Cuci Kiloan',
                subtitle: 'Cuci dan setrika pakaian harian',
                color: cyanColor,
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan navigasi ke form cuci kiloan nanti
                },
              ),
              const SizedBox(height: 12),
              _buildOrderOption(
                icon: Icons.dry_cleaning,
                title: 'Setrika Saja',
                subtitle: 'Hanya jasa setrika pakaian',
                color: const Color(0xFF5ACFD6),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildOrderOption(
                icon: Icons.roller_shades_closed, // Sebagai ikon sepatu/lainnya
                title: 'Cuci Sepatu',
                subtitle: 'Perawatan cuci sepatu premium',
                color: const Color(0xFF28A0A8),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2F53),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
