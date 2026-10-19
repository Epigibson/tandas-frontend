import 'package:flutter/material.dart';
import 'brand_config.dart';

/// AppColors actúa como puente directo hacia BrandConfig.
/// Para cambiar colores o estilos globales, edita: `brand_config.dart`.
class AppColors {
  // Primarios
  static const Color primary = BrandConfig.primary;
  static const Color primaryDark = BrandConfig.primaryDark;
  static const Color primaryLight = BrandConfig.primaryLight;

  // Acentos de Turno Dorado / Oro
  static const Color gold = BrandConfig.secondary;
  static const Color goldLight = Color(0xFFFFF7E6);
  static const Color goldDark = BrandConfig.secondaryDark;

  // Modo Oscuro
  static const Color darkBg = BrandConfig.darkBackground;
  static const Color darkSurface = BrandConfig.darkSurface;
  static const Color darkCard = BrandConfig.darkCard;
  static const Color darkBorder = BrandConfig.darkBorder;
  static const Color darkTextPrimary = BrandConfig.darkTextPrimary;
  static const Color darkTextSecondary = BrandConfig.darkTextSecondary;

  // Modo Claro
  static const Color lightBg = BrandConfig.lightBackground;
  static const Color lightSurface = BrandConfig.lightSurface;
  static const Color lightCard = BrandConfig.lightCard;
  static const Color lightBorder = BrandConfig.lightBorder;
  static const Color lightTextPrimary = BrandConfig.lightTextPrimary;
  static const Color lightTextSecondary = BrandConfig.lightTextSecondary;

  // Estados
  static const Color success = BrandConfig.success;
  static const Color warning = BrandConfig.warning;
  static const Color error = BrandConfig.error;
  static const Color info = BrandConfig.info;
}
