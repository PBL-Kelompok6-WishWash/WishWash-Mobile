import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomChatScreen extends StatefulWidget {
  const RoomChatScreen({super.key});

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final Color navyColor = const Color(0xFF0F2F53);
  final Color cyanColor = const Color(0xFF42C6D4);
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  Future<void> _openCamera() async {
    _toggleMenu();
    final ImagePicker picker = ImagePicker();
    try {
      await picker.pickImage(source: ImageSource.camera);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  Future<void> _openGallery() async {
    _toggleMenu();
    final ImagePicker picker = ImagePicker();
    try {
      await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      debugPrint("Gallery error: $e");
    }
  }

  Future<void> _openLocation() async {
    _toggleMenu();
    final Uri url = Uri.parse('https://maps.google.com');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Maps')),
          );
        }
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  // Logo image from assets
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cyanColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10), // Radius dikurangi border width
                      child: Padding(
                        padding: const EdgeInsets.all(4.0), // Padding agar logo tidak terpotong
                        child: Image.asset(
                          'assets/images/brand/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              'W',
                              style: GoogleFonts.poppins(
                                color: cyanColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atmint Mahesa',
                          style: GoogleFonts.poppins(
                            color: navyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Wish Wash\'s CS',
                          style: GoogleFonts.poppins(
                            color: navyColor.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24), // Spacer for padding
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- KONTEN HALAMAN (Sheet Putih) ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FBFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // List of chat messages
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    children: const [
                      // Placeholder untuk chat
                    ],
                  ),
                  
                  // Floating Menu
                  if (_isMenuOpen)
                    Positioned(
                      bottom: 10,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMenuItem(Icons.camera_alt, 'Camera', cyanColor, _openCamera),
                            const SizedBox(width: 24),
                            _buildMenuItem(Icons.image, 'Photo & Video', const Color(0xFF1E88E5), _openGallery),
                            const SizedBox(width: 24),
                            _buildMenuItem(Icons.location_on, 'Location', navyColor, _openLocation),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // --- BOTTOM INPUT AREA ---
          Container(
            color: const Color(0xFFBCEFF2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.only(left: 20, right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isMenuOpen ? Icons.close_rounded : Icons.add_rounded,
                              color: cyanColor,
                              size: 28,
                            ),
                            onPressed: _toggleMenu,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: cyanColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF0F2F53),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
