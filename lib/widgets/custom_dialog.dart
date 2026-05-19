import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    String? confirmText,
    String? cancelText,
    bool isSuccess = false,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: cancelText != null,
      barrierLabel: 'CustomDialog',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final double curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value;
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0C4B8E), // Navy
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      if (cancelText != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              cancelText,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSuccess ? const Color(0xFF42C6D4) : const Color(0xFF0C4B8E), // Cyan or Navy
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: Text(
                            confirmText ?? 'OK',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Predefined gorgeous alerts
  static Future<bool?> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF10B981), // Emerald Green
      iconBgColor: const Color(0xFFECFDF5), // Emerald light tint
      confirmText: 'OK',
      isSuccess: true,
    );
  }

  static Future<bool?> showError({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFEF4444), // Red
      iconBgColor: const Color(0xFFFEF2F2), // Red light tint
      confirmText: 'OK',
    );
  }

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      icon: Icons.help_outline_rounded,
      iconColor: const Color(0xFFF59E0B), // Amber
      iconBgColor: const Color(0xFFFFFBEB), // Amber light tint
      confirmText: confirmText,
      cancelText: cancelText,
    );
  }
}
