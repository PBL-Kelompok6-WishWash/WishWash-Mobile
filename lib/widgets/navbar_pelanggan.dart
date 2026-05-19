import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/pelanggan/orders/payment_screen.dart';
import 'package:mobile/screens/pelanggan/orders/create_order_screen.dart';

class BottomNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant BottomNavbar oldWidget) {
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
    const Color inactiveColor = Color(0xFF888888); // Gray for better inactive state
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8CFAFF), // Light bright cyan highlight (5% brighter)
                          Color(0xFF47B2BA), // Rich solid cyan depth (5% brighter)
                        ],
                      ),
                      boxShadow: [
                        // 3D bottom edge line (tipis)
                        BoxShadow(
                          color: const Color(0xFF104447).withOpacity(0.25),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                        // Soft ambient glow (tipis)
                        BoxShadow(
                          color: const Color(0xFF47B2BA).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showPlusMenu(context);
                        },
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

  void _showPlusMenu(BuildContext context) {
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
                        MaterialPageRoute(builder: (context) => const PaymentScreenNew()),
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
    return InkWell(
      onTap: onTap,
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
