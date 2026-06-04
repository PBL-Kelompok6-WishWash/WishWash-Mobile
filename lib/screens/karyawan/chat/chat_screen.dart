import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/utils/constants.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_detail.dart';
import 'package:mobile/services/translation_service.dart';

class KaryawanChatScreen extends StatefulWidget {
  const KaryawanChatScreen({super.key});

  @override
  State<KaryawanChatScreen> createState() => _KaryawanChatScreenState();
}

class _KaryawanChatScreenState extends State<KaryawanChatScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  List<dynamic> chatRooms = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchChatRooms();
  }

  Future<void> fetchChatRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/rooms'), 
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          chatRooms = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal load room chat karyawan: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // --- HEADER & APPBAR ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Symmetrical spacing
                    Text(
                      TranslationService.currentLang == 'en' ? 'Message' : 'Pesan',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 48), // Symmetrical spacing
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- KONTEN HALAMAN (Sheet Putih Premium) ---
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
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : () {
                      final filteredRooms = chatRooms.where((room) {
                        final order = room['Order'];
                        final pelanggan = order != null ? order['Pelanggan'] : null;
                        final String name = pelanggan != null ? pelanggan['nama_lengkap'] : 'Customer';
                        return name.toLowerCase().contains(searchQuery.toLowerCase());
                      }).toList();

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: TranslationService.currentLang == 'en' ? 'Search chat...' : 'Cari pesan...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.search, color: navyColor, size: 20),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: filteredRooms.isEmpty
                                ? Center(child: Text(TranslationService.currentLang == 'en' ? "No active chats yet" : "Belum ada obrolan aktif", style: GoogleFonts.poppins()))
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(24, 15, 24, 100),
                                    itemCount: filteredRooms.length,
                                    itemBuilder: (context, index) {
                                      final room = filteredRooms[index];
                                      final order = room['Order'];
                                      final pelanggan = order != null ? order['Pelanggan'] : null;
                                      
                                      String namaPelanggan = pelanggan != null ? pelanggan['nama_lengkap'] : 'Customer';
                                      String fotoPelanggan = pelanggan != null ? (pelanggan['foto_pelanggan'] ?? '') : '';
                                      String statusTag = order != null ? 'Order #${order['id_order']}' : 'Chat';

                                      final lastMsg = room['LastMessage'];
                                      String lastMsgText = 'Belum ada pesan';
                                      String lastMsgTime = '';
                                      if (lastMsg != null) {
                                        final String msgText = lastMsg['teks_pesan'] ?? '';
                                        final String pathImg = lastMsg['path_gambar'] ?? '';
                                        if (msgText.isNotEmpty) {
                                          lastMsgText = msgText;
                                        } else if (pathImg.isNotEmpty) {
                                          lastMsgText = '📷 Foto';
                                        }
                                        
                                        final String rawTime = lastMsg['waktu_kirim'] ?? '';
                                        if (rawTime.isNotEmpty) {
                                          try {
                                            final dt = DateTime.parse(rawTime).toLocal();
                                            lastMsgTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                          } catch (_) {}
                                        }
                                      }

                                      return _buildCustomerCard(
                                        context: context,
                                        roomID: room['id_room_chat'],
                                        name: namaPelanggan,
                                        statusTag: statusTag,
                                        message: lastMsgText,
                                        time: lastMsgTime,
                                        navyColor: navyColor,
                                        unreadCount: room['unread_count'] ?? 0,
                                        fotoPelanggan: fotoPelanggan,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    }(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard({
    required BuildContext context,
    required int roomID,
    required String name,
    required String statusTag,
    required String message,
    required String time,
    required Color navyColor,
    required int unreadCount,
    required String fotoPelanggan,
  }) {
    Widget avatarWidget;
    if (fotoPelanggan.isNotEmpty) {
      Widget img;
      if (fotoPelanggan.startsWith('http://') || fotoPelanggan.startsWith('https://')) {
        img = Image.network(fotoPelanggan, fit: BoxFit.cover);
      } else if (fotoPelanggan.startsWith('/uploads/')) {
        final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
        img = Image.network('$staticHost$fotoPelanggan', fit: BoxFit.cover);
      } else {
        img = Image.asset(fotoPelanggan, fit: BoxFit.cover);
      }
      avatarWidget = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(child: img),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFEBF8FA),
        child: Text(
          name.trim().split(' ').where((w) => w.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0C4B8E),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomChatDetailScreen(
              roomChatID: roomID,
              targetName: name,
              targetPhoto: fotoPelanggan,
              subtitle: statusTag,
            ),
          ),
        ).then((_) => fetchChatRooms());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            avatarWidget,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusTag,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF42C6D4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: unreadCount > 0 ? navyColor : Colors.grey.shade400,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5, 
                            color: unreadCount > 0 ? navyColor : Colors.grey.shade500,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF42C6D4),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
