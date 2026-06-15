import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/notifikasi_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile/utils/notification_listener.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_detail.dart';
import 'package:mobile/screens/karyawan/orders/order_detail_screen.dart';
import 'package:mobile/services/order_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedFilterIndex = 0; // 0: Semua, 1: Belum Dibaca, 2: Sudah Dibaca
  final ValueNotifier<int?> _openCardIdNotifier = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    NotificationListenerManager().addCallback(_onNewNotification);
  }

  @override
  void dispose() {
    NotificationListenerManager().removeCallback(_onNewNotification);
    super.dispose();
  }

  void _onNewNotification(Map<String, dynamic> notif) {
    if (mounted) {
      setState(() {
        _notifications.insert(0, notif);
      });
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      final list = await NotifikasiService.getNotifications();
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    try {
      final success = await NotifikasiService.markAsRead(id);
      if (success) {
        setState(() {
          _notifications[index]['is_read'] = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      final success = await NotifikasiService.markAllAsRead();
      if (success) {
        setState(() {
          for (var item in _notifications) {
            item['is_read'] = true;
          }
        });
        _showSuccessDialog();
      }
    } catch (_) {}
  }

  Future<void> _deleteAllNotifications() async {
    try {
      final success = await NotifikasiService.deleteAllNotifications();
      if (success) {
        setState(() {
          _notifications.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua notifikasi berhasil dihapus')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteNotification(int id) async {
    try {
      final success = await NotifikasiService.deleteNotification(id);
      if (success) {
        setState(() {
          _notifications.removeWhere((n) => n['id_notifikasi'] == id);
        });
      }
    } catch (_) {}
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCDD2),
                      width: 2.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFE53935),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hapus Semua Notifikasi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2F53),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Apakah Anda yakin ingin menghapus semua notifikasi? Tindakan ini tidak dapat dibatalkan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF0C4B8E).withValues(alpha: 0.6),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: const Color(0xFFBCEFF2).withValues(alpha: 0.8), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0C4B8E).withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAllNotifications();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Hapus',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curveValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curveValue,
          child: Opacity(
            opacity: anim1.value,
            child: AutoDismissDialog(
              duration: const Duration(milliseconds: 1600),
              child: Dialog(
                backgroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F3E4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.done_all_rounded,
                          color: Color(0xFF2E7D32),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Berhasil!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: const Color(0xFF0F2F53),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Semua notifikasi telah terbaca.\nSekarang Anda sudah up-to-date! ✨',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF0C4B8E).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMarkAllAsReadConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAFB),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBCEFF2),
                      width: 2.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.done_all_rounded,
                    color: Color(0xFF0C4B8E),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tandai Semua Dibaca',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2F53),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Apakah Anda yakin ingin menandai semua notifikasi sebagai telah dibaca?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF0C4B8E).withValues(alpha: 0.6),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: const Color(0xFFBCEFF2).withValues(alpha: 0.8), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0C4B8E).withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _markAllAsRead();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C4B8E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Ya, Tandai',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _extractOrderCode(String title, String description) {
    final combined = "$title $description";
    final match = RegExp(r"WW-[A-Z0-9]+", caseSensitive: false).firstMatch(combined);
    return match?.group(0)?.toUpperCase();
  }

  Future<void> _navigateToChat(String title) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF0C4B8E))),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        Navigator.pop(context);
        return;
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/rooms'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        Navigator.pop(context); // close loader
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rooms = data['data'] ?? [];

        String targetName = "";
        final match = RegExp(r"Pesan Baru dari (.*?) 💬").firstMatch(title);
        if (match != null) {
          targetName = match.group(1) ?? "";
        } else {
          targetName = title.replaceAll("Pesan Baru dari ", "").replaceAll(" 💬", "").trim();
        }

        var selectedRoom = rooms.firstWhere(
          (r) {
            final order = r['Order'];
            final pelanggan = order != null ? order['Pelanggan'] : null;
            final String name = pelanggan == null ? '' : pelanggan['nama_lengkap'];
            return name.toLowerCase().contains(targetName.toLowerCase()) ||
                   targetName.toLowerCase().contains(name.toLowerCase());
          },
          orElse: () => null,
        );

        if (selectedRoom == null && rooms.isNotEmpty) {
          selectedRoom = rooms.first;
        }

        if (selectedRoom != null && mounted) {
          final order = selectedRoom['Order'];
          final pelanggan = order != null ? order['Pelanggan'] : null;
          String name = pelanggan == null ? 'Customer' : pelanggan['nama_lengkap'];
          String fotoPelanggan = pelanggan == null ? '' : (pelanggan['foto_pelanggan'] ?? '');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomChatDetailScreen(
                roomChatID: selectedRoom['id_room_chat'],
                targetName: name,
                targetPhoto: fotoPelanggan,
                subtitle: '',
              ),
            ),
          ).then((_) => _fetchNotifications());
        }
      }
    } catch (e) {
      debugPrint("Error navigating to chat room: $e");
    }
  }

  Future<void> _navigateToOrderDetail(String orderCode) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF0C4B8E))),
      );

      final orders = await OrderService.getOrders();
      
      if (mounted) {
        Navigator.pop(context); // close loader
      }

      final selectedOrder = orders.firstWhere(
        (o) {
          final String code = o['kode_order'] ?? '';
          return code.toLowerCase() == orderCode.toLowerCase();
        },
        orElse: () => null,
      );

      if (selectedOrder != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreenKaryawan(
              order: selectedOrder,
              onOrderUpdated: (updatedOrder) {
                _fetchNotifications();
              },
            ),
          ),
        ).then((_) => _fetchNotifications());
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Detail pesanan tidak ditemukan')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error navigating to order detail: $e");
    }
  }

  String _formatTime(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) {
      return '-';
    }
  }

  IconData _getIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('baru masuk') || (lower.contains('pesanan') && lower.contains('baru'))) {
      return Icons.shopping_basket_rounded;
    }
    if (lower.contains('pelanggan baru')) {
      return Icons.person_add_rounded;
    }
    if (lower.contains('pembayaran berhasil') || lower.contains('pembayaran lunas')) {
      return Icons.check_circle_rounded;
    }
    if (lower.contains('metode bayar') || lower.contains('pembayaran') || lower.contains('bayar')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (lower.contains('metode penyerahan') ||
        lower.contains('penyerahan') ||
        lower.contains('jemput') ||
        lower.contains('antar') ||
        lower.contains('kirim') ||
        lower.contains('logistik')) {
      return Icons.local_shipping_rounded;
    }
    if (lower.contains('selesai')) {
      return Icons.check_circle_rounded;
    }
    if (lower.contains('setrika')) {
      return Icons.iron_rounded;
    }
    if (lower.contains('kering') || lower.contains('pengering')) {
      return Icons.wb_sunny_rounded;
    }
    if (lower.contains('dicuci') || lower.contains('pencucian') || lower.contains('cuci')) {
      return Icons.local_laundry_service_rounded;
    }
    if (lower.contains('timbang')) {
      return Icons.scale_rounded;
    }
    if (lower.contains('chat') || lower.contains('pesan baru') || lower.contains('obrolan')) {
      return Icons.chat_bubble_rounded;
    }
    if (lower.contains('batal') || lower.contains('cancel') || lower.contains('dibatalkan')) {
      return Icons.cancel_rounded;
    }
    if (lower.contains('ulasan') || lower.contains('rating') || lower.contains('penilaian') || lower.contains('review')) {
      return Icons.star_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getIconBgColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('baru masuk') || (lower.contains('pesanan') && lower.contains('baru'))) {
      return const Color(0xFFFFF3E0); // Soft Orange
    }
    if (lower.contains('pelanggan baru')) {
      return const Color(0xFFE0F2F1); // Soft Teal
    }
    if (lower.contains('pembayaran berhasil') || lower.contains('pembayaran lunas') || lower.contains('selesai')) {
      return const Color(0xFFE8F5E9); // Soft Green
    }
    if (lower.contains('metode bayar') || lower.contains('pembayaran') || lower.contains('bayar')) {
      return const Color(0xFFFFF8E1); // Soft Amber
    }
    if (lower.contains('metode penyerahan') ||
        lower.contains('penyerahan') ||
        lower.contains('jemput') ||
        lower.contains('antar') ||
        lower.contains('kirim') ||
        lower.contains('logistik')) {
      return const Color(0xFFE8EAF6); // Soft Indigo/Blue
    }
    if (lower.contains('setrika')) {
      return const Color(0xFFF3E5F5); // Soft Purple
    }
    if (lower.contains('kering') || lower.contains('pengering')) {
      return const Color(0xFFFFF3E0); // Soft Orange
    }
    if (lower.contains('dicuci') || lower.contains('pencucian') || lower.contains('cuci')) {
      return const Color(0xFFE1F5FE); // Soft Light Blue
    }
    if (lower.contains('timbang')) {
      return const Color(0xFFE0F2F1); // Soft Teal
    }
    if (lower.contains('chat') || lower.contains('pesan baru') || lower.contains('obrolan')) {
      return const Color(0xFFE3F2FD); // Soft Blue
    }
    if (lower.contains('batal') || lower.contains('cancel') || lower.contains('dibatalkan')) {
      return const Color(0xFFFFEBEE); // Soft Red
    }
    if (lower.contains('ulasan') || lower.contains('rating') || lower.contains('penilaian') || lower.contains('review')) {
      return const Color(0xFFFFFDE7); // Soft Gold
    }
    return const Color(0xFFF1E1FB);
  }

  Color _getIconColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('baru masuk') || (lower.contains('pesanan') && lower.contains('baru'))) {
      return const Color(0xFFFF9800); // Orange
    }
    if (lower.contains('pelanggan baru')) {
      return const Color(0xFF00796B); // Teal
    }
    if (lower.contains('pembayaran berhasil') || lower.contains('pembayaran lunas') || lower.contains('selesai')) {
      return const Color(0xFF2E7D32); // Green
    }
    if (lower.contains('metode bayar') || lower.contains('pembayaran') || lower.contains('bayar')) {
      return const Color(0xFFFF8F00); // Amber
    }
    if (lower.contains('metode penyerahan') ||
        lower.contains('penyerahan') ||
        lower.contains('jemput') ||
        lower.contains('antar') ||
        lower.contains('kirim') ||
        lower.contains('logistik')) {
      return const Color(0xFF3F51B5); // Indigo/Blue
    }
    if (lower.contains('setrika')) {
      return const Color(0xFF7B1FA2); // Purple
    }
    if (lower.contains('kering') || lower.contains('pengering')) {
      return const Color(0xFFFF9800); // Orange
    }
    if (lower.contains('dicuci') || lower.contains('pencucian') || lower.contains('cuci')) {
      return const Color(0xFF0288D1); // Light Blue
    }
    if (lower.contains('timbang')) {
      return const Color(0xFF00796B); // Teal
    }
    if (lower.contains('chat') || lower.contains('pesan baru') || lower.contains('obrolan')) {
      return const Color(0xFF1565C0); // Blue
    }
    if (lower.contains('batal') || lower.contains('cancel') || lower.contains('dibatalkan')) {
      return const Color(0xFFC62828); // Red
    }
    if (lower.contains('ulasan') || lower.contains('rating') || lower.contains('penilaian') || lower.contains('review')) {
      return const Color(0xFFF9A825); // Gold
    }
    return const Color(0xFF6A1B9A);
  }

  Widget _buildFilterSelector() {
    const Color navyColor = Color(0xFF0C4B8E);
    final filters = ['Semua', 'Belum Dibaca', 'Sudah Dibaca'];
    final countSemua = _notifications.length;
    final countBelum = _notifications.where((n) => !(n['is_read'] ?? false)).length;
    final countSudah = _notifications.where((n) => n['is_read'] ?? false).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          final count = index == 0 ? countSemua : (index == 1 ? countBelum : countSudah);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? navyColor : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: navyColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filters[index],
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : navyColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($count)',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white.withOpacity(0.85) : navyColor.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);

    return Scaffold(
      backgroundColor: const Color(0xFFBCEFF2),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Notification',
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  _notifications.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.done_all_rounded, color: navyColor, size: 22),
                              tooltip: 'Tandai semua dibaca',
                              onPressed: _showMarkAllAsReadConfirmation,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 22),
                              tooltip: 'Hapus semua notifikasi',
                              onPressed: _showDeleteAllConfirmation,
                            ),
                          ],
                        )
                      : const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          _buildFilterSelector(),
          const SizedBox(height: 10),

          // --- KONTEN HALAMAN (Sheet Putih) ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: navyColor,
                  child: _buildBody(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    const Color navyColor = Color(0xFF0C4B8E);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: navyColor),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Gagal memuat notifikasi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: navyColor, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _fetchNotifications,
              child: const Text('Coba Lagi'),
            ),
          ),
        ],
      );
    }

    final filteredList = _notifications.where((notif) {
      final bool isRead = notif['is_read'] ?? false;
      if (_selectedFilterIndex == 1) return !isRead; // Belum Dibaca
      if (_selectedFilterIndex == 2) return isRead;  // Sudah Dibaca
      return true; // Semua
    }).toList();

    if (filteredList.isEmpty) {
      String emptyText = 'Belum ada notifikasi';
      String emptyDesc = 'Notifikasi seputar pekerjaan Anda akan muncul di sini.';
      if (_selectedFilterIndex == 1) {
        emptyText = 'Tidak ada notifikasi baru';
        emptyDesc = 'Semua notifikasi Anda sudah dibaca.';
      } else if (_selectedFilterIndex == 2) {
        emptyText = 'Tidak ada riwayat';
        emptyDesc = 'Notifikasi yang sudah dibaca akan muncul di sini.';
      }

      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 450),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 25 * (1.0 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Center(
              child: Text(
                emptyText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  emptyDesc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: ValueKey<int>(_selectedFilterIndex),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final notif = filteredList[index];
        final int id = notif['id_notifikasi'] ?? 0;
        final String title = notif['judul'] ?? 'Notifikasi';
        final String desc = notif['pesan'] ?? '';
        final String time = _formatTime(notif['created_at'] ?? DateTime.now().toIso8601String());
        final bool isRead = notif['is_read'] ?? false;

        return SlidableNotificationCard(
          id: id,
          openCardIdNotifier: _openCardIdNotifier,
          onDelete: () {
            _deleteNotification(id);
          },
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 60).clamp(0, 300)),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1.0 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildNotificationCard(
              id: id,
              index: index,
              title: title,
              description: desc,
              time: time,
              isRead: isRead,
              icon: _getIcon(title),
              iconBg: _getIconBgColor(title),
              iconColor: _getIconColor(title),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required int id,
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required bool isRead,
    required Color iconBg,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(id, index);
        }
        
        final String titleLower = title.toLowerCase();
        if (titleLower.contains('chat') || titleLower.contains('pesan baru')) {
          _navigateToChat(title);
        } else {
          final orderCode = _extractOrderCode(title, description);
          if (orderCode != null) {
            _navigateToOrderDetail(orderCode);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0FAFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRead ? Colors.grey.shade100 : const Color(0xFFBCEFF2).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w800,
                                color: isRead ? Colors.grey.shade400 : const Color(0xFF0F2F53),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isRead ? Colors.grey.shade400 : Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isRead ? Colors.grey.shade400 : const Color(0xFF0C4B8E).withValues(alpha: 0.7),
                          height: 1.4,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isRead)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AutoDismissDialog extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const AutoDismissDialog({super.key, required this.child, this.duration = const Duration(milliseconds: 1500)});

  @override
  State<AutoDismissDialog> createState() => _AutoDismissDialogState();
}

class _AutoDismissDialogState extends State<AutoDismissDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class SlidableNotificationCard extends StatefulWidget {
  final Widget child;
  final int id;
  final ValueNotifier<int?> openCardIdNotifier;
  final VoidCallback onDelete;

  const SlidableNotificationCard({
    super.key,
    required this.child,
    required this.id,
    required this.openCardIdNotifier,
    required this.onDelete,
  });

  @override
  State<SlidableNotificationCard> createState() => _SlidableNotificationCardState();
}

class _SlidableNotificationCardState extends State<SlidableNotificationCard> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  static const double _maxDragWidth = 80.0;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    widget.openCardIdNotifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.openCardIdNotifier.removeListener(_onNotifierChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onNotifierChanged() {
    if (widget.openCardIdNotifier.value != widget.id && _dragOffset != 0.0) {
      _animateTo(0.0);
    }
  }

  void _animateTo(double target) {
    _animation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _isDeleting ? 0.0 : 1.0,
      curve: Curves.easeOut,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _isDeleting
            ? const SizedBox(width: double.infinity, height: 0)
            : Stack(
                children: [
                  // Background delete button
                  if (_dragOffset != 0.0)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFD32F2F), // Rich crimson red
                            Color(0xFFFF5252), // Modern coral red
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFF8A80).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: _maxDragWidth,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              onTap: () {
                                setState(() {
                                  _isDeleting = true;
                                });
                                _animateTo(0.0);
                                Future.delayed(const Duration(milliseconds: 250), () {
                                  if (mounted) {
                                    widget.onDelete();
                                  }
                                });
                              },
                              child: const Center(
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Foreground sliding card
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dragOffset += details.primaryDelta!;
                          if (_dragOffset > 0.0) _dragOffset = 0.0;
                          if (_dragOffset < -_maxDragWidth - 20) _dragOffset = -_maxDragWidth - 20;
                        });
                        if (_dragOffset < 0.0 && widget.openCardIdNotifier.value != widget.id) {
                          widget.openCardIdNotifier.value = widget.id;
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        if (_dragOffset < -_maxDragWidth / 2) {
                          _animateTo(-_maxDragWidth);
                          widget.openCardIdNotifier.value = widget.id;
                        } else {
                          _animateTo(0.0);
                          if (widget.openCardIdNotifier.value == widget.id) {
                            widget.openCardIdNotifier.value = null;
                          }
                        }
                      },
                      onTap: _dragOffset < 0.0 ? () {
                        _animateTo(0.0);
                        if (widget.openCardIdNotifier.value == widget.id) {
                          widget.openCardIdNotifier.value = null;
                        }
                      } : null,
                      child: AbsorbPointer(
                        absorbing: _dragOffset < 0.0,
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}