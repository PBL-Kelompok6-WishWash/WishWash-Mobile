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
import 'package:mobile/services/order_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/screens/pelanggan/orders/order_detail_screen.dart';
import 'package:mobile/screens/karyawan/orders/order_detail_screen.dart';

class RoomChatDetailScreen extends StatefulWidget {
  final int roomChatID;
  final String targetName;
  final String targetPhoto;
  final String subtitle;
  final Map<String, dynamic>? orderToTrack;
  
  const RoomChatDetailScreen({
    super.key, 
    required this.roomChatID,
    required this.targetName,
    required this.targetPhoto,
    required this.subtitle,
    this.orderToTrack,
  });

  @override
  State<RoomChatDetailScreen> createState() => _RoomChatDetailScreenState();
}

class _RoomChatDetailScreenState extends State<RoomChatDetailScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  WebSocketChannel? _channel;
  List<dynamic> _messages = [];
  bool _isMenuOpen = false;
  
  // Custom ID User pengirim (ambil dari SharedPreferences jika ada)
  int currentUserID = 2; 
  int? currentUserRoleID;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    await _loadUserID();
    await _loadChatHistory();
    _connectWebSocket();
    _autoSendOrderTrackerIfNeeded();
  }

  Future<void> _loadUserID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? idUser = prefs.getInt('id_user');
      int? roleId = prefs.getInt('id_role');
      if (idUser == null) {
        final token = prefs.getString('jwt_token');
        if (token != null) {
          idUser = _decodeUserIdFromToken(token);
          if (idUser != null) {
            await prefs.setInt('id_user', idUser);
          }
        }
      }
      debugPrint("Loaded User ID from storage: $idUser, Role ID: $roleId");
      if (idUser != null) {
        setState(() {
          currentUserID = idUser!;
        });
      }
      if (roleId != null) {
        setState(() {
          currentUserRoleID = roleId;
        });
      }
    } catch (e) {
      debugPrint("Error loading User ID: $e");
    }
  }

  int? _decodeUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = json.decode(resp);
      if (claims['id_user'] != null) {
        return (claims['id_user'] as num).toInt();
      }
    } catch (_) {}
    return null;
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
    final wsUrlStr = Constants.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrlStr/chat/room/${widget.roomChatID}/ws?id_user=$currentUserID'),
    );

    _channel!.stream.listen((message) {
      final incomingData = json.decode(message);
      setState(() {
        _messages.add(incomingData);
      });
      _scrollToBottom();
      
      // Jika pesan bukan dari user sekarang, beri tahu server untuk read (dengan trigger load history ulang)
      if (incomingData['id_user'] != currentUserID) {
        _loadChatHistory();
      }
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
    _channel?.sink.close(status.goingAway);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

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

  Widget _buildHeaderAvatar() {
    if (widget.targetPhoto.isEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, color: Colors.grey.shade400, size: 28),
      );
    }
    
    Widget img;
    if (widget.targetPhoto.startsWith('http://') || widget.targetPhoto.startsWith('https://')) {
      img = Image.network(widget.targetPhoto, fit: BoxFit.cover);
    } else if (widget.targetPhoto.startsWith('/uploads/')) {
      final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
      img = Image.network('$staticHost${widget.targetPhoto}', fit: BoxFit.cover);
    } else if (widget.targetPhoto.startsWith('data:image')) {
      try {
        final base64Content = widget.targetPhoto.split(',').last;
        final bytes = base64Decode(base64Content);
        img = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.person, color: Colors.grey.shade400, size: 28),
        );
      }
    } else {
      img = Image.asset(widget.targetPhoto, fit: BoxFit.cover);
    }
    
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(child: img),
    );
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
                  _buildHeaderAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.targetName,
                          style: GoogleFonts.poppins(color: navyColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (widget.subtitle.isNotEmpty && widget.subtitle != '-')
                          Text(
                            widget.subtitle,
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
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        bool isMe = (msg['id_user'] as num?)?.toInt() == currentUserID;

                        // Date Divider logic
                        bool showDateDivider = false;
                        String dateDividerText = '';
                        final String rawTime = msg['waktu_kirim'] ?? '';
                        if (rawTime.isNotEmpty) {
                          try {
                            final dt = DateTime.parse(rawTime).toLocal();
                            if (index == 0) {
                              showDateDivider = true;
                            } else {
                              final prevMsg = _messages[index - 1];
                              final String prevRawTime = prevMsg['waktu_kirim'] ?? '';
                              if (prevRawTime.isNotEmpty) {
                                final prevDt = DateTime.parse(prevRawTime).toLocal();
                                if (dt.year != prevDt.year || dt.month != prevDt.month || dt.day != prevDt.day) {
                                  showDateDivider = true;
                                }
                              } else {
                                showDateDivider = true;
                              }
                            }

                            if (showDateDivider) {
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              final yesterday = today.subtract(const Duration(days: 1));
                              final msgDate = DateTime(dt.year, dt.month, dt.day);

                              if (msgDate == today) {
                                dateDividerText = 'Today';
                              } else if (msgDate == yesterday) {
                                dateDividerText = 'Yesterday';
                              } else {
                                final months = [
                                  'January', 'February', 'March', 'April', 'May', 'June',
                                  'July', 'August', 'September', 'October', 'November', 'December'
                                ];
                                dateDividerText = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
                              }
                            }
                          } catch (_) {}
                        }

                        final String text = msg['teks_pesan'] ?? '';
                        final trackerInfo = _parseTrackerMessage(text);
                        
                        Widget bubbleWidget;
                        if (trackerInfo != null) {
                          String timeText = '';
                          final String rawTime = msg['waktu_kirim'] ?? '';
                          if (rawTime.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(rawTime).toLocal();
                              timeText = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            } catch (_) {}
                          }
                          bubbleWidget = Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: _buildTrackerCard(trackerInfo, isMe, timeText, msg['status_baca'] == true),
                          );
                        } else {
                          bubbleWidget = Align(
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
                                  final bool hasText = text.isNotEmpty;

                                  String timeText = '';
                                  final String rawTime = msg['waktu_kirim'] ?? '';
                                  if (rawTime.isNotEmpty) {
                                    try {
                                      final dt = DateTime.parse(rawTime).toLocal();
                                      timeText = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                    } catch (_) {}
                                  }

                                  return Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 14, right: 45),
                                        child: Column(
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
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              timeText,
                                              style: GoogleFonts.poppins(
                                                color: isMe ? Colors.white.withOpacity(0.65) : navyColor.withOpacity(0.55),
                                                fontSize: 10,
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.done_all_rounded,
                                                size: 15,
                                                color: (msg['status_baca'] == true)
                                                    ? const Color(0xFF40C4FF) // Centang biru
                                                    : Colors.white.withOpacity(0.6), // Centang abu-abu
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        if (showDateDivider) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDateDivider(dateDividerText),
                              bubbleWidget,
                            ],
                          );
                        }
                        return bubbleWidget;
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

  Widget _buildDateDivider(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF8FA),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: navyColor,
          ),
        ),
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

  void _autoSendOrderTrackerIfNeeded() {
    if (widget.orderToTrack == null) return;
    
    final order = widget.orderToTrack!;
    final orderCode = order['kode_order'] ?? 'WW-${order['id_order']}';
    final searchPattern = '[Order Tracker] $orderCode';
    
    bool alreadySent = false;
    for (var msg in _messages) {
      final String text = msg['teks_pesan'] ?? '';
      if (text.contains(searchPattern)) {
        alreadySent = true;
        break;
      }
    }
    
    if (!alreadySent) {
      final String serviceName = order['Layanan'] != null 
          ? (order['Layanan']['nama_layanan'] ?? 'Layanan') 
          : 'Layanan';
      final String status = _getOrderStatusForTracker(order);
      final double totalBayar = (order['total_bayar'] as num?)?.toDouble() ?? 0.0;
      final String priceStr = totalBayar > 0 ? 'Rp ${totalBayar.toInt()}' : 'Pending Weight';
      
      final String trackerMessage = 
          '📦 $searchPattern\n'
          '🔹 Service: $serviceName\n'
          '🔹 Status: $status\n'
          '🔹 Total: $priceStr\n'
          '🔹 Order ID: ${order['id_order']}';
          
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_channel != null) {
          _channel!.sink.add(json.encode({
            'teks_pesan': trackerMessage,
          }));
        }
      });
    }
  }

  Map<String, String>? _parseTrackerMessage(String text) {
    if (!text.contains('[Order Tracker]')) return null;
    try {
      final lines = text.split('\n');
      String code = '';
      String service = '';
      String status = '';
      String total = '';
      String orderId = '';
      
      for (var line in lines) {
        if (line.contains('[Order Tracker]')) {
          final idx = line.indexOf('[Order Tracker]');
          code = line.substring(idx + '[Order Tracker]'.length).trim();
        } else if (line.contains('Service:')) {
          service = line.substring(line.indexOf('Service:') + 'Service:'.length).trim();
        } else if (line.contains('Status:')) {
          status = line.substring(line.indexOf('Status:') + 'Status:'.length).trim();
        } else if (line.contains('Total:')) {
          total = line.substring(line.indexOf('Total:') + 'Total:'.length).trim();
        } else if (line.contains('Order ID:')) {
          orderId = line.substring(line.indexOf('Order ID:') + 'Order ID:'.length).trim();
        }
      }
      return {
        'code': code,
        'service': service,
        'status': status,
        'total': total,
        'orderId': orderId,
      };
    } catch (_) {
      return null;
    }
  }

  Widget _buildTrackerCard(Map<String, String> trackerInfo, bool isMe, String timeText, bool isRead) {
    final String code = trackerInfo['code'] ?? '';
    final String service = trackerInfo['service'] ?? '';
    final String status = trackerInfo['status'] ?? '';
    final String total = trackerInfo['total'] ?? '';
    final String orderIdStr = trackerInfo['orderId'] ?? '';
    final int? orderId = int.tryParse(orderIdStr);

    final Color statusColor;
    final Color statusBg;
    
    final statusLower = status.toLowerCase();
    if (statusLower.contains('selesai') || statusLower.contains('done')) {
      statusColor = const Color(0xFF2E7D32);
      statusBg = const Color(0xFFE8F5E9);
    } else if (statusLower.contains('batal') || statusLower.contains('cancel')) {
      statusColor = const Color(0xFFC62828);
      statusBg = const Color(0xFFFFEBEE);
    } else if (statusLower.contains('proses') || statusLower.contains('timbang') || statusLower.contains('cuci') || statusLower.contains('setrika') || statusLower.contains('pickup') || statusLower.contains('jemput')) {
      statusColor = const Color(0xFFE65100);
      statusBg = const Color(0xFFFFF3E0);
    } else {
      statusColor = const Color(0xFF1565C0);
      statusBg = const Color(0xFFE3F2FD);
    }

    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: navyColor.withOpacity(0.06),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: navyColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      TranslationService.currentLang == 'en' ? 'WishWash Order Detail' : 'Detail Pesanan WishWash',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        code,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade100, height: 1),
                  const SizedBox(height: 10),
                  _buildTrackerDetailRow(TranslationService.currentLang == 'en' ? 'Service' : 'Layanan', service),
                  const SizedBox(height: 6),
                  _buildTrackerDetailRow('Total', total, isBoldValue: true),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeText,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: isRead
                                ? const Color(0xFF40C4FF)
                                : Colors.grey.shade400,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (orderId != null)
              InkWell(
                onTap: () => _navigateToOrderDetail(orderId),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100, width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      TranslationService.currentLang == 'en' ? 'View Details' : 'Lihat Detail',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cyanColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerDetailRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF2D3748),
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToOrderDetail(int orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final order = await OrderService.getOrderById(orderId);
      if (mounted) {
        Navigator.pop(context);
        if (currentUserRoleID == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreenKaryawan(
                order: order,
                onOrderUpdated: (updated) {},
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(
                order: order,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load order details: $e')),
        );
      }
    }
  }

  String _getOrderStatusForTracker(Map<String, dynamic> order) {
    final historyList = order['RiwayatStatusDetail'];
    if (historyList == null || historyList is! List || historyList.isEmpty) {
      return 'Pesanan Diterima';
    }
    List<dynamic> sortedHistory = List.from(historyList);
    sortedHistory.sort((a, b) {
      final idA = a['id_riwayat_status_detail'] as num? ?? 0;
      final idB = b['id_riwayat_status_detail'] as num? ?? 0;
      return idA.compareTo(idB);
    });
    final latestHistory = sortedHistory.last;
    final refStatus = latestHistory['ReferensiStatus'];
    if (refStatus != null && refStatus is Map) {
      return refStatus['nama_status'] ?? 'Pesanan Diterima';
    }
    return 'Pesanan Diterima';
  }
}
