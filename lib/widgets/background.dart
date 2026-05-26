import 'package:flutter/material.dart';
import 'dart:ui';

class LaundryLayout extends StatelessWidget {
  final Widget child;
  // 1. Tambahin variabel buat nampung FAB dan BottomNav
  final Widget? fab; 
  final Widget? bottomNav;

  // 2. Update constructor-nya biar dia kenal sama 'fab' dan 'bottomNav'
  const LaundryLayout({
    super.key, 
    required this.child, 
    this.fab, 
    this.bottomNav
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Stack(
        children: [
          Container(color: Colors.white),
          // Blob Kanan Atas
          Positioned(
            top: -50,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF4FD1D9).withOpacity(0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blob Kiri Bawah
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: const Color(0xFF4FD1D9).withOpacity(0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Efek Blur biar estetik
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(child: child),
          if (bottomNav != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: bottomNav!,
            ),
        ],
      ),
    );
  }
}