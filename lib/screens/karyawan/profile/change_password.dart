import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/widgets/custom_dialog.dart';
import 'dart:async';
import 'package:mobile/services/translation_service.dart';

class ChangePasswordScreenKaryawan extends StatefulWidget {
  const ChangePasswordScreenKaryawan({super.key});

  @override
  State<ChangePasswordScreenKaryawan> createState() => _ChangePasswordScreenKaryawanState();
}

class _ChangePasswordScreenKaryawanState extends State<ChangePasswordScreenKaryawan> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);

  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _errorMessage;
  Timer? _errorTimer;

  void _showAutoClearError(String message) {
    _errorTimer?.cancel();
    setState(() {
      _errorMessage = message;
    });
    _errorTimer = Timer(const Duration(seconds: 4), () {
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
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await PelangganService.updatePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      final isEn = TranslationService.currentLang == 'en';
      if (response['success'] == true) {
        await CustomDialog.showSuccess(
          context: context,
          title: isEn ? 'Success' : 'Berhasil',
          message: isEn ? 'Your password has been successfully updated!' : 'Password Anda berhasil diperbarui!',
        );
        if (mounted) {
          Navigator.pop(context); // Close ChangePassword Screen
        }
      } else {
        final errorMsg = response['message'] ?? (isEn ? 'Failed to change password.' : 'Gagal mengubah password.');
        _showAutoClearError(errorMsg);
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required bool obscureText,
    required VoidCallback onSuffixPressed,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: navyColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: navyColor,
              fontWeight: FontWeight.w500,
            ),
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(prefixIcon, color: cyanColor, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: onSuffixPressed,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cyanColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        final isEn = lang == 'en';
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2), // Soft Cyan Signature
          extendBody: true,
          body: Stack(
            children: [
              Column(
                children: [
                  // Header
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Text(
                            TranslationService.translate('change_password'),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Content Card
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
                            color: Colors.black.withOpacity(0.06),
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
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn ? 'Change Your Account Password' : 'Ganti Password Akun Anda',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: navyColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isEn 
                                      ? 'Make sure your new password is strong, secure, and easy to remember to keep your account safe.' 
                                      : 'Pastikan password baru Anda kuat, aman, dan mudah diingat agar keamanan akun tetap terjaga.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // ERROR MESSAGE DISPLAY ABOVE CURRENT PASSWORD
                                if (_errorMessage != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0F0),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.redAccent.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: GoogleFonts.poppins(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Input Password Lama
                                _buildPasswordField(
                                  controller: _oldPasswordController,
                                  label: isEn ? 'Current Password' : 'Password Saat Ini',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscureOldPassword,
                                  onSuffixPressed: () {
                                    setState(() {
                                      _obscureOldPassword = !_obscureOldPassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return isEn ? 'Current password is required!' : 'Password saat ini wajib diisi!';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Input Password Baru
                                _buildPasswordField(
                                  controller: _newPasswordController,
                                  label: isEn ? 'New Password' : 'Password Baru',
                                  prefixIcon: Icons.lock_open_rounded,
                                  obscureText: _obscureNewPassword,
                                  onSuffixPressed: () {
                                    setState(() {
                                      _obscureNewPassword = !_obscureNewPassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return isEn ? 'New password is required!' : 'Password baru wajib diisi!';
                                    }
                                    if (value.length < 6) {
                                      return isEn 
                                          ? 'New password must be at least 6 characters!' 
                                          : 'Password baru harus minimal 6 karakter!';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Input Konfirmasi Password Baru
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  label: isEn ? 'Confirm New Password' : 'Konfirmasi Password Baru',
                                  prefixIcon: Icons.gpp_good_outlined,
                                  obscureText: _obscureConfirmPassword,
                                  onSuffixPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return isEn ? 'Confirm new password is required!' : 'Konfirmasi password baru wajib diisi!';
                                    }
                                    if (value != _newPasswordController.text) {
                                      return isEn ? 'Passwords do not match!' : 'Konfirmasi password tidak cocok!';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 36),

                                // Tombol Submit
                                Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [cyanColor, const Color(0xFF00ACC1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cyanColor.withOpacity(0.3),
                                        offset: const Offset(0, 4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _isLoading ? null : _changePassword,
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                isEn ? 'Update Password' : 'Perbarui Password',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
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
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
