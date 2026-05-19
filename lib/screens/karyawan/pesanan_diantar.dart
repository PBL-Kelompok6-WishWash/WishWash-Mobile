import 'package:flutter/material.dart';
import 'package:mobile/widgets/background.dart';

// PALET WARNA — samain sama profile
const Color _navy = Color(0xFF123B6B);
const Color _teal = Color(0xFF1E9A9F);
const Color _tealLight = Color(0xFFD6FAFA);

class PesananDiantarScreen extends StatefulWidget {
  final bool initialIsPickup;
  const PesananDiantarScreen({super.key, this.initialIsPickup = true});

  @override
  State<PesananDiantarScreen> createState() => _PesananDiantarScreenState();
}

class _PesananDiantarScreenState extends State<PesananDiantarScreen> {
  bool isPickupTab = true;
  int finishedCount = 0;

  List<Map<String, dynamic>> pickupList = [];
  List<Map<String, dynamic>> deliveryList = [];

  @override
  void initState() {
    super.initState();
    isPickupTab = widget.initialIsPickup;
    _loadInitialData();
  }

  void _loadInitialData() {
    setState(() {
      pickupList = [
        {
          'id': '1',
          'nama': 'Cecil',
          'alamat': 'Mulawarman',
          'layanan': 'Cuci Komplit',
          'dibuat': '07.00 (21 - 04 - 2025)',
          'tipe': 'Pickup Now',
          'durasi': '3 hari',
          'berat': 5.0,
          'harga': 32500,
        },
        {
          'id': '2',
          'nama': 'Bile',
          'alamat': 'Gondang',
          'layanan': 'Cuci Kering',
          'dibuat': '08.00 (21 - 04 - 2025)',
          'tipe': 'Pickup Now',
          'durasi': '2 hari',
          'berat': 3.0,
          'harga': 20000,
        }
      ];

      deliveryList = [
        {
          'id': '3',
          'nama': 'Ica',
          'alamat': 'Mblancir',
          'layanan': 'Setrika',
          'dibuat': '09.00 (21 - 04 - 2025)',
          'tipe': 'COD Now',
          'durasi': '3 hari',
          'berat': 5.0,
          'harga': 32500,
        },
        {
          'id': '4',
          'nama': 'Joko',
          'alamat': 'Banyumanik',
          'layanan': 'Cuci Komplit',
          'dibuat': '10.00 (21 - 04 - 2025)',
          'tipe': 'Delivery Now',
          'durasi': '2 hari',
          'berat': 3.0,
          'harga': 45000,
        }
      ];
    });
  }

