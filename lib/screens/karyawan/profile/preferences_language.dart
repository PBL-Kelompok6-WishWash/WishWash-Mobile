import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/translation_service.dart';

class PreferencesLanguageScreenKaryawan extends StatefulWidget {
  const PreferencesLanguageScreenKaryawan({super.key});

  @override
  State<PreferencesLanguageScreenKaryawan> createState() => _PreferencesLanguageScreenKaryawanState();
}

class _PreferencesLanguageScreenKaryawanState extends State<PreferencesLanguageScreenKaryawan> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);

  // Preference states
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('pref_push_notif') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showTermsDialog() {
    final isEn = TranslationService.currentLang == 'en';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Terms of Service' : 'Syarat & Ketentuan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      isEn
                          ? 'Welcome to WishWash. By using our laundry application, you agree to comply with and be bound by the following terms:\n\n'
                              '1. Order Placement: Orders are processed based on the details submitted in the app.\n'
                              '2. Services: We offer wash, dry, fold, and ironing services with professional care.\n'
                              '3. Payments: All transactions are secure and must be completed online or via cash on delivery if available.\n'
                              '4. Damage Policy: Any claims regarding fabric damage must be submitted within 24 hours of delivery.\n\n'
                              'Thank you for washing with WishWash!'
                          : 'Selamat datang di WishWash. Dengan menggunakan layanan aplikasi laundry kami, Anda menyetujui ketentuan berikut:\n\n'
                              '1. Pemesanan: Pesanan diproses berdasarkan data detail yang Anda kirimkan lewat aplikasi.\n'
                              '2. Layanan: Kami menyediakan jasa cuci, pengeringan, lipat, dan setrika dengan penanganan profesional.\n'
                              '3. Pembayaran: Semua pembayaran harus diselesaikan via transfer/metode online aman atau COD jika tersedia.\n'
                              '4. Kebijakan Kerusakan: Klaim mengenai kerusakan pakaian harus dilaporkan maksimal 24 jam setelah pengantaran.\n\n'
                              'Terima kasih telah menggunakan jasa WishWash!',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isEn ? 'Close' : 'Tutup',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    final isEn = TranslationService.currentLang == 'en';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Privacy Policy' : 'Kebijakan Privasi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      isEn
                          ? 'Your privacy is important to us. This privacy policy explains how WishWash collects, uses, and protects your personal data:\n\n'
                              '1. Information Collection: We collect name, phone number, and delivery addresses to process your laundry order.\n'
                              '2. Usage: Your location data is used strictly for pickup and delivery routing by our couriers.\n'
                              '3. Data Security: We implement encryption and secure servers to protect your credentials.\n'
                              '4. Third Parties: We do not share your private data with third parties for commercial use.'
                          : 'Privasi Anda sangat penting bagi kami. Kebijakan privasi ini menjelaskan bagaimana WishWash mengumpulkan, menggunakan, dan melindungi data pribadi Anda:\n\n'
                              '1. Pengumpulan Informasi: Kami mengumpulkan nama, no. HP, dan alamat pengantaran untuk memproses pesanan laundry Anda.\n'
                              '2. Penggunaan Data: Koordinat lokasi Anda digunakan khusus untuk proses jemput-antar pakaian oleh kurir kami.\n'
                              '3. Keamanan Data: Kami menggunakan server terenkripsi untuk mengamankan data akun dan transaksi Anda.\n'
                              '4. Pihak Ketiga: Kami tidak menjual atau membagikan data pribadi Anda kepada pihak luar untuk iklan.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isEn ? 'Close' : 'Tutup',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: navyColor.withValues(alpha: 0.6),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required String title,
    required String code,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? cyanColor : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: navyColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: cyanColor, size: 22)
                else
                  Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cyanColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: cyanColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Custom Switch: border cyan, warna dasar putih, thumb cyan
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 26,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: value ? cyanColor : Colors.grey.shade300,
                      width: 2.0,
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: value ? cyanColor : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClickableTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cyanColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: cyanColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: navyColor,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        final isEn = lang == 'en';
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2),
          extendBody: true,
          body: Column(
            children: [
              // --- HEADER & APPBAR ---
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            TranslationService.translate('preferences'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer to balance layout
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              
              // --- KONTEN UTAMA (Sheet Putih) ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFC),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(TranslationService.translate('language_bahasa')),
                          _buildLanguageTile(
                            title: 'English (US)',
                            code: 'en',
                            flag: '🇺🇸',
                            isSelected: lang == 'en',
                            onTap: () {
                              TranslationService.setLanguage('en');
                            },
                          ),
                          _buildLanguageTile(
                            title: 'Bahasa Indonesia',
                            code: 'id',
                            flag: '🇮🇩',
                            isSelected: lang == 'id',
                            onTap: () {
                              TranslationService.setLanguage('id');
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildSectionHeader(TranslationService.translate('notifications')),
                          _buildSwitchTile(
                            title: TranslationService.translate('push_notif'),
                            subtitle: TranslationService.translate('push_notif_sub'),
                            icon: Icons.notifications_none_rounded,
                            value: _pushNotifications,
                            onChanged: (val) {
                              setState(() => _pushNotifications = val);
                              _savePreference('pref_push_notif', val);
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildSectionHeader(isEn ? 'Information' : 'Informasi'),
                          _buildClickableTile(
                            title: isEn ? 'Terms of Service' : 'Syarat & Ketentuan',
                            icon: Icons.description_outlined,
                            onTap: _showTermsDialog,
                          ),
                          _buildClickableTile(
                            title: isEn ? 'Privacy Policy' : 'Kebijakan Privasi',
                            icon: Icons.security_outlined,
                            onTap: _showPrivacyDialog,
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              'WishWash v1.0.0',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade400,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
