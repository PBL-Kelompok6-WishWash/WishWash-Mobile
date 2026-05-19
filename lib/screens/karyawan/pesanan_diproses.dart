import 'package:flutter/material.dart';
import 'package:mobile/widgets/background.dart';

// DEFINISI PALET WARNA SESUAI PERMINTAAN
final Color tealColor = const Color(0xFFD6FAFA);
final Color tengahColor = const Color(0xFF45D0D5);
final Color blueColor = const Color(0xFF0F9CE6);
final Color navyColor = const Color(0xFF0A4D8C);

class PesananDiprosesScreen extends StatefulWidget {
  const PesananDiprosesScreen({super.key});

  @override
  State<PesananDiprosesScreen> createState() => _PesananDiprosesScreenState();
}

class _PesananDiprosesScreenState extends State<PesananDiprosesScreen> {
  List<Map<String, dynamic>> pesananList = [];
  int finishedCount = 0;

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
          'isTimbang': false,
          'isPrinted': false,
          'berat': 0.0,
          'harga': 0.0,
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
          'isTimbang': false,
          'isPrinted': false,
          'berat': 0.0,
          'harga': 0.0,
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
          'isTimbang': false,
          'isPrinted': false,
          'berat': 0.0,
          'harga': 0.0,
        },
      ];
    });
  }

  void _toggleExpand(int index) {
    setState(() {
      pesananList[index]['isExpanded'] = !pesananList[index]['isExpanded'];
    });
  }

  void _showTimbangDialog(int index) {
    TextEditingController beratCtrl = TextEditingController();
    TextEditingController hargaCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              "Input Timbangan",
              style: TextStyle(color: navyColor, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Berat", style: TextStyle(color: navyColor, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: beratCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: blueColor, width: 2),
                  ),
                  suffixText: "Kg",
                  suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: navyColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text("Harga", style: TextStyle(color: navyColor, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: hargaCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: blueColor, width: 2),
                  ),
                  prefixText: "Rp ",
                  prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: navyColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF45D0D5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text("Batal", style: TextStyle(color: Color(0xFF45D0D5), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  pesananList[index]['isTimbang'] = true;
                  pesananList[index]['berat'] = double.tryParse(beratCtrl.text) ?? 0.0;
                  pesananList[index]['harga'] = double.tryParse(hargaCtrl.text) ?? 0.0;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF45D0D5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                elevation: 0,
              ),
              child: const Text("Oke", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _navToDetailStatus(Map<String, dynamic> pesanan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusPesananScreen(
          pesanan: pesanan,
          onCetak: () {
            // Callback ketika nota selesai dicetak
            setState(() {
              final idx = pesananList.indexWhere((p) => p['id'] == pesanan['id']);
              if (idx != -1) {
                pesananList[idx]['isPrinted'] = true;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LaundryLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 24.0),
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
                Text(
                  'Pesanan Diproses',
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
    final isTimbang = pesanan['isTimbang'];
    final isPrinted = pesanan['isPrinted'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFF1F5F9), const Color(0xFFD9E2EC)], // Agak gelap (Slate/Blue-Grey)
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: navyColor.withOpacity(0.08),
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
                // Header (Label Pesanan | Belum Dibayar & Tombol Dropdown)
                Row(
                  children: [
                    // Title
                    Text(
                      pesanan['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: navyColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(width: 2, height: 16, color: Colors.grey.shade400),
                    ),
                    const Text(
                      "Belum dibayar",
                      style: TextStyle(
                        color: Colors.redAccent, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 13
                      ),
                    ),
                    const Spacer(),
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
                
                // Teks "Lihat detail"
                if (isTimbang)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: GestureDetector(
                      onTap: () => _navToDetailStatus(pesanan),
                      child: const Text(
                        "Lihat detail",
                        style: TextStyle(
                          color: Color(0xFF0F9CE6),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Info Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detail Kiri
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
                    
                    // Tombol Timbang & Selesai di sebelah Kanan
                    Column(
                      children: [
                        if (!isTimbang)
                          OutlinedButton(
                            onPressed: () => _showTimbangDialog(index),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: blueColor, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(90, 36),
                            ),
                            child: Text(
                              "Timbang",
                              style: TextStyle(fontWeight: FontWeight.bold, color: blueColor),
                            ),
                          ),
                        if (!isTimbang) const SizedBox(height: 8),
                        
                        // Tombol Selesai (Aktif jika isPrinted = true)
                        ElevatedButton(
                          onPressed: isPrinted ? () {
                            setState(() {
                              pesananList.removeWhere((p) => p['id'] == pesanan['id']);
                              finishedCount++;
                            });
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPrinted ? const Color(0xFF16A34A) : Colors.grey.shade400,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(90, 36),
                            elevation: 0,
                          ),
                          child: Text(
                            "Selesai",
                            style: TextStyle(fontWeight: FontWeight.bold, color: isPrinted ? Colors.white : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Expanded Section
                if (isExpanded)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildModernInfoRow(Icons.person_outline, 'Nama', pesanan['nama']),
                                  const SizedBox(height: 4),
                                  _buildModernInfoRow(Icons.location_on_outlined, 'Alamat', pesanan['alamat']),
                                  const SizedBox(height: 4),
                                  _buildModernInfoRow(Icons.local_laundry_service_outlined, 'Layanan', pesanan['layanan']),
                                  const SizedBox(height: 4),
                                  _buildModernInfoRow(Icons.timer_outlined, 'Durasi', pesanan['durasi']),
                                  const SizedBox(height: 4),
                                  _buildModernInfoRow(Icons.delivery_dining_outlined, 'Pengantaran', pesanan['pengantaran']),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Gambar / Image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image, color: Colors.grey, size: 40),
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

// ==========================================
// SCREEN: DETAIL STATUS PESANAN (TIMELINE)
// ==========================================
class StatusPesananScreen extends StatefulWidget {
  final Map<String, dynamic> pesanan;
  final VoidCallback onCetak;

  const StatusPesananScreen({super.key, required this.pesanan, required this.onCetak});

  @override
  State<StatusPesananScreen> createState() => _StatusPesananScreenState();
}

class _StatusPesananScreenState extends State<StatusPesananScreen> {
  int currentStep = 0; // 0: Pick Up, 1: Iron, 2: Fold, 3: In Store

  final List<String> steps = ["Pick Up", "Iron", "Fold", "In Store"];

  @override
  void initState() {
    super.initState();
    // Jika pesanan sudah pernah dicetak, statusnya pasti sudah sampai akhir (3)
    if (widget.pesanan['isPrinted'] == true) {
      currentStep = 3;
    }
  }

  void _showBarcodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo/Header Struk
              const Icon(Icons.receipt_long, size: 40, color: Color(0xFF0F9CE6)),
              const SizedBox(height: 12),
              const Text(
                "Wish Wash Laundry",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const Text(
                "Jl. Tembalang No. 17, Kota Semarang",
                style: TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Barcode Placeholder
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/UPC-A-036000291452.svg/1200px-UPC-A-036000291452.svg.png',
                      height: 50,
                      width: 200,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_2, size: 50),
                    ),
                    const SizedBox(height: 8),
                    const Text("(00)123456789101112133", style: TextStyle(fontSize: 10, letterSpacing: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Details Struk yang Rapih
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow("Atas Nama", widget.pesanan['nama']),
                    _buildReceiptRow("Layanan", widget.pesanan['layanan']),
                    _buildReceiptRow("Durasi", widget.pesanan['durasi']),
                    _buildReceiptRow("Pengantaran", widget.pesanan['pengantaran']),
                    _buildReceiptRow("Berat", "${widget.pesanan['berat']} kg"),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Colors.black26), // Garis pembatas
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text("Rp ${widget.pesanan['harga'].toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F9CE6))),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tombol Cetak
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 1. Panggil Callback untuk update state isPrinted di halaman awal
                    widget.onCetak();
                    // 2. Tutup dialog dan kembali ke layar pesanan
                    Navigator.pop(context); // Tutup dialog
                    Navigator.pop(context); // Tutup layar tracking status
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF45D0D5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text("Cetak & Selesaikan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Fungsi Helper untuk baris detail struk agar rapi
  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LaundryLayout(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 24.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: blueColor.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: blueColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Kartu Kuning (Order Tracking)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3), // Soft Yellow
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: navyColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order #${widget.pesanan['id']}231",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF854D0E)), // Dark yellow/brown
                      ),
                      const Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Color(0xFF991B1B)),
                          SizedBox(width: 4),
                          Text("Est: 15 April 2026", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF991B1B))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.pesanan['layanan'],
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF854D0E)),
                  ),
                  const SizedBox(height: 30),

                  // Timeline (Horizontal)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(steps.length, (index) {
                      bool isCompleted = index <= currentStep;
                      return Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Line left
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    color: index == 0 ? Colors.transparent : const Color(0xFF854D0E),
                                  ),
                                ),
                                // Circle Button
                                IgnorePointer(
                                  ignoring: widget.pesanan['isPrinted'] == true,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (widget.pesanan['isPrinted'] == true) return;
                                      setState(() => currentStep = index);
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isCompleted ? const Color(0xFF854D0E) : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF854D0E), width: 2),
                                      ),
                                      child: isCompleted
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF854D0E), shape: BoxShape.circle))),
                                    ),
                                  ),
                                ),
                                // Line right
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    color: index == steps.length - 1 ? Colors.transparent : const Color(0xFF854D0E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              steps[index],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF854D0E)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Tombol Cetak Nota
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: currentStep == 3 ? _showBarcodeDialog : null, // Hanya aktif jika sudah In Store (step 3)
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentStep == 3 ? Colors.white : Colors.white.withOpacity(0.5),
                        foregroundColor: const Color(0xFF854D0E),
                        elevation: currentStep == 3 ? 2 : 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Cetak Nota",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // Kartu Abu-abu Detail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: navyColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Nama: ${widget.pesanan['nama']}", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Alamat: ${widget.pesanan['alamat']}", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Layanan: ${widget.pesanan['layanan']}", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Durasi: ${widget.pesanan['durasi']}", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Jenis Pengantaran: ${widget.pesanan['pengantaran']}", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Berat: ${widget.pesanan['berat']} Kg", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Harga: Rp ${widget.pesanan['harga'].toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  // Image Placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag, color: Colors.grey, size: 40),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
