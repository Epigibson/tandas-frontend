import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Una pestaña de [PillTabBar]: ícono y texto.
class PillTab {
  final IconData icon;
  final String label;

  const PillTab(this.icon, this.label);
}

/// Pestañas en forma de pastilla: la seleccionada se rellena de menta y se desliza al cambiar.
/// Solo usa íconos que ya trae la versión instalada, para que llegue por parche de Shorebird.
class PillTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<PillTab> tabs;
  final TabController? controller;
  final EdgeInsetsGeometry margin;

  const PillTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.margin = const EdgeInsets.fromLTRB(16, 4, 16, 10),
  });

  static const double _height = 50;

  @override
  Size get preferredSize => const Size.fromHeight(_height + 14);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        height: _height,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: TabBar(
          controller: controller,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF00A97F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          labelColor: AppColors.darkBg,
          unselectedLabelColor: AppColors.darkTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: [
            for (final tab in tabs)
              Tab(
                height: _height - 8,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 18),
                      const SizedBox(width: 8),
                      Text(tab.label, maxLines: 1),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
