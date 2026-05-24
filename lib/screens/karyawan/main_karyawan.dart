import 'package:flutter/material.dart';
import 'package:mobile/widgets/background.dart';
import 'package:mobile/widgets/navbar_karyawan.dart';
import 'home_screen.dart';
import 'orders.dart';
import 'profile.dart';
import 'chat/chat_screen.dart';

class MainKaryawan extends StatefulWidget {
  final int initialIndex;
  const MainKaryawan({super.key, this.initialIndex = 0});

  @override
  State<MainKaryawan> createState() => _MainKaryawanState();
}

class _MainKaryawanState extends State<MainKaryawan> {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      DashboardKaryawan(onProfileTap: () => _onTap(4)),
      const OrderScreenKaryawan(),
      const SizedBox(), // Placeholder for + button
      const KaryawanChatScreen(),
      const ProfileScreenKaryawan(),
    ];
  }

  void _onTap(int index) {
    if (index == 2) {
      showKaryawanMenu(context);
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LaundryLayout(
      bottomNav: NavbarKaryawan(currentIndex: _currentIndex, onTap: _onTap),
      child: IndexedStack(index: _currentIndex, children: _pages),
    );
  }
}
