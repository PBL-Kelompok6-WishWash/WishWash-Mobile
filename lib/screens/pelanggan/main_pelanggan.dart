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

  final List<Widget> _pages = [
    const PelangganHomeScreen(showNavbar: false),
    const OrdersScreen(showNavbar: false),
    const Center(child: Text('Add Screen')),    // Placeholder for Plus Action
    const ChatScreen(showNavbar: false),
    const ProfileScreen(showNavbar: false),
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
