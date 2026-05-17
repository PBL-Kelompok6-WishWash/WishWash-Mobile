import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'chat/chat_screen.dart';
import 'profile/profile_screen.dart';
import 'orders/orders_screen.dart';
import 'orders/create_order_screen.dart';
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

  final GlobalKey<PelangganHomeScreenState> _homeKey = GlobalKey<PelangganHomeScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _pages = [
    PelangganHomeScreen(key: _homeKey, showNavbar: false),
    const OrdersScreen(showNavbar: false),
    const Center(child: Text('Add Screen')),
    const ChatScreen(showNavbar: false),
    ProfileScreen(key: _profileKey, showNavbar: false),
  ];

  void _onTap(int index) {
    if (index == 2) {
      // Buka halaman Buat Pesanan Baru
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
      );
      return;
    }
    
    if (_currentIndex == 0 && index != 0) {
      _homeKey.currentState?.closeDropdown();
    }

    if (index == 0) {
      _homeKey.currentState?.reloadProfileAndServices();
    } else if (index == 4) {
      _profileKey.currentState?.reloadProfile();
    }

    setState(() {
      _currentIndex = index;
    });
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
