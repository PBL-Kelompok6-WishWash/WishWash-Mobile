import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import '../widgets/bubble_background.dart';
import '../services/translation_service.dart';

import 'dart:async';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _slides = [
    {
      'title': 'landing_title',
      'subtitle': 'landing_subtitle',
    },
    {
      'title': 'landing_title_2',
      'subtitle': 'landing_subtitle_2',
    },
    {
      'title': 'landing_title_3',
      'subtitle': 'landing_subtitle_3',
    },
    {
      'title': 'landing_title_4',
      'subtitle': 'landing_subtitle_4',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white, // Putih di atas
                  Constants.colorLightIce, // Transisi ice blue di tengah
                  Constants.colorCyan, // Cyan di bawah
                ],
                stops: [0.3, 0.7, 1.0], // Mengatur titik persebaran gradasi
              ),
            ),
            child: Stack(
              children: [
                const BubbleBackground(), // Animasi gelembung sabun terbang
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0.0, // Parent horizontal padding set to 0 to allow edge-to-edge sliding!
                                vertical: 40.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Spacer(flex: 2), // Mendorong logo agak ke tengah atas
                                  
                                  // --- BAGIAN LOGO ---
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                    child: Column(
                                      children: [
                                        Image.asset('assets/images/brand/logo.png', height: 100),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Wish Wash',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                            color: Constants.colorDarkBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Spacer(flex: 3), // Mendorong teks dan tombol ke bawah
                                  
                                  // --- BAGIAN TEKS PROMO SLIDER ---
                                  SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 120, // Reduced from 160 to 120 for closer spacing
                                          child: PageView.builder(
                                            controller: _pageController,
                                            onPageChanged: (int index) {
                                              setState(() {
                                                _currentPage = index;
                                              });
                                              _startTimer(); // Reset timer upon manual interaction
                                            },
                                            itemCount: _slides.length,
                                            itemBuilder: (context, index) {
                                              final slide = _slides[index];
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 30.0), // Padding inside PageView item so it glides edge-to-edge!
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.end, // Closer to indicators
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      TranslationService.translate(slide['title']!),
                                                      textAlign: TextAlign.left,
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.w900,
                                                        color: Constants.colorDarkBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      TranslationService.translate(slide['subtitle']!),
                                                      textAlign: TextAlign.left,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: Constants.colorDarkBlue,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 32), // Spacing between text and dots
                                
                                        // --- DOT INDICATORS ---
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center, // Centered Carousel Indicators!
                                          children: List.generate(
                                            _slides.length,
                                            (index) => AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              margin: const EdgeInsets.only(right: 6),
                                              height: 8,
                                              width: _currentPage == index ? 24 : 8,
                                              decoration: BoxDecoration(
                                                color: _currentPage == index
                                                    ? Constants.colorDarkBlue
                                                    : Constants.colorDarkBlue.withValues(alpha: 0.3),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  // --- BAGIAN TOMBOL ---
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                    child: Column(
                                      children: [
                                        // Tombol Sign In (Cyan Gradient, Border Putih)
                                        Container(
                                          width: double.infinity,
                                          height: 55,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white, width: 1.5),
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF80DEEA), Color(0xFF00BCD4)], // Cyan terang ke dalam
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const LoginScreen(),
                                                  ),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(14),
                                              splashColor: Colors.white.withValues(alpha: 0.4),
                                              highlightColor: Colors.black.withValues(alpha: 0.1),
                                              child: Center(
                                                child: Text(
                                                  TranslationService.translate('sign_in'),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16), // Jarak antar tombol
                                        // 2. Tombol Create Account (Putih/Ice Gradient, Border Navy)
                                        Container(
                                          width: double.infinity,
                                          height: 55,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Constants.colorDarkBlue, width: 1.5),
                                            gradient: const LinearGradient(
                                              colors: [Colors.white, Color(0xFFF0F8FF)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const RegisterScreen(),
                                                  ),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(14),
                                              splashColor: Constants.colorDarkBlue.withValues(alpha: 0.15),
                                              highlightColor: Colors.black.withValues(alpha: 0.05),
                                              child: Center(
                                                child: Text(
                                                  TranslationService.translate('create_account'),
                                                  style: const TextStyle(
                                                    color: Constants.colorDarkBlue,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ), // end SafeArea
              ], // end Stack children
            ), // end Stack
          ), // end Container
        ); // end Scaffold
      },
    );
  }
}
