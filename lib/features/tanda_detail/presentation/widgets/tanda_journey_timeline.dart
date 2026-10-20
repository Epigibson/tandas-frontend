import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class SlotItemData {
  final String slotId;
  final int slotNumber;
  final String userName;
  final String? userId;
  final String? avatarUrl;
  final DateTime dueDate;
  final double amount;
  final bool isCompleted;
  final bool isCurrent;
  final bool isAvailable;

  const SlotItemData({
    required this.slotId,
    required this.slotNumber,
    required this.userName,
    this.userId,
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
                    width: 2.5,
                    height: 38,
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
            const SizedBox(width: 12),

            // Tarjeta de Información del Turno Compacta
            Expanded(
              child: LiquidGlassContainer(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                blur: slot.isCurrent ? 16 : 12,
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
                        radius: 17,
                        backgroundColor: slot.isCurrent
                            ? AppColors.gold.withValues(alpha: 0.2)
                            : (slot.isCompleted
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.darkBorder),
                        child: Text(
                          slot.isAvailable ? '?' : slot.userName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: slot.isCurrent
                                ? AppColors.gold
                                : (slot.isCompleted ? AppColors.primary : Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

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
                                    fontSize: 11,
                                    color: slot.isCurrent
                                        ? AppColors.gold
                                        : AppColors.darkTextSecondary,
                                  ),
                                ),
                                if (slot.isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '¡Cobra ahora!',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot.isAvailable ? 'Número disponible' : slot.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Monto y Fecha
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(slot.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: slot.isCurrent ? AppColors.gold : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(slot.dueDate),
                            style: const TextStyle(
                              fontSize: 11,
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
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppColors.darkBg, size: 14),
      );
    } else if (slot.isCurrent) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.gold,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.star, color: Colors.black, size: 15),
        ),
      );
    } else {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.darkBorder, width: 1.5),
        ),
        child: Center(
          child: Text(
            '${slot.slotNumber}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
