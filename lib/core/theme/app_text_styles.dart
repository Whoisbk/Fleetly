import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get _base => GoogleFonts.inter();

  static TextStyle pageTitle({Color? color}) => _base.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle sectionTitle({Color? color}) => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle metric({Color? color}) => _base.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: color ?? AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle body({Color? color}) => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle label({Color? color}) => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle button({Color? color}) => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textOnDark,
      );
}
