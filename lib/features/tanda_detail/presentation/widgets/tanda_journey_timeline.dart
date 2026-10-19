import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class SlotItemData {
  final int slotNumber;
  final String userName;
  final String? avatarUrl;
  final DateTime dueDate;
  final double amount;
  final bool isCompleted;
  final bool isCurrent;
  final bool isAvailable;

  const SlotItemData({
    required this.slotNumber,
    required this.userName,
    this.avatarUrl,
    required this.dueDate,
    required this.amount,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isAvailable = false,
  });
}

class TandaJourneyTimeline extends StatelessWidget {
  final List<SlotItemData> slots;
  final Function(SlotItemData slot)? onSlotTap;

  const TandaJourneyTimeline({
    super.key,
    required this.slots,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final dateFormat = DateFormat('d MMM', 'es_MX');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isLast = index == slots.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea y Nodo indicador
            Column(
              children: [
                _buildNodeIndicator(slot),
                if (!isLast)
                  Container(
                    width: 3,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          slot.isCompleted ? AppColors.primary : AppColors.darkBorder,
                          (index + 1 < slots.length && slots[index + 1].isCompleted)
                              ? AppColors.primary
                              : AppColors.darkBorder,
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Tarjeta de Información del Turno con Vidrio Líquido
            Expanded(
              child: LiquidGlassContainer(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                borderRadius: BrandConfig.cardRadius,
                blur: slot.isCurrent ? 24 : 16,
                tintColor: slot.isCurrent
                    ? AppColors.gold
                    : (slot.isCompleted ? AppColors.primary : null),
                opacity: slot.isCurrent ? 0.14 : (slot.isCompleted ? 0.08 : 0.05),
                borderOpacity: slot.isCurrent ? 0.45 : (slot.isCompleted ? 0.25 : 0.15),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSlotTap?.call(slot);
                },
                child: Row(
                    children: [
                      // Avatar o Inicial
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: slot.isCurrent
                            ? AppColors.gold.withValues(alpha: 0.2)
                            : (slot.isCompleted
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.darkBorder),
                        child: Text(
                          slot.isAvailable ? '?' : slot.userName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: slot.isCurrent
                                ? AppColors.gold
                                : (slot.isCompleted ? AppColors.primary : Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Detalles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Turno #${slot.slotNumber}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: slot.isCurrent
                                        ? AppColors.gold
                                        : AppColors.darkTextSecondary,
                                  ),
                                ),
                                if (slot.isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      '¡Cobra ahora!',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slot.isAvailable ? 'Número disponible' : slot.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Monto y Fecha
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(slot.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: slot.isCurrent ? AppColors.gold : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(slot.dueDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: (index * 60).ms).slideX(begin: 0.05);
      },
    );
  }

  Widget _buildNodeIndicator(SlotItemData slot) {
    if (slot.isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppColors.darkBg, size: 18),
      );
    } else if (slot.isCurrent) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.gold,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.star, color: Colors.black, size: 20),
        ),
      );
    } else {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.darkBorder, width: 2),
        ),
        child: Center(
          child: Text(
            '${slot.slotNumber}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
