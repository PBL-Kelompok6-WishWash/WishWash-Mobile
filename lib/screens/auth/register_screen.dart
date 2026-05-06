import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _handleRegister() {
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    print("Mencoba daftar dengan Username: $username, Email: $email & Password: $password");
  }

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

    return GestureDetector(
      onTap: () {
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

            // Konten form register responsif
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
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
                                  Icon(Icons.arrow_back_ios_new, size: 16, color: Constants.colorDarkBlue),
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
                            
                            const Spacer(flex: 1),

                            // Header Logo & Teks Create Account
                            Row(
                              children: [
                                Image.asset('assets/images/logo.png', height: 40),
                                const SizedBox(width: 12),
                                const Text(
                                  'Create Account',
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
                              'Welcome! Please create your account here.',
                              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 40),

                            // Form Input Username
                            _buildTextField(
                              controller: _usernameController,
                              label: 'Username',
                            ),
                            const SizedBox(height: 20),
                            
                            // Form Input Email
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                            ),
                            const SizedBox(height: 20),
                            
                            // Form Input Password
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              isPassword: true,
                            ),
                            
                            // Jarak langsung ke tombol, tanpa baris Remember Me
                            const SizedBox(height: 32),

                            // Tombol Create Account
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
                                onPressed: _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.colorCyan,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Tautan Sign In
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ",
                                  style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // Pop kembali ke halaman Login yang sudah ada di stack
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Constants.colorDarkBlue,
                                    ),
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
    );
  }
}