import 'package:flutter/material.dart';
import 'package:mobile/widgets/background.dart';
import 'package:mobile/screens/karyawan/orders/pesanan_diproses.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  // Data dummy pesanan
  List<Map<String, dynamic>> pesananList = [];
  int acceptedCount = 0;

  // DEFINISI PALET WARNA SESUAI PERMINTAAN
  final Color cyanSoftColor = const Color(0xFFBCEFF2);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color navyColor = const Color(0xFF0C4B8E);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    setState(() {
      pesananList = [
        {
          'id': '1',
          'title': 'Pesanan 1',
          'nama': 'Cecil',
          'alamat': 'Mulawarman',
          'layanan': 'Cuci komplit',
          'durasi': '3 hari',
          'pengantaran': 'Delivery',
          'isExpanded': false,
        },
        {
          'id': '2',
          'title': 'Pesanan 2',
          'nama': 'Bile',
          'alamat': 'Gondang',
          'layanan': 'Cuci kering',
          'durasi': '2 hari',
          'pengantaran': 'Ambil Sendiri',
          'isExpanded': false,
        },
        {
          'id': '3',
          'title': 'Pesanan 3',
          'nama': 'Ica',
          'alamat': 'Mblancir',
          'layanan': 'Setrika',
          'durasi': '1 hari',
          'pengantaran': 'Delivery',
          'isExpanded': false,
        },
      ];
    });
  }

  void _terimaPesanan(String id) {
    setState(() {
      pesananList.removeWhere((element) => element['id'] == id);
      acceptedCount++;
    });
  }

  void _toggleExpand(int index) {
    setState(() {
      pesananList[index]['isExpanded'] = !pesananList[index]['isExpanded'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return LaundryLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan Judul
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 24.0),
            child: Row(
              children: [
                // Tombol Back Premium
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: cyanColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: cyanColor, size: 20),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, acceptedCount);
                      } else {
                        _loadInitialData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Daftar Pesanan',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: navyColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // List of Pesanan
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: pesananList.length,
              itemBuilder: (context, index) {
                final pesanan = pesananList[index];
                return _buildPesananCard(pesanan, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananCard(Map<String, dynamic> pesanan, int index) {
    final isExpanded = pesanan['isExpanded'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: cyanSoftColor, width: 2), 
        boxShadow: [
          BoxShadow(
            color: navyColor.withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekorasi air/gelembung estetik transparan di dalam card
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.water_drop_rounded,
              size: 120,
              color: cyanSoftColor.withOpacity(0.4),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Label Pesanan & Tombol Dropdown)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title dengan background pil kecil biar modern ala Dashboard
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cyanColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cyanColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 18, color: cyanColor),
                          const SizedBox(width: 8),
                          Text(
                            pesanan['title'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: navyColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tombol expand yang sangat nyatu dengan desain
                    GestureDetector(
                      onTap: () => _toggleExpand(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isExpanded ? cyanColor : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: cyanColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 20,
                          color: isExpanded ? Colors.white : cyanColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Info Section & Tombol Terima
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Detail Kiri dengan Icon
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernInfoRow(Icons.person_outline, 'Nama', pesanan['nama']),
                          const SizedBox(height: 10),
                          _buildModernInfoRow(Icons.location_on_outlined, 'Alamat', pesanan['alamat']),
                          const SizedBox(height: 10),
                          _buildModernInfoRow(Icons.local_laundry_service_outlined, 'Layanan', pesanan['layanan']),
                        ],
                      ),
                    ),
                    
                    // Tombol Terima Kanan Bawah (Gradient Palette Blue ke Navy)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [cyanColor, navyColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: navyColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _terimaPesanan(pesanan['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Terima',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Expanded Section
                if (isExpanded)
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cyanSoftColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cyanSoftColor.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            _buildModernInfoRow(Icons.timer_outlined, 'Durasi', pesanan['durasi']),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Divider(height: 1, color: cyanColor.withOpacity(0.1)),
                            ),
                            _buildModernInfoRow(Icons.delivery_dining_outlined, 'Pengantaran', pesanan['pengantaran']),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi pembuat baris info yang lebih elegan dan modern menggunakan Icon
  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cyanColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: navyColor.withOpacity(0.6), fontSize: 13),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: navyColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
