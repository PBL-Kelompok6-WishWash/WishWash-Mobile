import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/utils/constants.dart';
import 'package:mobile/widgets/navbar_pelanggan.dart';
import 'package:mobile/screens/pelanggan/home/home_screen.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_kurir.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_admin.dart';
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
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2),
          extendBody: true,
          body: Column(
            children: [
              // --- HEADER & APPBAR ---
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        TranslationService.translate('message'),
                        style: GoogleFonts.poppins(
                          color: navyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
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
                      : chatRooms.isEmpty
                          ? Center(child: Text("Belum ada obrolan aktif", style: GoogleFonts.poppins()))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
                              itemCount: chatRooms.length,
                              itemBuilder: (context, index) {
                                final room = chatRooms[index];
                                final order = room['Order'];
                                final karyawan = order != null ? order['Karyawan'] : null;
                                
                                // Ambil nama kurir pelaksana order laundry-nya atau Admin jika kurir belum ditentukan
                                bool isAdmin = karyawan == null;
                                String namaKurir = isAdmin ? 'Admin WishWash' : karyawan['nama_karyawan'];
                                String platNomor = isAdmin ? '-' : karyawan['plat_nomor'];

                                final String orderCode = order != null ? (order['kode_order'] ?? 'WW-${order['id_order']}') : '';
                                String displayName = orderCode.isNotEmpty ? '$namaKurir (#$orderCode)' : namaKurir;

                                return _buildCourierCard(
                                  context: context,
                                  roomID: room['id_room_chat'],
                                  name: displayName,
                                  platNomor: platNomor,
                                  message: 'Klik untuk obrolan pesanan #$orderCode...',
                                  time: '',
                                  navyColor: navyColor,
                                  unreadCount: 0,
                                  isAdmin: isAdmin,
                                );
                              },
                            ),
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
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin
                ? RoomChatAdminScreen(
                    roomChatID: roomID,
                    courierName: name,
                    platNomor: platNomor,
                  )
                : RoomChatKurirScreen(
                    roomChatID: roomID,
                    courierName: name,
                    platNomor: platNomor,
                  ),
          ),
        );
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
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFEBF8FA),
              child: Text(
                name.trim().split(' ').where((w) => w.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase(),
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: navyColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: navyColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEBF8FA), borderRadius: BorderRadius.circular(6)),
                        child: Text(platNomor, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF42C6D4))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(message, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}