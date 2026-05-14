import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/background.dart'; 
import 'package:mobile/widgets/navbar_karyawan.dart';
import 'package:mobile/screens/karyawan/home_screen.dart';
import 'package:mobile/screens/karyawan/profile.dart';

class OrderScreenKaryawan extends StatefulWidget {
  const OrderScreenKaryawan({super.key});

  @override
  State<OrderScreenKaryawan> createState() => _OrderScreenKaryawanState();
}

class _OrderScreenKaryawanState extends State<OrderScreenKaryawan> {
  // Variabel buat simpen status list-nya dibuka atau nggak
  bool _isKasirExpanded = false;
  bool _isKurirExpanded = false;

  final Color navyColor = const Color(0xFF123B6B);
  final Color tealColor = const Color(0xFF1E9A9F);

  // Data Dummy sesuai request (7 Kasir, 11 Kurir)
  final List<Map<String, String>> kasirData = List.generate(7, (i) => {
    "id": "TR00${i + 1}",
    "nama": "Pelanggan Kasir ${i + 1}",
    "layanan": "Wash & Ironing",
    "harga": "Rp 30.000",
    "status": i % 2 == 0 ? "LUNAS" : "PENDING"
  });

  final List<Map<String, String>> kurirData = List.generate(11, (i) => {
    "id": "KR00${i + 1}",
    "nama": "Pelanggan Kurir ${i + 1}",
    "layanan": i % 2 == 0 ? "PickUp" : "Delivery",
    "harga": "Rp 15.000",
    "status": i % 2 == 0 ? "PickUp" : "Delivery"
  });

  @override
  Widget build(BuildContext context) {
    return LaundryLayout(
      fab: FloatingActionButton(
        onPressed: () => showKaryawanMenu(context),
        backgroundColor: const Color(0xFF4FD1D9),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      bottomNav: NavbarKaryawan(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardKaryawan()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreenKaryawan()),
            );
          }
        },
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // --- SECTION KASIR ---
            _buildExpandableSection(
              title: "Aktivitas Kasir",
              data: kasirData,
              isExpanded: _isKasirExpanded,
              onToggle: () => setState(() => _isKasirExpanded = !_isKasirExpanded),
            ),

            const SizedBox(height: 30),

            // --- SECTION KURIR ---
            _buildExpandableSection(
              title: "Tugas Kurir",
              data: kurirData,
              isExpanded: _isKurirExpanded,
              onToggle: () => setState(() => _isKurirExpanded = !_isKurirExpanded),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Widget buat bikin Section yang bisa dibuka-tutup
  Widget _buildExpandableSection({
    required String title,
    required List<Map<String, String>> data,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    // Tentukan berapa banyak item yang mau ditampilin
    int displayCount = isExpanded ? data.length : (data.length > 3 ? 3 : data.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: navyColor.withOpacity(0.8)),
        ),
        const SizedBox(height: 12),
        // Render List Card
        ...data.take(displayCount).map((item) => _buildOrderCard(
              item['id']!,
              item['nama']!,
              item['layanan']!,
              item['harga']!,
              item['status']!,
              item['status'] == "LUNAS" ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
              item['status'] == "LUNAS" ? Colors.green : Colors.grey,
            )),
        
        // Tombol Panah di tengah bawah card terakhir
        if (data.length > 3)
          Center(
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: tealColor,
                size: 35,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderCard(String id, String nama, String layanan, String harga, String status, Color defaultStatusBg, Color defaultStatusText) {
    Color bg = defaultStatusBg;
    Color text = defaultStatusText;
    Color? border;

    if (status == "PickUp") {
      bg = const Color(0xFFFFF3A3); // Latar kuning terang
      text = const Color(0xFFD8BA1C); // Teks kuning gelap
    } else if (status == "Delivery") {
      bg = const Color(0xFFBDE0FE); // Latar biru terang
      text = const Color(0xFF0288D1); // Teks biru gelap
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(nama, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: navyColor)),
                Text(layanan, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(harga, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: tealColor)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: bg, 
                  borderRadius: BorderRadius.circular(20),
                  border: border != null ? Border.all(color: border, width: 2.0) : null,
                ),
                child: Text(status, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}