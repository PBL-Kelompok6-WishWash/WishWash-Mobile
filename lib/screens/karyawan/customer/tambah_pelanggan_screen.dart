import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/widgets/custom_dialog.dart';

class TambahPelangganScreen extends StatefulWidget {
  const TambahPelangganScreen({super.key});

  @override
  State<TambahPelangganScreen> createState() => _TambahPelangganScreenState();
}

class _TambahPelangganScreenState extends State<TambahPelangganScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _isAutoUsernameEnabled = true;

  @override
  void initState() {
    super.initState();
    // Auto-generate username from full name dynamically
    _nameController.addListener(_onNamaChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNamaChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onNamaChanged() {
    if (!_isAutoUsernameEnabled) return;
    
    final String text = _nameController.text.trim().toLowerCase();
    if (text.isEmpty) {
      _usernameController.text = '';
      return;
    }
    
    // Replace spaces and special characters with underscore
    final String generated = text
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
        
    _usernameController.text = generated;
  }

  Widget _buildInputLabel(String label, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: navyColor.withOpacity(0.8),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: navyColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cyanColor, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _handleDaftarPelanggan() async {
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // 1. Full Name Validation
    if (name.isEmpty) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Full name cannot be empty' 
            : 'Nama lengkap tidak boleh kosong',
      );
      return;
    }
    if (name.length < 2) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Full name must be at least 2 characters' 
            : 'Nama lengkap minimal harus 2 karakter',
      );
      return;
    }

    // 2. Username Validation
    if (username.isEmpty) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Username cannot be empty' 
            : 'Username tidak boleh kosong',
      );
      return;
    }
    if (username.contains(' ')) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Username cannot contain spaces' 
            : 'Username tidak boleh mengandung spasi',
      );
      return;
    }
    if (username.length < 3) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Username must be at least 3 characters' 
            : 'Username minimal harus 3 karakter',
      );
      return;
    }

    // 3. Email Validation
    if (email.isEmpty) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Email address cannot be empty' 
            : 'Email tidak boleh kosong',
      );
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Please enter a valid email address' 
            : 'Format email tidak valid (harus mengandung @ dan domain)',
      );
      return;
    }

    // 4. Phone Number Validation
    if (phone.isEmpty) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Phone number cannot be empty' 
            : 'Nomor telepon tidak boleh kosong',
      );
      return;
    }
    if (phone.length < 9 || phone.length > 13) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Phone number must be between 9 and 13 digits' 
            : 'Nomor telepon harus berukuran antara 9 sampai 13 digit',
      );
      return;
    }

    // 5. Password Validation
    if (password.isEmpty) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Password cannot be empty' 
            : 'Password tidak boleh kosong',
      );
      return;
    }
    if (password.length < 8) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Password must be at least 8 characters' 
            : 'Password minimal harus 8 karakter',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await AuthService.register(
        username,
        email,
        password,
        name,
        phone,
        3, // Role ID 3 for Pelanggan
      );

      setState(() {
        _isSaving = false;
      });

      if (result['success'] == true) {
        if (mounted) {
          // Success Dialog
          await CustomDialog.showSuccess(
            context: context,
            title: TranslationService.currentLang == 'en' ? 'Success' : 'Berhasil',
            message: TranslationService.currentLang == 'en'
                ? 'Customer $name registered successfully!'
                : 'Pelanggan $name berhasil didaftarkan!',
          );
          if (mounted) {
            Navigator.pop(context); // Close screen
          }
        }
      } else {
        if (mounted) {
          final String errMsg = result['message'] ?? 'Gagal mendaftarkan pelanggan';
          CustomDialog.showError(
            context: context,
            title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
            message: errMsg,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        CustomDialog.showError(
          context: context,
          title: TranslationService.currentLang == 'en' ? 'Error' : 'Kesalahan',
          message: 'Koneksi internet bermasalah: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        final isEn = TranslationService.currentLang == 'en';
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2),
          body: Column(
            children: [
              // --- HEADER & APPBAR (Matching Edit Profile Design) ---
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        isEn ? 'Add New Customer' : 'Tambah Pelanggan Baru',
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
              ),
              const SizedBox(height: 10),

              // --- CONTENT CONTAINER SHEET (Matching Edit Profile Design) ---
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
                        color: Colors.black.withOpacity(0.08),
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
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Nama Lengkap
                          _buildInputLabel(isEn ? 'Full Name' : 'Nama Lengkap'),
                          _buildTextField(
                            _nameController,
                            isEn ? 'Enter customer full name' : 'Nama lengkap pelanggan...',
                            Icons.person_outline_rounded,
                          ),

                          // 2. Username
                          _buildInputLabel(
                            'Username',
                            trailing: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAutoUsernameEnabled = !_isAutoUsernameEnabled;
                                  if (_isAutoUsernameEnabled) {
                                    _onNamaChanged();
                                  }
                                });
                              },
                              child: Text(
                                _isAutoUsernameEnabled 
                                    ? (isEn ? 'Manual Type' : 'Ketik Manual') 
                                    : 'Auto-Generate',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cyanColor,
                                ),
                              ),
                            ),
                          ),
                          _buildTextField(
                            _usernameController,
                            isEn ? 'Enter username' : 'username_pelanggan...',
                            Icons.alternate_email_rounded,
                            onChanged: (val) {
                              if (_isAutoUsernameEnabled) {
                                setState(() {
                                  _isAutoUsernameEnabled = false;
                                });
                              }
                            },
                          ),

                          // 3. Email
                          _buildInputLabel('Email'),
                          _buildTextField(
                            _emailController,
                            isEn ? 'Enter email address' : 'alamat_email@mail.com...',
                            Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          // 4. Nomor Telepon / HP
                          _buildInputLabel(isEn ? 'Phone Number' : 'Nomor Telepon'),
                          _buildTextField(
                            _phoneController,
                            isEn ? 'Enter phone number' : '0812345678...',
                            Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),

                          // 5. Password Akun
                          _buildInputLabel(isEn ? 'Password' : 'Password Akun'),
                          _buildTextField(
                            _passwordController,
                            isEn ? 'Min. 8 characters' : 'Password minimal 8 karakter...',
                            Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade500,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Save/Submit Button (Matching Edit Profile Design)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [cyanColor, const Color(0xFF00ACC1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cyanColor.withOpacity(0.4),
                                    offset: const Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _isSaving ? null : _handleDaftarPelanggan,
                                  child: Center(
                                    child: _isSaving
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                            isEn ? 'Add Customer Account' : 'Daftarkan Akun Pelanggan',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
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
