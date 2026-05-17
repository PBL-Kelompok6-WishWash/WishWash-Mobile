import 'dart:math';
import 'package:flutter/material.dart';

class BubbleBackground extends StatefulWidget {
  const BubbleBackground({super.key});

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<_Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    // Animasi akan terus berulang (loop), perlambat menjadi 25 detik per siklus
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 20)
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Buat daftar gelembung jika belum ada
    if (_bubbles.isEmpty) {
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < 40; i++) { // Jumlah gelembung diperbanyak (40)
        _bubbles.add(
          _Bubble(
            x: _random.nextDouble() * size.width, 
            startOffset: _random.nextDouble(), 
            // Ukuran kelereng (10) hingga bola sepak (130)
            size: 10.0 + _random.nextDouble() * 120.0, 
            // Kecepatan sangat bervariasi tapi secara umum lambat
            speedMultiplier: 0.3 + _random.nextDouble() * 0.8,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        return Stack(
          children: _bubbles.map((bubble) {
            double progress = (_controller.value * bubble.speedMultiplier + bubble.startOffset) % 1.0;
            double currentY = size.height * (1.2 - (progress * 1.4)); 
            double wobbleX = sin(progress * pi * 4) * 20;

            return Positioned(
              left: bubble.x + wobbleX,
              top: currentY,
              child: Container(
                width: bubble.size,
                height: bubble.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.4), 
                      Colors.white.withOpacity(0.1), 
                      Colors.white.withOpacity(0.0), 
                    ],
                    stops: const [0.1, 0.6, 1.0],
                    center: const Alignment(-0.3, -0.3), 
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3), 
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Bubble {
  final double x;
  final double startOffset;
  final double size;
  final double speedMultiplier;

  _Bubble({
    required this.x,
    required this.startOffset,
    required this.size,
    required this.speedMultiplier,
  });
}
