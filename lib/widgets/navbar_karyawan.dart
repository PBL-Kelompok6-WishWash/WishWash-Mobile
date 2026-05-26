import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/karyawan/customer/tambah_pelanggan_screen.dart';
import 'package:mobile/screens/karyawan/create_order/create_order_screen.dart';
import 'package:mobile/services/translation_service.dart';

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
    const Color inactiveColor = Color(0xFF8E9AA6); // Grey for inactive state
    const Color cyanColor = Color(0xFF42C6D4);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - 20) / 5;
    final double indicatorWidth = 76;
    double targetLeft = 10 + (widget.currentIndex * itemWidth) + (itemWidth / 2) - (indicatorWidth / 2);

    if (_isFirstBuild) {
      _oldLeft = targetLeft;
      _leftAnimation = Tween<double>(begin: targetLeft, end: targetLeft).animate(_controller);
      _isFirstBuild = false;
    }

    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
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
                        label: TranslationService.translate('home'),
                        index: 0,
                        currentIndex: widget.currentIndex,
                        onTap: widget.onTap,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                      _buildNavItem(
                        icon: Icons.local_laundry_service_outlined,
                        activeIcon: Icons.local_laundry_service_rounded,
                        label: TranslationService.translate('orders'),
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
                              Color(0xFFBCEFF2), // Soft bright brand cyan
                              Color(0xFF42C6D4), // Standard brand cyan
                            ],
                          ),
                          boxShadow: [
                            // 3D bottom edge line (tipis)
                            BoxShadow(
                              color: const Color(0xFF0C4B8E).withOpacity(0.25),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                            // Soft ambient glow (tipis)
                            BoxShadow(
                              color: const Color(0xFF42C6D4).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () => showKaryawanMenu(context),
                          behavior: HitTestBehavior.opaque,
                          child: const Center(
                            child: Icon(
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
                        label: TranslationService.translate('message'),
                        index: 3,
                        currentIndex: widget.currentIndex,
                        onTap: widget.onTap,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                      _buildNavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: TranslationService.translate('profile'),
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
      },
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
    barrierDismissible: false,
    barrierLabel: "Dismiss",
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) {
      return const KaryawanMenuDialogContent();
    },
  ).then((value) {
    if (value == 'pesanan') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateOrderScreen()));
    } else if (value == 'akun') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const TambahPelangganScreen()));
    }
  });
}

class KaryawanMenuDialogContent extends StatefulWidget {
  const KaryawanMenuDialogContent({super.key});

  @override
  State<KaryawanMenuDialogContent> createState() => _KaryawanMenuDialogContentState();
}

class _KaryawanMenuDialogContentState extends State<KaryawanMenuDialogContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateAnimation;
  late Animation<double> _barrierOpacity;

  String? _activeTooltip;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _translateAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _barrierOpacity = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeDialog() {
    _controller.reverse().then((_) {
      Navigator.pop(context);
    });
  }

  void _handleAction(String type) {
    setState(() {
      _activeTooltip = null;
    });
    _controller.reverse().then((_) {
      Navigator.pop(context, type);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _closeDialog,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              color: Colors.black.withOpacity(_barrierOpacity.value),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 1. Tooltip Bubble (Muncul di atas rectangle putih tepat di atas masing-masing icon)
                  if (_activeTooltip != null)
                    Positioned(
                      bottom: 186,
                      left: (screenWidth - 210) / 2,
                      width: 210,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Tooltip Kiri (Tambah Pesanan)
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: GestureDetector(
                                onTap: () => _handleAction('pesanan'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: navyColor,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    TranslationService.translate('add_order'),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Divider placeholder
                          const SizedBox(width: 1.5),

                          // Tooltip Kanan (Tambah Akun)
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: GestureDetector(
                                onTap: () => _handleAction('akun'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: navyColor,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    TranslationService.translate('add_account'),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 2. White Rectangle Menu (Dua Icon Bersebelahan)
                  Positioned(
                    bottom: 96,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _translateAnimation.value),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 210,
                            height: 85,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade100, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Icon 1: Tambah Pesanan
                                SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => _handleAction('pesanan'),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFBCEFF2), // Soft bright brand cyan
                                              Color(0xFF42C6D4), // Standard brand cyan
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF42C6D4).withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.add_shopping_cart_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Divider Vertikal
                                Container(
                                  width: 1.5,
                                  height: 35,
                                  color: Colors.grey.shade100,
                                ),

                                // Icon 2: Tambah Akun
                                SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => _handleAction('akun'),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFBCEFF2), // Soft bright brand cyan
                                              Color(0xFF42C6D4), // Standard brand cyan
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF42C6D4).withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.person_add_alt_1_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Rotating Plus Button (Hanya Ikon di dalam yang berputar, background & bayangan tetap kokoh/static)
                  Positioned(
                    bottom: 22,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFBCEFF2), // Soft bright brand cyan
                            Color(0xFF42C6D4), // Standard brand cyan
                          ],
                        ),
                        boxShadow: [
                          // 3D bottom edge line (tipis)
                          BoxShadow(
                            color: const Color(0xFF0C4B8E).withOpacity(0.25),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                          // Soft ambient glow (tipis)
                          BoxShadow(
                            color: const Color(0xFF42C6D4).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: _closeDialog,
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: RotationTransition(
                            turns: _rotationAnimation,
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
