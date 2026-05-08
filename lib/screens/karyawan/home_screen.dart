import 'package:flutter/material.dart';

class KaryawanHomeScreen extends StatelessWidget {
  const KaryawanHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Karyawan'), backgroundColor: Colors.amber),
      body: const Center(child: Text('Panel Operasional Karyawan')),
    );
  }
}