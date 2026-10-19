import 'package:flutter/material.dart';

/// =========================================================================
/// 🎨 ARCHIVO CENTRAL DE BRANDING Y DISEÑO (SINGLE SOURCE OF TRUTH)
/// =========================================================================
/// Si quieres cambiar el nombre de la app, los colores, las tipografías,
/// los bordes redondeados o los gradientes de TODA la aplicación,
/// SOLO MODIFICA ESTE ARCHIVO.
/// =========================================================================

enum BrandThemePreset {
  emeraldFintech, // Esmeralda / Menta Neón / Oro (Predeterminado)
  royalPurple,    // Estilo Nu: Púrpura Profundo / Neón / Lima
  midnightBlue,   // Estilo Revolut: Azul Marino / Cian Eléctrico
  cyberGold,      // Dorado / Grafito Oscuro / Bronce
}

class BrandConfig {
  // -----------------------------------------------------------------------
  // 🏷️ 1. IDENTIDAD DE MARCA (NOMBRES Y TEXTOS CLAVE)
  // -----------------------------------------------------------------------
  static const String appName = 'Tandas México';
  static const String appShortName = 'Tandas';
  static const String appTagline = 'Ahorro familiar claro, puntual y sin fricción.';
  static const String greeting = '¡Hola, compadre!';
  static const String currencySymbol = '\$';
  static const String currencyCode = 'MXN';

  // -----------------------------------------------------------------------
  // 🎨 2. SELECTOR RÁPIDO DE PRESET (O PERSONALIZA ABAJO DIRECTAMENTE)
  // -----------------------------------------------------------------------
  static const BrandThemePreset activePreset = BrandThemePreset.emeraldFintech;

  // -----------------------------------------------------------------------
  // 🌈 3. PALETA DE COLORES PRINCIPAL
  // -----------------------------------------------------------------------
  // Color de acción principal (botones, checks, elementos activos)
  static const Color primary = Color(0xFF00C896); // Menta neón fintech
  static const Color primaryDark = Color(0xFF09392E); // Bosque esmeralda
  static const Color primaryLight = Color(0xFFE6F9F4);

  // Acento secundario (turnos que cobran, trofeos, medallas, dinero acumulado)
  static const Color secondary = Color(0xFFFFB800); // Dorado / Oro
  static const Color secondaryDark = Color(0xFFB38100);

  // Modo Oscuro (OLED Premium)
  static const Color darkBackground = Color(0xFF0D1312);
  static const Color darkSurface = Color(0xFF151E1C);
  static const Color darkCard = Color(0xFF1B2825);
  static const Color darkBorder = Color(0xFF263834);
  static const Color darkTextPrimary = Color(0xFFF1F5F4);
  static const Color darkTextSecondary = Color(0xFF8FA7A0);

  // Modo Claro Minimalista
  static const Color lightBackground = Color(0xFFF7FAF9);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE4EDE9);
  static const Color lightTextPrimary = Color(0xFF11221F);
  static const Color lightTextSecondary = Color(0xFF5A726C);

  // Colores de Estado del Sistema
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // -----------------------------------------------------------------------
  // 📐 4. DIMENSIONES Y ESTILOS DE FORMA (UI TOKENS)
  // -----------------------------------------------------------------------
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double inputRadius = 16.0;
  static const double chipRadius = 12.0;
  static const double modalRadius = 24.0;

  // -----------------------------------------------------------------------
  // 🌟 5. GRADIENTES DE MARCA
  // -----------------------------------------------------------------------
  // Gradiente de la tarjeta principal de balance financiero en Home
  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F4B3C),
      Color(0xFF092921),
      Color(0xFF061A15),
    ],
  );

  // Gradiente del avatar del usuario
  static const LinearGradient avatarGradient = LinearGradient(
    colors: [primary, primaryDark],
  );

  // Gradiente de la tarjeta de resumen en creación de tandas
  static const LinearGradient createSummaryGradient = LinearGradient(
    colors: [primaryDark, Color(0xFF08221B)],
  );
}
