import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/brand_config.dart';

/// =========================================================================
/// 🧪 LIQUID GLASS DESIGN SYSTEM (GLASSMORPHISM DE ALTA PRECISIÓN)
/// =========================================================================

/// Contenedor de Vidrio Líquido con desenfoque de fondo (BackdropFilter),
/// reflejo especular en bordes y brillo refractivo translúcido.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? tintColor;
  final double opacity;
  final double borderOpacity;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = BrandConfig.cardRadius,
    this.blur = 18.0,
    this.tintColor,
    this.opacity = 0.08,
    this.borderOpacity = 0.22,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tintColor ?? Colors.white;

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              if (tintColor != null)
                BoxShadow(
                  color: tintColor!.withValues(alpha: 0.12),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              // Gradiente de refracción líquida (brillo suave en ángulo de luz)
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveTint.withValues(alpha: opacity + 0.06),
                  effectiveTint.withValues(alpha: opacity * 0.5),
                  effectiveTint.withValues(alpha: opacity * 0.1),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              // Borde biselado con reflejo de luz superior
              border: Border.all(
                color: effectiveTint.withValues(alpha: borderOpacity),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Fondo Ambiental Líquido con orbes de luz orgánica difusa.
/// Coloca esto detrás de tu Scaffold o CustomScrollView para que el vidrio
/// líquido tenga colores que refractar y cobre vida.
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;
  final Color orbColor1;
  final Color orbColor2;
  final Color orbColor3;

  const LiquidGlassBackground({
    super.key,
    required this.child,
    this.orbColor1 = BrandConfig.primary,
    this.orbColor2 = BrandConfig.secondary,
    this.orbColor3 = const Color(0xFF005A44),
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Fondo base profundo
        Container(
          width: double.infinity,
          height: double.infinity,
          color: BrandConfig.darkBackground,
        ),

        // Orbe 1: Luz Esmeralda / Primaria Superior Derecha
        Positioned(
          top: -60,
          right: -80,
          child: Container(
            width: size.width * 0.75,
            height: size.width * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orbColor1.withValues(alpha: 0.18),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Orbe 2: Luz Ámbar / Dorada Centro-Izquierda
        Positioned(
          top: size.height * 0.35,
          left: -100,
          child: Container(
            width: size.width * 0.65,
            height: size.width * 0.65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orbColor2.withValues(alpha: 0.12),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Orbe 3: Luz Profunda Inferior Derecha
        Positioned(
          bottom: -80,
          right: -40,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orbColor3.withValues(alpha: 0.22),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Contenido de la pantalla encima del líquido
        child,
      ],
    );
  }
}

/// Botón estilizado con efecto Vidrio Líquido pulido
class LiquidGlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final Color? tintColor;
  final EdgeInsetsGeometry padding;

  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.tintColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final tint = tintColor ?? BrandConfig.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(BrandConfig.buttonRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            splashColor: tint.withValues(alpha: 0.2),
            highlightColor: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BrandConfig.buttonRadius),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BrandConfig.buttonRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tint.withValues(alpha: 0.18),
                    tint.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: tint.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: tint, size: 20),
                    const SizedBox(width: 8),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
