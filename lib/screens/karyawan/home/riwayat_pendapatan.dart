import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';

class RiwayatPendapatanScreen extends StatefulWidget {
  const RiwayatPendapatanScreen({super.key});

  @override
  State<RiwayatPendapatanScreen> createState() => _RiwayatPendapatanScreenState();
}

class _RiwayatPendapatanScreenState extends State<RiwayatPendapatanScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  int _activeFilterIndex = 0; // 0: Semua, 1: Tunai, 2: Digital

  // High-fidelity laundry revenue per completed order mock data
  final List<Map<String, dynamic>> _transactions = [
    {
      "id": "TX-90214",
      "method_type": "digital",
      "title": "Order #WW-H78F2",
      "subtitle": "Cecil Clarissa • Cuci & Setrika",
      "time": "Hari ini, 15:30",
      "amount": 48000.0,
      "payment_method": "QRIS",
    },
    {
      "id": "TX-90188",
      "method_type": "cash",
      "title": "Order #WW-K92B1",
      "subtitle": "Abilah Budi • Setrika Saja",
      "time": "Hari ini, 11:15",
      "amount": 25000.0,
      "payment_method": "Tunai",
    },
    {
      "id": "TX-89812",
      "method_type": "digital",
      "title": "Order #WW-T33G4",
      "subtitle": "Clarissa Ica • Cuci Kering Lipat",
      "time": "Kemarin, 14:20",
      "amount": 24000.0,
      "payment_method": "E-Wallet",
    },
    {
      "id": "TX-89640",
      "method_type": "digital",
      "title": "Order #WW-P11A9",
      "subtitle": "Devi Ajeng • Cuci Kering Lipat",
      "time": "22 Mei 2026, 09:10",
      "amount": 40000.0,
      "payment_method": "QRIS",
    },
    {
      "id": "TX-89510",
      "method_type": "cash",
      "title": "Order #WW-L88P3",
      "subtitle": "Budi Santoso • Cuci & Setrika",
      "time": "21 Mei 2026, 16:45",
      "amount": 32000.0,
      "payment_method": "Tunai",
    },
    {
      "id": "TX-89320",
      "method_type": "digital",
      "title": "Order #WW-N02Y1",
      "subtitle": "Andi Wijaya • Setrika Saja",
      "time": "20 Mei 2026, 13:00",
      "amount": 15000.0,
      "payment_method": "Mandiri Transfer",
    },
    {
      "id": "TX-89102",
      "method_type": "digital",
      "title": "Order #WW-F88H2",
      "subtitle": "Riana Dewi • Express Cuci & Setrika",
      "time": "18 Mei 2026, 10:15",
      "amount": 65000.0,
      "payment_method": "OVO",
    },
    {
      "id": "TX-88981",
      "method_type": "cash",
      "title": "Order #WW-Q11W9",
      "subtitle": "Hadi Prasetyo • Cuci Karpet Bedcover",
      "time": "16 Mei 2026, 14:30",
      "amount": 120000.0,
      "payment_method": "Tunai",
    },
    {
      "id": "TX-88742",
      "method_type": "digital",
      "title": "Order #WW-J32K8",
      "subtitle": "Siska Amalia • Dry Cleaning",
      "time": "15 Mei 2026, 11:00",
      "amount": 85000.0,
      "payment_method": "Gopay",
    },
    {
      "id": "TX-88510",
      "method_type": "digital",
      "title": "Order #WW-Z99M1",
      "subtitle": "Reza Pahlevi • Cuci & Setrika",
      "time": "12 Mei 2026, 16:20",
      "amount": 45000.0,
      "payment_method": "ShopeePay",
    },
    {
      "id": "TX-88122",
      "method_type": "cash",
      "title": "Order #WW-X55C4",
      "subtitle": "Mira Lestari • Setrika Saja",
      "time": "10 Mei 2026, 09:45",
      "amount": 20000.0,
      "payment_method": "Tunai",
    },
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_activeFilterIndex == 1) {
      return _transactions.where((tx) => tx['method_type'] == 'cash').toList();
    } else if (_activeFilterIndex == 2) {
      return _transactions.where((tx) => tx['method_type'] == 'digital').toList();
    }
    return _transactions;
  }

  String _formatRupiah(double value) {
    String valStr = value.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = TranslationService.currentLang == 'en';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBCEFF2),
              Color(0xFFF8FBFC),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- APP BAR LENGKAP ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: navyColor,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      isEn ? 'Revenue History' : 'Riwayat Pendapatan',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 48), // Balancing spacer
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- WALLET PREVIEW CARD MATCHING HOME SCREEN ---
                      _buildWalletCard(isEn),
                      const SizedBox(height: 28),

                      // --- SECTION TITLE ---
                      Text(
                        isEn ? 'Income History' : 'Daftar Pendapatan Masuk',
                        style: GoogleFonts.poppins(
                          color: navyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // --- SLIDING SEGMENTED CHIPS FILTER ---
                      _buildSegmentedFilters(isEn),
                      const SizedBox(height: 16),

                      // --- TRANSACTION LIST ---
                      _filteredTransactions.isEmpty
                          ? _buildEmptyState(isEn)
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = _filteredTransactions[index];
                                return _buildTransactionItem(tx);
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(bool isEn) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C4B8E),
            Color(0xFF0A3D75),
            Color(0xFF00ACC1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C4B8E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        (isEn ? 'TOTAL ACCUMULATED REVENUE' : 'TOTAL PENDAPATAN AKUMULASI').toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Rp 4.850.000,00",
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedFilters(bool isEn) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: navyColor.withOpacity(0.06), width: 1.2),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final String label = index == 0
              ? (isEn ? 'All' : 'Semua')
              : index == 1
                  ? (isEn ? 'Cash' : 'Tunai')
                  : (isEn ? 'Digital' : 'Digital');
          final isSelected = _activeFilterIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeFilterIndex = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? navyColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_chart_rounded,
              color: Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx['subtitle'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tx['time']} • ${tx['payment_method']}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${_formatRupiah(tx['amount'])}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEn) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            isEn ? 'No revenue recorded' : 'Belum ada pendapatan terekam',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
