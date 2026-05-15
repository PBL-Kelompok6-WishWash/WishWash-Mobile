import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF0C4B8E);
    const Color inactiveColor = Color(0xFF000000);
    const Color cyanColor = Color(0xFF5ACFD6);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - 20) / 5;
    // Calculate indicator position
    final double indicatorWidth = 76;
    double indicatorLeft =
        10 +
        (currentIndex * itemWidth) +
        (itemWidth / 2) -
        (indicatorWidth / 2);

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
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              top: 0,
              left: indicatorLeft,
              child: CustomPaint(
                size: Size(indicatorWidth, 24),
                painter: IndicatorPainter(cyanColor),
              ),
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
                    currentIndex: currentIndex,
                    onTap: onTap,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  _buildNavItem(
                    icon: Icons.local_laundry_service_outlined,
                    activeIcon: Icons.local_laundry_service_rounded,
                    label: 'Orders',
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTap,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),

                  // Smaller Aesthetic Plus Button
                  GestureDetector(
                    onTap: () => onTap(2),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cyanColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cyanColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  _buildNavItem(
                    icon: Icons.message_outlined,
                    activeIcon: Icons.message_rounded,
                    label: 'Message',
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: onTap,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                    currentIndex: currentIndex,
                    onTap: onTap,
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
    );
  }
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
