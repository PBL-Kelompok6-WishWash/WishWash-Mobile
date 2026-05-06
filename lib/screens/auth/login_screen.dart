import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State untuk interaksi UI
  bool _obscurePassword = true;
  bool _rememberMe = false;

  void _handleLogin() {
    final username = _usernameController.text;
    final password = _passwordController.text;
    print("Mencoba login dengan Username: $username & Password: $password");
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
            color: Colors.black.withOpacity(0.03),
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
        // 💡 Mantra untuk menghilangkan fokus (menutup keyboard)
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background awan atas
            Positioned(
              top: -250,
              left: -100,
              width: screenWidth * 1.5,
              child: Image.asset(
                'assets/images/bg_atas.png',
                fit: BoxFit.contain,
              ),
            ),

            // Background awan bawah
            Positioned(
              bottom: -250,
              left: -100,
              width: screenWidth * 1.5,
              child: Image.asset(
                'assets/images/bg_bawah.png',
                fit: BoxFit.fitWidth,
              ),
            ),

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
                                  'assets/images/logo.png',
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
                            const SizedBox(height: 40),

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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.colorDarkBlue,
                                    ),
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
                                    color: Constants.colorCyan.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.colorCyan,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
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
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Constants.colorDarkBlue,
                                    ),
                                  ),
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
    );
  }
}
