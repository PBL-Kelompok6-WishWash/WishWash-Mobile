import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'register_screen.dart';
import '../pelanggan/main_pelanggan.dart';
import '../karyawan/main_karyawan.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/hover_link_text.dart';
import '../../widgets/bubble_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  final String? successMessage; 

  const LoginScreen({super.key, this.successMessage});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State untuk interaksi UI
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _errorTimer;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Langsung tangkap pesan dari halaman Register (jika ada) saat halaman dibuka
    if (widget.successMessage != null) {
      _successMessage = widget.successMessage;
      
      // Pasang timer untuk menghilangkan kotak hijau setelah 5 detik
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    }

    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool('remember_me') ?? false;
    if (isRemembered) {
      final savedUsername = prefs.getString('saved_username') ?? '';
      final savedPassword = prefs.getString('saved_password') ?? '';
      if (mounted) {
        setState(() {
          _rememberMe = true;
          _usernameController.text = savedUsername;
          _passwordController.text = savedPassword;
        });
      }
    }
  }

  void _showAutoClearError(String message) {
    // Batalkan timer sebelumnya jika user spam klik tombol
    _errorTimer?.cancel();

    setState(() {
      _errorMessage = message;
    });

    // Mulai timer 3 detik
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null; // Kosongkan error setelah 3 detik
        });
      }
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Reset pesan error setiap kali tombol Sign In ditekan
    setState(() {
      _errorMessage = null;
    });

    // A. Validasi kosong
    if (username.isEmpty || password.isEmpty) {
      _showAutoClearError('Oops! Username dan Password wajib diisi ya.');
      return;
    }

    // B. Nyalakan loading
    setState(() {
      _isLoading = true;
    });

    // C. Tembak API Golang
    final result = await AuthService.login(username, password);

    // D. Matikan loading
    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    // E. Evaluasi hasil dari Golang
    if (result['success']) {
      final int roleId = result['id_role'];

      // Save or clear Remember Me data
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
      }

      if (!mounted) return;

      if (roleId == 2) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainKaryawan()),
          (route) => false,
        );
      } else if (roleId == 3){
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainPelanggan()),
          (route) => false,
        );
      }
    } else {
      // F. Tampilkan error Golang secara inline dan auto-clear
      _showAutoClearError(result['message']);
    }
  }

  // Helper membuat TextField dengan shadow Neumorphism
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
          floatingLabelStyle: const TextStyle(
            color: Constants.colorDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: Stack(
            children: [
              // Background awan atas
              Positioned(
                top: -250,
                left: -100,
                width: screenWidth * 1.5,
                child: Image.asset(
                  'assets/images/backgrounds/bg_atas.png',
                  fit: BoxFit.contain,
                ),
              ),

              // Background awan bawah
              Positioned(
                bottom: -250,
                left: -100,
                width: screenWidth * 1.5,
                child: Image.asset(
                  'assets/images/backgrounds/bg_bawah.png',
                  fit: BoxFit.fitWidth,
                ),
              ),

              const BubbleBackground(), // Gelembung sabun animasi

              // Konten form login responsif
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints
                              .maxHeight, // Memastikan tinggi minimal sama dengan layar
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              // Tombol kembali
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 16,
                                      color: Constants.colorDarkBlue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Back',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Constants.colorDarkBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Pengganti SizedBox statis 130
                              const Spacer(flex: 1),

                              // Header Logo & Teks Sign In
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/brand/logo.png',
                                    height: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Constants.colorDarkBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Subtitle
                              const Text(
                                'Welcome! Please sign in to your account.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity, // Sepanjang textfield
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(
                                      16,
                                    ), // Samakan dengan textfield
                                    border: Border.all(
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              else if (_successMessage != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF0FFF4,
                                    ), // Hijau pastel
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    _successMessage!,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 20),

                              // Form Input Username
                              _buildTextField(
                                controller: _usernameController,
                                label: 'Username',
                              ),
                              const SizedBox(height: 20),

                              // Form Input Password
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                isPassword: true,
                              ),
                              const SizedBox(height: 16),

                              // Baris Remember me & Forgot Password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: Constants.colorCyan,
                                          side: const BorderSide(
                                            color: Colors.blueGrey,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  HoverLinkText(
                                    text: 'Forgot Password?',
                                    onTap: () {
                                      //  Aksi saat lupa password
                                    },
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.colorDarkBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Tombol Sign In
                              Container(
                                width: double.infinity,
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Constants.colorCyan.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  // Matikan tombol jika sedang loading
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Constants.colorCyan,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  // Ganti teks dengan animasi loading
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Tautan Create Account
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  HoverLinkText(
                                    text: "Create Account",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Constants.colorDarkBlue,
                                    ),
                                    onTap: () async {
                                      //  1. Tunggu user kembali dari halaman Register
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );

                                      //  2. Tangkap pesan suksesnya (jika ada)
                                      if (result != null && mounted) {
                                        setState(() {
                                          _successMessage = result.toString();
                                          _errorMessage =
                                              null; // Hapus error merah jika ada
                                        });

                                        //  3. Hilangkan pesan sukses otomatis setelah 5 detik
                                        Timer(const Duration(seconds: 5), () {
                                          if (mounted) {
                                            setState(() {
                                              _successMessage = null;
                                            });
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),

                              // Pengganti SizedBox statis 300
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
  }
}
