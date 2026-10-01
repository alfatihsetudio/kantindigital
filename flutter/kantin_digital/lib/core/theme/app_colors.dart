import 'package:flutter/material.dart';

/// Modern Liquid Glass + Gojek-inspired color palette
/// Soft, translucent, with beautiful gradients
class AppColors {
  // ═══════════════════════════════════════════════════════════
  // PRIMARY COLORS - Base Palette
  // ═══════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF6F4E37); // Default Coffee Brown
  static const Color primaryDark = Color(0xFF3E2723);
  static const Color primaryLight = Color(0xFFEFEBE9);
  static const Color primarySoft = Color(0xFFD7CCC8);
  
  // Primary Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8D6E63), Color(0xFF6F4E37)],
  );

  // ═══════════════════════════════════════════════════════════
  // LIQUID GLASS COLORS - Translucent & Frosted Effects
  // ═══════════════════════════════════════════════════════════
  static const Color glassWhite = Color(0xE6FFFFFF); // 90% white
  static const Color glassSoft = Color(0xCCFFFFFF); // 80% white
  static const Color glassCard = Color(0xF2FFFFFF); // 95% white
  static const Color glassOverlay = Color(0x33FFFFFF); // 20% white for overlays
  static const Color glassBorder = Color(0x1A000000); // Very subtle dark border
  static const Color glassHighlight = Color(0x40FFFFFF); // For inner glow
  
  // Glass Gradient (for cards)
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xF5FFFFFF), Color(0xE8F8F8F8)],
  );

  // ═══════════════════════════════════════════════════════════
  // BACKGROUNDS - Soft, warm, and inviting
  // ═══════════════════════════════════════════════════════════
  static const Color background = Color(0xFFF6F7F9); // Soft cool grey
  static const Color backgroundWarm = Color(0xFFFDFDFD); // Almost white
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFEFEFE);
  
  // Mesh Gradient Background Effect Colors
  static const Color meshGradient1 = Color(0xFFEFEBE9);
  static const Color meshGradient2 = Color(0xFFF0F4FF); // Light blue
  static const Color meshGradient3 = Color(0xFFFFF8E8); // Light warm yellow

  // ═══════════════════════════════════════════════════════════
  // STATUS COLORS - Modern & Vibrant
  // ═══════════════════════════════════════════════════════════
  static const Color success = Color(0xFF00C853); // Brighter green
  static const Color successLight = Color(0xFFE8F8ED);
  static const Color danger = Color(0xFFFF3B3B);
  static const Color dangerLight = Color(0xFFFFEBEB);
  static const Color warning = Color(0xFFFF9500);
  static const Color warningLight = Color(0xFFFFF5E6);
  static const Color info = Color(0xFF007AFF);
  static const Color infoLight = Color(0xFFE8F2FF);

  // ═══════════════════════════════════════════════════════════
  // TEXT & NEUTRALS - Clear hierarchy
  // ═══════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFF1A1D1F); // Rich black
  static const Color textSecondary = Color(0xFF6F767E); // Medium grey
  static const Color textMuted = Color(0xFFA4A8AE); // Light grey
  static const Color muted = textSecondary; // Alias for legacy
  static const Color textOnPrimary = Colors.white;
  
  // ═══════════════════════════════════════════════════════════
  // BORDERS & DIVIDERS - Subtle & Soft
  // ═══════════════════════════════════════════════════════════
  static const Color border = Color(0xFFE8EAED);
  static const Color borderLight = Color(0xFFF2F3F5);
  static const Color divider = Color(0xFFF0F1F3);
  
  // ═══════════════════════════════════════════════════════════
  // SHADOWS - Soft & Diffused
  // ═══════════════════════════════════════════════════════════
  static const Color shadowLight = Color(0x08000000); // 3%
  static const Color shadowMedium = Color(0x12000000); // 7%
  static const Color shadowDark = Color(0x1F000000); // 12%
  
  // ═══════════════════════════════════════════════════════════
  // CATEGORY COLORS - For food categories chips
  // ═══════════════════════════════════════════════════════════
  static const Color categoryFood = Color(0xFFFF6B35);
  static const Color categoryDrink = Color(0xFF4ECDC4);
  static const Color categorySnack = Color(0xFFFFE66D);
  static const Color categoryDessert = Color(0xFFFF8ED2);
}