  void _navigateToMap(Map<String, dynamic> pesanan, bool isPickup) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapTrackingScreen(
          pesanan: pesanan,
          isPickup: isPickup,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        if (isPickup) {
          pickupList.removeWhere((p) => p['id'] == pesanan['id']);
        } else {
          deliveryList.removeWhere((p) => p['id'] == pesanan['id']);
        }
        finishedCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = isPickupTab ? pickupList : deliveryList;

    return LaundryLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 10.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: _navy, size: 24),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, finishedCount);
                      } else {
                        _loadInitialData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _navy.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: _navy.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: _teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search",
                              hintStyle: TextStyle(color: _navy.withOpacity(0.4)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isPickupTab = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isPickupTab ? _teal : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isPickupTab
                            ? [BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                            : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Center(
                        child: Text(
                          "Pickup",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isPickupTab ? Colors.white : _navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isPickupTab = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !isPickupTab ? _teal : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: !isPickupTab
                            ? [BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                            : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Center(
                        child: Text(
                          "Delivery",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: !isPickupTab ? Colors.white : _navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List Pesanan
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                return _buildCard(currentList[index], isPickupTab);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> pesanan, bool isPickup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _teal.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.water_drop_rounded, size: 120, color: _teal.withOpacity(0.06)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _teal.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 16, color: _teal),
                      const SizedBox(width: 8),
                      Text(
                        pesanan['nama'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _navy,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.location_on_outlined, 'Alamat', pesanan['alamat']),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.local_laundry_service_outlined, 'Layanan', pesanan['layanan']),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.schedule, 'Dibuat', pesanan['dibuat']),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Container(
                          width: 90,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _tealLight,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: _navy.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(size: const Size(90, 50), painter: _SimpleMapPainter()),
                              const Icon(Icons.location_on, color: Colors.redAccent, size: 28),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: () => _navigateToMap(pesanan, isPickup),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navy,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                            ),
                            child: Text(
                              pesanan['tipe'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: _navy.withOpacity(0.5), fontSize: 13),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _navy, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SCREEN: MAP TRACKING
// ==========================================
class MapTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> pesanan;
  final bool isPickup;

  const MapTrackingScreen({super.key, required this.pesanan, required this.isPickup});

  void _onBottomButtonPressed(BuildContext context) async {
    if (isPickup) {
      _showPickupSelesaiDialog(context);
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MockScannerScreen()),
      );
      if (result == true) _showDeliverySelesaiDialog(context);
    }
  }

  void _showDeliverySelesaiDialog(BuildContext context) {
    String titleText = pesanan['tipe'].toString().contains("COD") ? "COD selesai" : "Delivery selesai";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _teal,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 50, color: _teal),
            ),
            const SizedBox(height: 20),
            Text(titleText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogTextRow("Nama", pesanan['nama']),
                        _buildDialogTextRow("Alamat", pesanan['alamat']),
                        _buildDialogTextRow("Layanan", pesanan['layanan']),
                        _buildDialogTextRow("Durasi", pesanan['durasi'] ?? "3 hari"),
                        _buildDialogTextRow("Jenis", "\n${pesanan['tipe'].toString().replaceAll(" Now", "")}"),
                        _buildDialogTextRow("Berat", "${pesanan['berat'] ?? 5} Kg"),
                        _buildDialogTextRow("Harga", "Rp ${pesanan['harga'] ?? 32500}"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: NetworkImage('https://plus.unsplash.com/premium_photo-1678385311090-e8b919bb1dcd?q=80&w=200&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context, true); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Text("$label: $value", style: const TextStyle(fontSize: 11, color: Colors.black87)),
    );
  }

  void _showPickupSelesaiDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _teal,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 50, color: _teal),
            ),
            const SizedBox(height: 20),
            const Text("Pickup selesai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildDialogRow("Nama", pesanan['nama']),
                  _buildDialogRow("Alamat", pesanan['alamat']),
                  _buildDialogRow("Layanan", pesanan['layanan']),
                  _buildDialogRow("Selesai", "07.00 (21 - 04 - 2025)"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context, true); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$label : ", style: const TextStyle(fontWeight: FontWeight.w900, color: _navy, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: _navy.withOpacity(0.6), fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: _tealLight,
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(painter: _FullMapDummyPainter()),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPickup ? "1 hr 48 min" : "2 hr 10 min",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text("Rp 94.500,00", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: _navy,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onBottomButtonPressed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    child: Text(
                      isPickup ? "Konfirmasi Selesai" : "Scan untuk konfirmasi",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN: MOCK SCANNER
// ==========================================
class MockScannerScreen extends StatelessWidget {
  const MockScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Scan Barcode Delivery", style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: _teal, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  "Arahkan kamera ke nota/barcode\npelanggan untuk konfirmasi",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "Simulasikan Berhasil Scan ✅",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HELPER PAINTERS
// ==========================================
class _SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _teal.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.3)
      ..moveTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width * 0.6, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FullMapDummyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = _teal
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width, size.height * 0.9);

    canvas.drawPath(path, roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width * 0.5, size.height * 0.5), minorRoadPaint);
    canvas.drawLine(Offset(size.width * 0.8, size.height * 0.8), Offset(size.width * 0.9, size.height), minorRoadPaint);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.3), Offset(size.width, size.height * 0.2), minorRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
