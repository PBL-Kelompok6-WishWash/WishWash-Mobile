import 'package:flutter/material.dart';
import 'package:mobile/widgets/background.dart';

class PesananSelesaiScreen extends StatefulWidget {
  const PesananSelesaiScreen({super.key});

  @override
  State<PesananSelesaiScreen> createState() => _PesananSelesaiScreenState();
}

class _PesananSelesaiScreenState extends State<PesananSelesaiScreen> {
  // Data dummy sesuai dengan mockup
  final List<Map<String, dynamic>> pesananSelesaiList = [
    {
      'title': 'Pesanan 1',
      'nama': 'Cecil',
      'alamat': 'Mulawarman',
      'layanan': 'Cuci komplit',
      'durasi': '3 hari',
      'pengantaran': 'Delivery',
      'berat': '5.0',
      'harga': '32500',
      'isExpanded': false,
    },
    {
      'title': 'Pesanan 2',
      'nama': 'Devi',
      'alamat': 'Gondang',
      'layanan': 'Cuci kering',
      'durasi': '2 hari',
      'pengantaran': 'Pickup',
      'berat': '3.0',
      'harga': '20000',
      'isExpanded': false,
    },
    {
      'title': 'Pesanan 3',
      'nama': 'Mark',
      'alamat': 'Mulawarman',
      'layanan': 'Cuci komplit',
      'durasi': '3 hari',
      'pengantaran': 'Delivery',
      'berat': '4.0',
      'harga': '25000',
      'isExpanded': false,
    },
    {
      'title': 'Pesanan 4',
      'nama': 'Ajeng',
      'alamat': 'Gondang',
      'layanan': 'Cuci kering',
      'durasi': '2 hari',
      'pengantaran': 'Delivery',
      'berat': '2.0',
      'harga': '15000',
      'isExpanded': false,
    },
    {
      'title': 'Pesanan 5',
      'nama': 'Anin',
      'alamat': 'Mblancir',
      'layanan': 'Cuci satuan',
      'durasi': '1 hari',
      'pengantaran': 'Pickup',
      'berat': '1.0',
      'harga': '10000',
      'isExpanded': false,
    },
    {
      'title': 'Pesanan 6',
      'nama': 'Mark',
      'alamat': 'Mulawarman',
      'layanan': 'Cuci komplit',
      'durasi': '3 hari',
      'pengantaran': 'Delivery',
      'berat': '6.0',
      'harga': '40000',
      'isExpanded': false,
    },
    {
      'title': 'Pesanan 7',
      'nama': 'Ajeng',
      'alamat': 'Gondang',
      'layanan': 'Cuci kering',
      'durasi': '2 hari',
      'pengantaran': 'Pickup',
      'berat': '2.5',
      'harga': '18000',
      'isExpanded': false,
    },
    {
      'title': 'Pesanan 8',
      'nama': 'Anin',
      'alamat': 'Mblancir',
      'layanan': 'Cuci satuan',
      'durasi': '1 hari',
      'pengantaran': 'Delivery',
      'berat': '1.5',
      'harga': '12000',
      'isExpanded': false,
    },
  ];

  // DEFINISI PALET WARNA
  final Color navyColor = const Color(0xFF123B6B);
  final Color tealColor = const Color(0xFF1E9A9F);
  final Color tengahColor = const Color(0xFF45D0D5);
  final Color blueColor = const Color(0xFF0F9CE6);

  void _toggleExpand(int index) {
    setState(() {
      pesananSelesaiList[index]['isExpanded'] = !pesananSelesaiList[index]['isExpanded'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return LaundryLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: blueColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: blueColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Pesanan Selesai',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: navyColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // List Pesanan Selesai
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: pesananSelesaiList.length,
              itemBuilder: (context, index) {
                final pesanan = pesananSelesaiList[index];
                return _buildPesananCard(pesanan, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananCard(Map<String, dynamic> pesanan, int index) {
    final bool isExpanded = pesanan['isExpanded'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        // Gradient variatif tapi tetap sesuai palet
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFE0F7FA), // Light cyan/teal
          ],
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: tealColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: navyColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(-4, 8), // Bayangan ke kiri bawah
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekorasi background air
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.water_drop_rounded,
              size: 120,
              color: tengahColor.withOpacity(0.08),
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
                    Text(
                      pesanan['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: navyColor,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
                          ),
                          child: const Text(
                            "Selesai",
                            style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _toggleExpand(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isExpanded ? blueColor : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: blueColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 20,
                              color: isExpanded ? Colors.white : blueColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Info Dasar & Peta
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernInfoRow(Icons.person_outline, 'Nama', pesanan['nama']),
                          const SizedBox(height: 8),
                          _buildModernInfoRow(Icons.location_on_outlined, 'Alamat', pesanan['alamat']),
                          const SizedBox(height: 8),
                          _buildModernInfoRow(Icons.local_laundry_service_outlined, 'Layanan', pesanan['layanan']),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Peta Miniatur
                    Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: navyColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                        image: const DecorationImage(
                          image: NetworkImage('https://maps.gstatic.com/tactile/basemap_styler/v2/map_styles/roadmap.png'), 
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on, color: Colors.redAccent, size: 24),
                      ),
                    ),
                  ],
                ),
                
                // Expanded Section (Detail Lanjutan)
                if (isExpanded)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModernInfoRow(Icons.timer_outlined, 'Durasi', pesanan['durasi']),
                            const SizedBox(height: 6),
                            _buildModernInfoRow(Icons.delivery_dining_outlined, 'Pengantaran', pesanan['pengantaran']),
                            const SizedBox(height: 6),
                            _buildModernInfoRow(Icons.monitor_weight_outlined, 'Berat', '${pesanan['berat']} Kg'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(color: Colors.black12, height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Total Harga", style: TextStyle(color: navyColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold)),
                                Text("Rp ${pesanan['harga']}", style: TextStyle(color: navyColor, fontSize: 16, fontWeight: FontWeight.w900)),
                              ],
                            ),
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

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: tengahColor),
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
                    fontSize: 13,
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
