import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5E35B1);
  static const Color secondary = Color(0xFF3949AB);
  static const Color background = Color(0xFFE9E1F7);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFFA000);
  static const Color danger = Color(0xFFD32F2F);
  static const Color card = Color(0xFFF7F4FF);
  static const Color cardAccent = Color(0xFFEFF3FF);
  static const Color cardWarm = Color(0xFFFFF8EE);
  static const Color textPrimary = Color(0xFF241B3A);
  static const Color textSecondary = Color(0xFF6B617C);
  static const Color border = Color(0xFFE4DDF4);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [Color(0xFFE2D6F4), Color(0xFFF2ECFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get cardGradient => const LinearGradient(
    colors: [card, cardAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient softCardGradient(Color accent) => LinearGradient(
    colors: [card, accent.withValues(alpha: 0.12)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
