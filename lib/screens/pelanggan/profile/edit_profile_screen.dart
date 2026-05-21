import 'dart:convert';
import 'package:flutter/material';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/services/pelanggan_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/utils/constants.dart';
import 'package:mobile/widgets/custom_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  final String namaLengkap;
  final String noTelp;
  final String email;
  final String username;
  final String fotoPelanggan;

  const EditProfileScreen({
    super.key,
    required this.namaLengkap,
    required this.noTelp,
    required this.email,
    required this.username,
    required this.fotoPelanggan,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  
  String _fotoPelanggan = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.namaLengkap);
    _phoneController = TextEditingController(text: widget.noTelp == '-' ? '' : widget.noTelp);
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
    _fotoPelanggan = widget.fotoPelanggan;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        setState(() {
          _fotoPelanggan = 'data:image/png;base64,$base64Str';
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Widget _buildAvatarSelector() {
    ImageProvider? imageProvider;
    if (_fotoPelanggan.startsWith('http://') || _fotoPelanggan.startsWith('https://')) {
      imageProvider = NetworkImage(_fotoPelanggan);
    } else if (_fotoPelanggan.startsWith('data:image')) {
      try {
        final base64Content = _fotoPelanggan.split(',').last;
        final bytes = base64Decode(base64Content);
        imageProvider = MemoryImage(bytes);
      } catch (e) {
        debugPrint("Error base64 image: $e");
      }
    } else if (_fotoPelanggan.startsWith('/uploads/')) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      imageProvider = NetworkImage('$staticHost$_fotoPelanggan');
    } else if (_fotoPelanggan.isNotEmpty) {
      imageProvider = AssetImage(_fotoPelanggan);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(55),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFEBF8FA),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Icon(Icons.person_rounded, size: 55, color: cyanColor)
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cyanColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 16),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: navyColor.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14, color: navyColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
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

  Future<void> _saveChanges() async {
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();

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

    // 2. Phone Number Validation
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
    if (phone.length < 10 || phone.length > 13) {
      CustomDialog.showError(
        context: context,
        title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
        message: TranslationService.currentLang == 'en' 
            ? 'Phone number must be between 10 and 13 digits' 
            : 'Nomor telepon harus berukuran antara 10 sampai 13 digit',
      );
      return;
    }

    // 3. Username Validation
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

    // 4. Email Validation
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

    setState(() {
      _isSaving = true;
    });

    final response = await PelangganService.updateProfile({
      'nama': name,
      'no_telp': phone,
      'username': username,
      'email': email,
      'foto_pelanggan': _fotoPelanggan.trim(),
    });

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (response['success'] == true) {
        CustomDialog.showSuccess(
          context: context,
          title: TranslationService.currentLang == 'en' ? 'Success' : 'Berhasil',
          message: TranslationService.currentLang == 'en'
              ? 'Profile updated successfully!'
              : 'Profil berhasil diperbarui!',
        );
        // Wait a short delay for dialog and then return success true
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        CustomDialog.showError(
          context: context,
          title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
          message: response['message'] ?? 'Terjadi kesalahan.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2),
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
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        TranslationService.currentLang == 'en' ? 'Edit Profile' : 'Edit Profil',
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

              // --- CONTENT CONTAINER SHEET ---
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
                          // Avatar Selector
                          _buildAvatarSelector(),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              TranslationService.currentLang == 'en' 
                                  ? 'Tap camera icon to change photo' 
                                  : 'Ketuk ikon kamera untuk mengubah foto',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Inputs
                          _buildInputLabel(TranslationService.currentLang == 'en' ? 'Full Name' : 'Nama Lengkap'),
                          _buildTextField(
                            _nameController, 
                            TranslationService.currentLang == 'en' ? 'Enter full name' : 'Masukkan nama lengkap', 
                            Icons.person_outline
                          ),
                          
                          _buildInputLabel(TranslationService.currentLang == 'en' ? 'Phone Number' : 'Nomor Telepon'),
                          _buildTextField(
                            _phoneController, 
                            TranslationService.currentLang == 'en' ? 'Enter phone number' : 'Masukkan nomor telepon', 
                            Icons.phone_android_outlined, 
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          
                          _buildInputLabel('Username'),
                          _buildTextField(
                            _usernameController, 
                            TranslationService.currentLang == 'en' ? 'Enter username' : 'Masukkan username', 
                            Icons.alternate_email_outlined
                          ),
                          
                          _buildInputLabel('Email'),
                          _buildTextField(
                            _emailController, 
                            TranslationService.currentLang == 'en' ? 'Enter email address' : 'Masukkan email', 
                            Icons.mail_outline, 
                            keyboardType: TextInputType.emailAddress
                          ),
                          
                          const SizedBox(height: 40),

                          // Save Button
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
                                  onTap: _isSaving ? null : _saveChanges,
                                  child: Center(
                                    child: _isSaving
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                            TranslationService.currentLang == 'en' 
                                                ? 'Save Changes' 
                                                : 'Simpan Perubahan',
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
