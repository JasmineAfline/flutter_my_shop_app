import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightScaffoldColor = Color(0xFFF8F9FE);
  static const Color lightPrimaryColor = Color(0xFF6366F1);
  static const Color lightPrimaryColorDark = Color(0xFF4F46E5);
  static const Color lightCardColor = Colors.white;
  
  // Dark Theme Colors  
  static const Color darkScaffoldColor = Color(0xFF0F0F1A);
  static const Color darkPrimaryColor = Color(0xFF818CF8);
  static const Color darkCardColor = Color(0xFF1A1A2E);
  
  // Accent Colors
  static const Color accentColor = Color(0xFF10B981);
  static const Color accentColorLight = Color(0xFF34D399);
  
  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];
  
  static const List<Color> primaryGradientLight = [
    Color(0xFF6366F1),
    Color(0xFFA78BFA),
  ];
  
  static const List<Color> darkGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
  ];
  
  // Text Colors
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  
  // Border Colors
  static const Color lightBorderColor = Color(0xFFE5E7EB);
  static const Color darkBorderColor = Color(0xFF374151);
  
  // Shimmer Colors
  static const Color shimmerBaseLight = Color(0xFFE5E7EB);
  static const Color shimmerHighlightLight = Color(0xFFF9FAFB);
  static const Color shimmerBaseDark = Color(0xFF1F2937);
  static const Color shimmerHighlightDark = Color(0xFF374151);
}
