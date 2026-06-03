import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/utils/constants.dart';

class RoomChatAdminScreen extends StatefulWidget {
  final int roomChatID; // Menangkap ID Room dari halaman sebelumnya
  final String courierName;
  final String platNomor;
  
  const RoomChatAdminScreen({
    super.key, 
    required this.roomChatID,
    required this.courierName,
    required this.platNomor,
  });

  @override
  State<RoomChatAdminScreen> createState() => _RoomChatAdminScreenState();
}

class _RoomChatAdminScreenState extends State<RoomChatAdminScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  WebSocketChannel? _channel;
  List<dynamic> _messages = [];
  bool _isMenuOpen = false;
  
  // Kasih hardcode ID User pengirim sementara untuk tes (misal: Pelanggan ID = 2)
  // Nanti kalau sistem loginmu sudah jadi, ambil dari SharedPreferences / State Management
  final int currentUserID = 2; 

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _connectWebSocket();
  }

  // 1. Ambil History Chat Lama via HTTP
  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/room/${widget.roomChatID}/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _messages = data['data'] ?? [];
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Gagal memuat history chat: $e");
    }
  }

  // 2. Hubungkan Saluran Jembatan WebSocket ke Go
  void _connectWebSocket() {
    // Jalur jabat tangan menggunakan ws:// (bukan http://)
    final wsUrlStr = Constants.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrlStr/chat/room/${widget.roomChatID}/ws?id_user=$currentUserID'),
    );

    // Dengarkan terus secara real-time kalau backend mengirimkan pesan baru
    _channel!.stream.listen((message) {
      final incomingData = json.decode(message);
      setState(() {
        _messages.add(incomingData);
      });
      _scrollToBottom();
    }, onError: (error) {
      debugPrint("WebSocket Error: $error");
    }, onDone: () {
      debugPrint("WebSocket Koneksi Terputus.");
    });
  }

  // 3. Fungsi Mengirim Pesan Instan
  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && _channel != null) {
      final text = _messageController.text.trim();
      
      // Kirim format JSON ke Go lewat WebSocket
      _channel!.sink.add(json.encode({
        'teks_pesan': text,
      }));

      _messageController.clear();
    }
  }

  Future<void> _sendImageMessage(XFile image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    if (_channel != null) {
      _channel!.sink.add(json.encode({
        'teks_pesan': '',
        'base64_gambar': base64Image,
      }));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway); // Tutup koneksi WebSocket jika keluar halaman
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  // --- Fungsi Tambahan Menu ---
  Future<void> _openCamera() async {
    _toggleMenu();
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (image != null) {
        _sendImageMessage(image);
      }
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  Future<void> _openGallery() async {
    _toggleMenu();
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        _sendImageMessage(image);
      }
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
                          style: GoogleFonts.poppins(color: navyColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          widget.platNomor,
                          style: GoogleFonts.poppins(color: navyColor.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- KONTEN HALAMAN (Daftar Balon Chat) ---
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
                  // List Message Dinamis
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // Cek apakah pesan ini dikirim oleh user yang sedang login sekarang
                      bool isMe = msg['id_user'] == currentUserID;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? navyColor : const Color(0xFFEBF8FA),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Builder(
                            builder: (context) {
                              final String? pathGambar = msg['path_gambar'];
                              final bool hasGambar = pathGambar != null && pathGambar.isNotEmpty;
                              final String text = msg['teks_pesan'] ?? '';
                              final bool hasText = text.isNotEmpty;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasGambar) ...[
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                        maxHeight: 220,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          Constants.baseUrl.replaceAll('/api/v1', '') + pathGambar,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: Center(child: CircularProgressIndicator()),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    if (hasText) const SizedBox(height: 8),
                                  ],
                                  if (hasText)
                                    Text(
                                      text,
                                      style: GoogleFonts.poppins(
                                        color: isMe ? Colors.white : navyColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Floating Menu
                  if (_isMenuOpen)
                    Positioned(
                      bottom: 10, left: 20, right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isMenuOpen ? Icons.close_rounded : Icons.add_rounded, color: cyanColor, size: 28),
                            onPressed: _toggleMenu,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: cyanColor, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                      onPressed: _sendMessage,
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
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF0C4B8E), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}