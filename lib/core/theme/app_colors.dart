import 'package:flutter/material.dart';

abstract final class AppColors {
  static bool isDark = false;

  static const _background = Color(0xFFF5F5F5);
  static const _surface = Color(0xFFFFFFFF);
  static const _cardDark = Color(0xFF1A1A1A);

  static const _textPrimary = Color(0xFF000000);
  static const _textSecondary = Color(0xFF6B7280);
  static const _textOnDark = Color(0xFFFFFFFF);

  static const lavender = Color(0xFFE8DFF5);
  static const mint = Color(0xFFD3EDE2);
  static const peach = Color(0xFFF9E8D9);
  static const skyBlue = Color(0xFFD6EAF8);

  static const accent = Color(0xFF2DD4BF);
  static const error = Color(0xFFEF4444);
  static const _border = Color(0xFFE5E7EB);

  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const _darkTextSecondary = Color(0xFF9CA3AF);
  static const _darkBorder = Color(0xFF374151);

  static Color get background => isDark ? darkBackground : _background;
  static Color get surface => isDark ? darkSurface : _surface;
  static Color get cardDark => isDark ? _surface : _cardDark;

  static Color get textPrimary => isDark ? _textOnDark : _textPrimary;
  static Color get textSecondary => isDark ? _darkTextSecondary : _textSecondary;
  static Color get textOnDark => isDark ? _textPrimary : _textOnDark;

  static Color get border => isDark ? _darkBorder : _border;
}
