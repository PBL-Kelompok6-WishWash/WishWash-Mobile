import 'package:flutter/material.dart';

class HoverLinkText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onTap;

  const HoverLinkText({
    super.key,
    required this.text,
    required this.style,
    required this.onTap,
  });

  @override
  State<HoverLinkText> createState() => _HoverLinkTextState();
}

class _HoverLinkTextState extends State<HoverLinkText> {
  bool _isActive = false;

  @override
  Widget build(BuildContext context) {
    // Deteksi otomatis apakah teks tebal (bold)
    final bool isBold = widget.style.fontWeight == FontWeight.bold ||
        widget.style.fontWeight == FontWeight.w600 ||
        widget.style.fontWeight == FontWeight.w700 ||
        widget.style.fontWeight == FontWeight.w800 ||
        widget.style.fontWeight == FontWeight.w900;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isActive = true),
      onExit: (_) => setState(() => _isActive = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isActive = true),
        onTapUp: (_) => setState(() => _isActive = false),
        onTapCancel: () => setState(() => _isActive = false),
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: widget.style.copyWith(
            decoration: _isActive ? TextDecoration.underline : TextDecoration.none,
            decorationColor: widget.style.color, 
            decorationThickness: isBold ? 2.5 : 1.0, 
          ),
        ),
      ),
    );
  }
}