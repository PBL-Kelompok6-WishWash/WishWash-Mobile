import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/pelanggan/orders/payment.dart';
import 'package:mobile/screens/pelanggan/orders/create_order_screen.dart';

void showMenuPlus(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.1), // Dim background
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 110, left: 24, right: 24),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPopupMenuItem(
                  context,
                  icon: Icons.credit_card_rounded,
                  label: 'Payment',
                  onTap: () {
                    Navigator.pop(context); // Close popup
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentScreen()),
                    );
                  },
                ),
                _buildPopupMenuItem(
                  context,
                  icon: Icons.post_add_rounded,
                  label: 'New Order',
                  onTap: () {
                    Navigator.pop(context); // Close popup
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

Widget _buildPopupMenuItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
  const Color cyanColor = Color(0xFF5ACFD6);
  return InkWell(
    onTap: onTap,
    splashColor: cyanColor.withOpacity(0.2), // Warna efek saat dipencet
    highlightColor: cyanColor.withOpacity(0.1),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0C4B8E), size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF0C4B8E),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
