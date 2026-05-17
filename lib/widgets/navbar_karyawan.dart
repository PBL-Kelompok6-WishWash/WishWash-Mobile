import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/auth/register_screen.dart';

class NavbarKaryawan extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarKaryawan({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<NavbarKaryawan> createState() => _NavbarKaryawanState();
}

class _NavbarKaryawanState extends State<NavbarKaryawan> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _topAnimation;
  late Animation<double> _leftAnimation;
  
  double _oldLeft = 0;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600),
    );

    _topAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -30.0).chain(CurveTween(curve: Curves.easeInSine)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -30.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutSine)),
        weight: 50.0,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant NavbarKaryawan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double itemWidth = (screenWidth - 20) / 5;
      final double indicatorWidth = 76;
      
      _oldLeft = 10 + (oldWidget.currentIndex * itemWidth) + (itemWidth / 2) - (indicatorWidth / 2);
      final double targetLeft = 10 + (widget.currentIndex * itemWidth) + (itemWidth / 2) - (indicatorWidth / 2);

      _leftAnimation = Tween<double>(begin: _oldLeft, end: targetLeft).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine)
      );

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF0C4B8E);
    const Color inactiveColor = Color(0xFF000000);
    const Color cyanColor = Color(0xFF5ACFD6);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - 20) / 5;
    final double indicatorWidth = 76;
    double targetLeft = 10 + (widget.currentIndex * itemWidth) + (itemWidth / 2) - (indicatorWidth / 2);

    if (_isFirstBuild) {
      _oldLeft = targetLeft;
      _leftAnimation = Tween<double>(begin: targetLeft, end: targetLeft).animate(_controller);
      _isFirstBuild = false;
    }

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        child: Stack(
          children: [
            // Smooth Curved 'Liquid' Indicator (Inside Top Edge)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  top: _topAnimation.value,
                  left: _leftAnimation.value,
                  child: CustomPaint(
                    size: Size(indicatorWidth, 24),
                    painter: IndicatorPainter(cyanColor),
                  ),
                );
              },
            ),

            // Navbar Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    currentIndex: widget.currentIndex,
                    onTap: widget.onTap,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  _buildNavItem(
                    icon: Icons.local_laundry_service_outlined,
                    activeIcon: Icons.local_laundry_service_rounded,
                    label: 'Orders',
                    index: 1,
                    currentIndex: widget.currentIndex,
                    onTap: widget.onTap,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),

                  // Smaller Aesthetic Plus Button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cyanColor.withOpacity(0.7),
                          cyanColor,
                        ],
                      ),
                      boxShadow: [
                        // White shiny highlight
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(-3, -3),
                        ),
                        // Depth shadow
                        BoxShadow(
                          color: cyanColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showKaryawanMenu(context),
                        customBorder: const CircleBorder(),
                        splashColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.1),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  _buildNavItem(
                    icon: Icons.message_outlined,
                    activeIcon: Icons.message_rounded,
                    label: 'Message',
                    index: 3,
                    currentIndex: widget.currentIndex,
                    onTap: widget.onTap,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                    currentIndex: widget.currentIndex,
                    onTap: widget.onTap,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required Function(int) onTap,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: () => onTap(index),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: SizedBox(
        width: 60,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutSine,
          transform: Matrix4.translationValues(0, isSelected ? -4.0 : 0.0, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Icon(isSelected ? activeIcon : icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Fungsi Pop-up Menu Karyawan (Speed Dial Style) ---
void showKaryawanMenu(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Dismiss",
    barrierColor: Colors.black.withOpacity(0.4), // Efek gelap transparan
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100), // Di atas tombol +
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Menu Tambah Pesanan
                _buildMenuRow(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  label: "Tambah Pesanan",
                  onTap: () {
                    Navigator.pop(context);
                    print("Ke halaman Tambah Pesanan");
                  },
                ),
                const SizedBox(height: 20),
                // 2. Menu Tambah Akun
                _buildMenuRow(
                  context,
                  icon: Icons.person_add_alt_1_outlined,
                  label: "Tambah Akun",
                  onTap: () {
                    Navigator.pop(context); // Tutup pop-up menu dulu
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
    // Animasi muncul dari bawah
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(0, 0.5), end: const Offset(0, 0))
            .animate(anim1),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

// Widget Helper buat Baris Menu (Icon + Label di samping)
Widget _buildMenuRow(BuildContext context,
    {required IconData icon,
    required String label,
    required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label di Samping
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF123B6B),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Tombol Lingkaran Teal
        Container(
          width: 55,
          height: 55,
          decoration: const BoxDecoration(
            color: Color(0xFF4FD1D9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ],
    ),
  );
}

class IndicatorPainter extends CustomPainter {
  final Color color;
  IndicatorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.1,
      0,
      size.width * 0.2,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.2,
      size.width * 0.8,
      size.height * 0.2,
    );
    path.quadraticBezierTo(size.width * 0.9, 0, size.width, 0);
    path.close();

    // Draw Shadow
    canvas.drawShadow(
      path.shift(const Offset(0, 1)),
      color.withOpacity(0.5),
      2.0,
      false,
    );

    // Draw Fill
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Draw Thin Border (Stroke) only at the bottom curve
    Path borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.quadraticBezierTo(
      size.width * 0.1,
      0,
      size.width * 0.2,
      size.height * 0.2,
    );
    borderPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.2,
      size.width * 0.8,
      size.height * 0.2,
    );
    borderPath.quadraticBezierTo(size.width * 0.9, 0, size.width, 0);

    Paint strokePaint = Paint()
      ..color =
          const Color(0xFF3BA9B0) // Cyan tua yang serasi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.01;
    canvas.drawPath(borderPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
