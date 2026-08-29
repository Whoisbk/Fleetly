import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppDecorations {
  static const radiusSmall = 16.0;
  static const radiusMedium = 24.0;
  static const radiusLarge = 32.0;

  static BorderRadius get cardRadius => BorderRadius.circular(radiusMedium);
  static BorderRadius get pillRadius => BorderRadius.circular(100);

  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: cardRadius,
      );

  static BoxDecoration pastelCard(Color color) => BoxDecoration(
        color: color,
        borderRadius: cardRadius,
      );

  static BoxDecoration darkHeroCard() => BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(radiusLarge),
      );
}
