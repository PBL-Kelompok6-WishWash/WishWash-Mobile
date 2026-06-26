import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/utils/constants.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/home_screen.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_detail.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/screens/pelanggan/profile/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final bool showNavbar;
  const ChatScreen({super.key, this.showNavbar = true});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  List<dynamic> chatRooms = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchChatRooms();
  }

  // Fungsi mengambil daftar Room Chat dari Backend Go
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
        final List<dynamic> rooms = data['data'] ?? [];
        
        // Sort rooms by LastMessage.waktu_kirim descending (newest first)
        rooms.sort((a, b) {
          final lastMsgA = a['LastMessage'];
          final lastMsgB = b['LastMessage'];
          if (lastMsgA == null && lastMsgB == null) return 0;
          if (lastMsgA == null) return 1;
          if (lastMsgB == null) return -1;
          final String timeStrA = lastMsgA['waktu_kirim'] ?? '';
          final String timeStrB = lastMsgB['waktu_kirim'] ?? '';
          if (timeStrA.isEmpty && timeStrB.isEmpty) return 0;
          if (timeStrA.isEmpty) return 1;
          if (timeStrB.isEmpty) return -1;
          try {
            final DateTime dtA = DateTime.parse(timeStrA);
            final DateTime dtB = DateTime.parse(timeStrB);
            return dtB.compareTo(dtA);
          } catch (_) {
            return 0;
          }
        });

        setState(() {
          chatRooms = rooms;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal load room chat: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        final double statusBarHeight = MediaQuery.of(context).padding.top;
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2),
          extendBody: true,
          body: Column(
            children: [
              // --- HEADER & APPBAR ---
              Padding(
                padding: EdgeInsets.fromLTRB(20, statusBarHeight + 10, 20, 10),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Text(
                        TranslationService.translate('message'),
                        style: GoogleFonts.poppins(
                          color: navyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- KONTEN UTAMA (Sheet Putih) ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFC),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : () {
                          final filteredRooms = chatRooms.where((room) {
                            final order = room['Order'];
                            final karyawan = order != null ? order['Karyawan'] : null;
                            final String name = karyawan == null ? 'Admin WishWash' : karyawan['nama_karyawan'];
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
                                child: RefreshIndicator(
                                  onRefresh: fetchChatRooms,
                                  color: navyColor,
                                  child: filteredRooms.isEmpty
                                      ? ListView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          children: [
                                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                            Center(
                                              child: Text(
                                                TranslationService.currentLang == 'en' ? "No active chats" : "Belum ada obrolan aktif",
                                                style: GoogleFonts.poppins(),
                                              ),
                                            ),
                                          ],
                                        )
                                      : ListView.builder(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.fromLTRB(24, 15, 24, 100),
                                          itemCount: filteredRooms.length,
                                          itemBuilder: (context, index) {
                                            final room = filteredRooms[index];
                                            final order = room['Order'];
                                            final karyawan = order != null ? order['Karyawan'] : null;
                                            
                                            bool isAdmin = karyawan == null;
                                            String namaKurir = isAdmin ? 'Admin WishWash' : karyawan['nama_karyawan'];
                                            String fotoKaryawan = isAdmin ? '' : (karyawan['foto_karyawan'] ?? '');
                                            
                                            String subtitle = isAdmin
                                                ? '-'
                                                : [
                                                    if (karyawan['jenis_kendaraan'] != null && karyawan['jenis_kendaraan'].toString().trim().isNotEmpty)
                                                      karyawan['jenis_kendaraan'].toString().trim(),
                                                    if (karyawan['plat_nomor'] != null && karyawan['plat_nomor'].toString().trim().isNotEmpty)
                                                      karyawan['plat_nomor'].toString().trim(),
                                                  ].join(' \u2022 ');

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
                                                lastMsgTime = _formatLastMessageTime(rawTime);
                                              }
                                            }

                                            return _buildCourierCard(
                                              context: context,
                                              roomID: room['id_room_chat'],
                                              name: namaKurir,
                                              platNomor: subtitle,
                                              message: lastMsgText,
                                              time: lastMsgTime,
                                              navyColor: navyColor,
                                              unreadCount: room['unread_count'] ?? 0,
                                              isAdmin: isAdmin,
                                              fotoKaryawan: fotoKaryawan,
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ],
                          );
                        }(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: widget.showNavbar ? BottomNavbar(
            currentIndex: 3,
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PelangganHomeScreen()));
              } else if (index == 4) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }
            },
          ) : null,
        );
      },
    );
  }

  Widget _buildCourierCard({
    required BuildContext context,
    required int roomID,
    required String name,
    required String platNomor,
    required String message,
    required String time,
    required Color navyColor,
    required int unreadCount,
    required bool isAdmin,
    required String fotoKaryawan,
  }) {
    Widget avatarWidget;
    if (isAdmin) {
      avatarWidget = CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFEBF8FA),
        child: Icon(Icons.admin_panel_settings_rounded, color: navyColor, size: 28),
      );
    } else if (fotoKaryawan.isNotEmpty) {
      Widget img;
      if (fotoKaryawan.startsWith('http://') || fotoKaryawan.startsWith('https://')) {
        img = Image.network(fotoKaryawan, fit: BoxFit.cover);
      } else if (fotoKaryawan.startsWith('/uploads/')) {
        final staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
        img = Image.network('$staticHost$fotoKaryawan', fit: BoxFit.cover);
      } else {
        img = Image.asset(fotoKaryawan, fit: BoxFit.cover);
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
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: navyColor),
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
              targetPhoto: fotoKaryawan,
              subtitle: platNomor,
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
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: navyColor),
                              ),
                            ),
                            if (platNomor.isNotEmpty && platNomor != '-') ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFEBF8FA), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    platNomor, 
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF42C6D4)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontSize: 11, 
                            color: unreadCount > 0 ? navyColor : Colors.grey.shade400, 
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
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

  String _formatLastMessageTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      
      final dateOnlyDt = DateTime(dt.year, dt.month, dt.day);
      final dateOnlyNow = DateTime(now.year, now.month, now.day);
      
      final difference = dateOnlyNow.difference(dateOnlyDt).inDays;
      final isEn = TranslationService.currentLang == 'en';
      
      if (difference <= 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (difference == 1) {
        return isEn ? 'Yesterday' : 'Kemarin';
      } else if (difference < 7) {
        final dayOfWeek = dt.weekday;
        if (isEn) {
          switch (dayOfWeek) {
            case 1: return 'Monday';
            case 2: return 'Tuesday';
            case 3: return 'Wednesday';
            case 4: return 'Thursday';
            case 5: return 'Friday';
            case 6: return 'Saturday';
            case 7: return 'Sunday';
          }
        } else {
          switch (dayOfWeek) {
            case 1: return 'Senin';
            case 2: return 'Selasa';
            case 3: return 'Rabu';
            case 4: return 'Kamis';
            case 5: return 'Jumat';
            case 6: return 'Sabtu';
            case 7: return 'Minggu';
          }
        }
      }
      
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      return '';
    }
  }
}