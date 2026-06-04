import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/order_service.dart';
import 'package:mobile/utils/constants.dart';
import 'dart:convert';

class RiwayatPendapatanScreen extends StatefulWidget {
  const RiwayatPendapatanScreen({super.key});

  @override
  State<RiwayatPendapatanScreen> createState() => _RiwayatPendapatanScreenState();
}

class _RiwayatPendapatanScreenState extends State<RiwayatPendapatanScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  int _activeFilterIndex = 0; // 0: Semua, 1: Tunai, 2: Digital

  List<dynamic> _realTransactions = [];
  double _accumulatedRevenue = 0.0;
  bool _isLoading = true;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchRevenueData();
  }

  Future<void> _fetchRevenueData() async {
    try {
      final response = await OrderService.getRevenueSummary(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (response['success'] == true) {
        setState(() {
          _accumulatedRevenue = (response['monthly_revenue'] as num?)?.toDouble() ?? 0.0;
          _realTransactions = response['transactions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching revenue data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getMonthYearLabel(bool isEn) {
    final monthsId = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final String monthName = isEn ? monthsEn[_selectedMonth - 1] : monthsId[_selectedMonth - 1];
    return isEn ? 'REVENUE FOR $monthName $_selectedYear' : 'PENDAPATAN $monthName $_selectedYear';
  }

  void _showMonthYearPicker() {
    final monthsId = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final isEn = TranslationService.currentLang == 'en';
    final currentMonths = isEn ? monthsEn : monthsId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int tempMonth = _selectedMonth;
        int tempYear = _selectedYear;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 340,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Select Month & Year' : 'Pilih Bulan & Tahun',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                     child: Row(
                       children: [
                         // Month Picker
                         Expanded(
                           child: ListWheelScrollView.useDelegate(
                             itemExtent: 40,
                             perspective: 0.005,
                             diameterRatio: 1.2,
                             physics: const FixedExtentScrollPhysics(),
                             controller: FixedExtentScrollController(initialItem: tempMonth - 1),
                             onSelectedItemChanged: (index) {
                               setModalState(() {
                                 tempMonth = index + 1;
                               });
                             },
                             childDelegate: ListWheelChildBuilderDelegate(
                               childCount: 12,
                               builder: (context, index) {
                                 final isSel = tempMonth == index + 1;
                                 return Center(
                                   child: Text(
                                     currentMonths[index],
                                     style: GoogleFonts.poppins(
                                       fontSize: 16,
                                       fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                       color: isSel ? navyColor : Colors.grey.shade400,
                                     ),
                                   ),
                                 );
                               },
                             ),
                           ),
                         ),
                         // Year Picker
                         Expanded(
                           child: ListWheelScrollView.useDelegate(
                             itemExtent: 40,
                             perspective: 0.005,
                             diameterRatio: 1.2,
                             physics: const FixedExtentScrollPhysics(),
                             controller: FixedExtentScrollController(
                               initialItem: tempYear - (DateTime.now().year - 5),
                             ),
                             onSelectedItemChanged: (index) {
                               setModalState(() {
                                 tempYear = (DateTime.now().year - 5) + index;
                               });
                             },
                             childDelegate: ListWheelChildBuilderDelegate(
                               childCount: 10,
                               builder: (context, index) {
                                 final yearVal = (DateTime.now().year - 5) + index;
                                 final isSel = tempYear == yearVal;
                                 return Center(
                                   child: Text(
                                     "$yearVal",
                                     style: GoogleFonts.poppins(
                                       fontSize: 16,
                                       fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                       color: isSel ? navyColor : Colors.grey.shade400,
                                     ),
                                   ),
                                 );
                               },
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedMonth = tempMonth;
                          _selectedYear = tempYear;
                          _isLoading = true;
                        });
                        _fetchRevenueData();
                      },
                      child: Text(
                        isEn ? 'Apply' : 'Terapkan',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                         ),
                       ),
                     ),
                   ),
                 ],
               ),
             );
           },
         );
       },
     );
   }

  List<dynamic> get _filteredTransactions {
    if (_activeFilterIndex == 1) {
      return _realTransactions.where((tx) => tx['method_type'] == 'cash').toList();
    } else if (_activeFilterIndex == 2) {
      return _realTransactions.where((tx) => tx['method_type'] == 'digital').toList();
    }
    return _realTransactions;
  }

  Widget _buildCustomerAvatar(String name, String photo) {
    final String initials = _getInitials(name);
    
    Widget avatarWidget;
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      avatarWidget = Image.network(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(initials),
      );
    } else if (photo.startsWith('data:image')) {
      try {
        final base64Content = photo.split(',').last;
        final bytes = base64Decode(base64Content);
        avatarWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(initials),
        );
      } catch (_) {
        avatarWidget = _buildDefaultAvatar(initials);
      }
    } else if (photo.startsWith('/uploads/')) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      avatarWidget = Image.network(
        '$staticHost$photo',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(initials),
      );
    } else if (photo.isNotEmpty) {
      avatarWidget = Image.asset(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(initials),
      );
    } else {
      avatarWidget = _buildDefaultAvatar(initials);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: avatarWidget),
    );
  }

  Widget _buildDefaultAvatar(String initials) {
    return Container(
      color: cyanColor.withOpacity(0.2),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          color: navyColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatTransactionTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final String hour = dt.hour.toString().padLeft(2, '0');
      final String minute = dt.minute.toString().padLeft(2, '0');
      
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return TranslationService.currentLang == 'en' ? 'Today, $hour:$minute' : 'Hari ini, $hour:$minute';
      } else if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
        return TranslationService.currentLang == 'en' ? 'Yesterday, $hour:$minute' : 'Kemarin, $hour:$minute';
      } else {
        final monthsId = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        final monthsEn = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final monthName = TranslationService.currentLang == 'en' ? monthsEn[dt.month - 1] : monthsId[dt.month - 1];
        return '${dt.day} $monthName ${dt.year}, $hour:$minute';
      }
    } catch (_) {
      return isoString;
    }
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
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C4B8E)),
                                ),
                              ),
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.05, 0.0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _filteredTransactions.isEmpty
                                  ? _buildEmptyState(isEn)
                                  : ListView.builder(
                                      key: ValueKey<int>(_activeFilterIndex),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _filteredTransactions.length,
                                      itemBuilder: (context, index) {
                                        final tx = _filteredTransactions[index];
                                        return _buildTransactionItem(tx);
                                      },
                                    ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            _getMonthYearLabel(isEn).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showMonthYearPicker,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _formatRupiah(_accumulatedRevenue),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double tabWidth = (totalWidth - 6) / 3; // 6 is padding (3 left + 3 right)
        
        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: navyColor.withOpacity(0.06), width: 1.2),
          ),
          child: Stack(
            children: [
              // Smooth sliding indicator background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: 3 + (_activeFilterIndex * tabWidth),
                top: 3,
                bottom: 3,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: navyColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: navyColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab labels
              Row(
                children: List.generate(3, (index) {
                  final String label = index == 0
                      ? (isEn ? 'All' : 'Semua')
                      : index == 1
                          ? (isEn ? 'Cash' : 'Tunai')
                          : (isEn ? 'Digital' : 'Digital');
                  final isSelected = _activeFilterIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _activeFilterIndex = index;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey.shade500,
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final String title = tx['title']?.toString() ?? '';
    final String subtitle = tx['subtitle']?.toString() ?? '';
    final String timeStr = _formatTransactionTime(tx['time']?.toString() ?? '');
    final String method = tx['payment_method']?.toString() ?? '';

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
          _buildCustomerAvatar(subtitle.split(' • ').first, tx['foto_pelanggan']?.toString() ?? ''),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
                  '$timeStr • $method',
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
            '+${_formatRupiah(amount)}',
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
