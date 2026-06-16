import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/hover_link_text.dart'; 
import '../../widgets/loading_overlay.dart';
import '../../widgets/bubble_background.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _errorTimer;
  bool _isAutoUsernameEnabled = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNamaChanged);
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

  // 💡 Helper Error Inline Auto-Clear
  void _showAutoClearError(String message) {
    _errorTimer?.cancel();
    setState(() {
      _errorMessage = message;
    });
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _nameController.removeListener(_onNamaChanged);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final namaLengkap = _nameController.text.trim(); 
    final noTelp = _phoneController.text.trim();

    // 1. Validasi Kosong
    if (username.isEmpty || email.isEmpty || password.isEmpty || 
        namaLengkap.isEmpty || noTelp.isEmpty) {
      _showAutoClearError(TranslationService.translate('fill_all_fields'));
      return;
    }

    // 2. Validasi Format Email Sederhana
    if (!email.contains('@') || !email.contains('.')) {
      _showAutoClearError(TranslationService.translate('email_format_invalid'));
      return;
    }

    // 3. Validasi Panjang Password (Sesuai Golang-mu)
    if (password.length < 6) {
      _showAutoClearError(TranslationService.translate('password_min_length'));
      return;
    }

    // 3.5. Validasi Panjang Nomor Telepon
    if (noTelp.length < 9 || noTelp.length > 13) {
      _showAutoClearError(TranslationService.translate('phone_length_invalid'));
      return;
    }

    // 4. Nyalakan Loading
    setState(() {
      _isLoading = true;
    });

    // 💡 5. TEMBAK API GOLANG 
    // Angka 3 berarti kita mendaftarkan user ini secara paksa sebagai Pelanggan
    final result = await AuthService.register(username, email, password, namaLengkap, noTelp, 3);
    
    // 6. Matikan Loading
    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    // 7. Evaluasi Hasil
    if (result['success'] == true) {
      String msg = result['message']?.toString() ?? "Registrasi berhasil!";
      String user = result['username']?.toString() ?? "";
      
      String pesanLengkap = "$msg ($user)";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(successMessage: pesanLengkap),
        ),
      );
    } else {
      _showAutoClearError(result['message']?.toString() ?? 'Registrasi gagal.');
    }
  }

  // Helper TextField (Tetap sama seperti aslimu)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
          floatingLabelStyle: const TextStyle(
            color: Constants.colorDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blueGrey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            // 💡 BUNGKUS DENGAN LOADING OVERLAY
            body: LoadingOverlay(
              isLoading: _isLoading,
              child: Stack(
                children: [
                  Positioned(
                    top: -250,
                    left: -100,
                    width: screenWidth * 1.5,
                    child: Image.asset('assets/images/backgrounds/bg_atas.png', fit: BoxFit.contain),
                  ),
                  Positioned(
                    bottom: -250,
                    left: -100,
                    width: screenWidth * 1.5,
                    child: Image.asset('assets/images/backgrounds/bg_bawah.png', fit: BoxFit.fitWidth),
                  ),
                  const BubbleBackground(), // Gelembung sabun animasi
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.arrow_back_ios_new, size: 16, color: Constants.colorDarkBlue),
                                        const SizedBox(width: 4),
                                        Text(
                                          TranslationService.translate('back'),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Constants.colorDarkBlue),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const Spacer(flex: 1),

                                  Row(
                                    children: [
                                      Image.asset('assets/images/brand/logo.png', height: 40),
                                      const SizedBox(width: 12),
                                      Text(
                                        TranslationService.translate('create_account'),
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Constants.colorDarkBlue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Text(
                                    TranslationService.translate('register_welcome'),
                                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                  ),
                                  const SizedBox(height: 20),

                                  // 💡 TAMPILAN ERROR INLINE AUTO-CLEAR
                                  if (_errorMessage != null)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0F0),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.redAccent.withValues(alpha:0.3), width: 1.5),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 20),

                                  _buildTextField(
                                    controller: _nameController,
                                    label: TranslationService.translate('full_name'),
                                  ),
                                  const SizedBox(height: 20),

                                  _buildTextField(
                                    controller: _usernameController,
                                    label: TranslationService.translate('username'),
                                    onChanged: (val) {
                                      if (_isAutoUsernameEnabled) {
                                        _isAutoUsernameEnabled = false;
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: TranslationService.translate('phone_number'),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  _buildTextField(
                                    controller: _emailController,
                                    label: TranslationService.translate('email'),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: TranslationService.translate('password'),
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 32),

                                  Container(
                                    width: double.infinity,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4DD0E1), Color(0xFF00BCD4)], // Primary Cyan face
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0097A7), // Dark Cyan shadow simulating the 3D edge directly
                                          blurRadius: 0,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: _isLoading ? null : _handleRegister,
                                        splashColor: Colors.white.withValues(alpha: 0.25),
                                        child: Center(
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text(
                                                  TranslationService.translate('create_account'),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  // 💡 TAUTAN SIGN IN DENGAN HOVER EFFECT
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        TranslationService.translate('already_have_account'),
                                        style: const TextStyle(
                                          fontSize: 14, 
                                          color: Colors.blueGrey
                                        ),
                                      ),
                                      HoverLinkText(
                                        text: TranslationService.translate('sign_in'),
                                        onTap: () {
                                          // 💡 Gunakan pushReplacement agar tidak menumpuk stack
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const LoginScreen()
                                            ),
                                          );
                                        },
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Constants.colorDarkBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const Spacer(flex: 2), 
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}