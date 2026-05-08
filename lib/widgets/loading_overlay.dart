import 'dart:async'; // 💡 Pastikan ada import ini untuk Timer
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/constants.dart';

// --- Widget Utama ---
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({ // 💡 Nama ini harus sama dengan 'class LoadingOverlay'
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Constants.colorCyan.withValues(alpha:0.8),
                  Colors.white.withValues(alpha:0.9),
                ],
                radius: 1.0,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/laundry_loading.json',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -70),
                    child: const LoadingText(), // Memanggil widget teks animasi
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// --- Widget Teks Animasi (Baris 67 biasanya ada di sekitar sini) ---
class LoadingText extends StatefulWidget {
  const LoadingText({super.key}); // 💡 CEK DISINI: Nama harus 'LoadingText'

  @override
  State<LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<LoadingText> {
  int _dotCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dots = "." * _dotCount;
    return Text(
      "Loading$dots",
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Constants.colorDarkBlue,
      ),
    );
  }
}