import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomChatKurirScreen extends StatefulWidget {
  final String courierName;
  final String platNomor;
  
  const RoomChatKurirScreen({
    super.key, 
    required this.courierName,
    required this.platNomor,
  });

  @override
  State<RoomChatKurirScreen> createState() => _RoomChatKurirScreenState();
}

class _RoomChatKurirScreenState extends State<RoomChatKurirScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
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
                  // Default Profile Picture
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade100,
                    child: Icon(Icons.person, color: Colors.grey.shade400, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.courierName,
                          style: GoogleFonts.poppins(
                            color: navyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.platNomor,
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
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMenuItem(Icons.camera_alt, 'Camera', cyanColor, _openCamera),
                            _buildMenuItem(Icons.image, 'Photo & Video', const Color(0xFF1E88E5), _openGallery),
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
              color: const Color(0xFF0C4B8E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
