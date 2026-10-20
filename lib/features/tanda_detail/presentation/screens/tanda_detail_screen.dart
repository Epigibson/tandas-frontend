import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/tanda_detail_controller.dart';
import '../widgets/tanda_journey_timeline.dart';

class TandaDetailScreen extends ConsumerStatefulWidget {
  final String tandaId;

  const TandaDetailScreen({super.key, required this.tandaId});

  @override
  ConsumerState<TandaDetailScreen> createState() => _TandaDetailScreenState();
}

class _TandaDetailScreenState extends ConsumerState<TandaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePickAndSubmitReceipt(String roundId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    HapticFeedback.lightImpact();

    try {
      await ref.read(tandaDetailActionsProvider).submitPaymentProof(
            roundId: roundId,
            filePath: pickedFile.path,
            tandaId: widget.tandaId,
          );

      if (mounted) {
        Navigator.pop(context); // Cierra bottomsheet si estaba abierto
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Comprobante subido! En espera de validación del organizador ⏱️'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleTriggerDraw() async {
    HapticFeedback.heavyImpact();
    try {
      await ref.read(tandaDetailActionsProvider).triggerDraw(tandaId: widget.tandaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Sorteo ejecutado con éxito! Turnos asignados aleatoriamente 🎲🎉'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el sorteo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tandaAsync = ref.watch(tandaDetailProvider(widget.tandaId));
    final currentUser = ref.watch(authControllerProvider).value;
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return tandaAsync.when(
      data: (tanda) {
        final title = tanda['title'] as String? ?? 'Detalle de Tanda';
        final isOrganizer = currentUser?.id == tanda['organizer_id'];
        final inviteCode = tanda['invite_code'] as String? ?? '';
        final slotsData = tanda['slots'] as List<dynamic>? ?? [];
        final roundsData = tanda['rounds'] as List<dynamic>? ?? [];

        // Ronda activa (primera collecting o upcoming)
        final activeRound = roundsData.firstWhere(
          (r) => r['status'] == 'collecting',
          orElse: () => roundsData.isNotEmpty ? roundsData.first : null,
        );

        final expectedAmount = (activeRound?['expected_amount'] as num?)?.toDouble() ?? 10000.0;
        final collectedAmount = (activeRound?['collected_amount'] as num?)?.toDouble() ?? 0.0;
        final roundNumber = (activeRound?['round_number'] as num?)?.toInt() ?? 1;
        final activeRoundId = activeRound?['id'] as String? ?? '';

        // Beneficiario del turno activo
        final beneficiarySlotNumber = (activeRound?['slot_number_beneficiary'] as num?)?.toInt() ?? 1;
        final beneficiarySlot = slotsData.firstWhere(
          (s) => s['slot_number'] == beneficiarySlotNumber,
          orElse: () => null,
        );
        final beneficiaryName = beneficiarySlot?['user']?['full_name'] ?? 'Por asignar';

        final userSlots = slotsData.where((s) => s['user']?['id'] == currentUser?.id).toList();

        // Mapear slots a SlotItemData para la línea de tiempo
        final mappedSlots = slotsData.map((s) {
          final slotId = s['id'] as String;
          final slotNum = s['slot_number'] as int;
          final user = s['user'];
          final isUser = user != null && user['id'] == currentUser?.id;
          final userName = user != null ? (isUser ? '${user['full_name']} (Tú)' : user['full_name']) : 'Turno disponible';
          final scheduledDateStr = s['scheduled_payout_date'] as String?;
          final scheduledDate = scheduledDateStr != null ? DateTime.parse(scheduledDateStr) : DateTime.now();
          final isCurrent = slotNum == beneficiarySlotNumber;
          final isCompleted = s['payout_status'] == 'confirmed';

          return SlotItemData(
            slotId: slotId,
            slotNumber: slotNum,
            userName: userName,
            userId: user?['id'] as String?,
            dueDate: scheduledDate,
            amount: expectedAmount,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isAvailable: user == null,
          );
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (isOrganizer)
                IconButton(
                  icon: const Icon(Icons.casino_outlined, color: AppColors.gold),
                  tooltip: 'Ejecutar Sorteo Aleatorio',
                  onPressed: _handleTriggerDraw,
                ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.primary),
                tooltip: 'Compartir código por WhatsApp',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final msg =
                      '¡Hola! Te invito a mi tanda "$title". Únete en la app con este código: $inviteCode 📱🎉';
                  Clipboard.setData(ClipboardData(text: msg));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensaje de invitación copiado para WhatsApp 💬'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
              ),
            ],
          ),
          body: LiquidGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // Tarjeta de Ronda Activa con Vidrio Líquido Ámbar Compacta
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: LiquidGlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: 16,
                      blur: 14,
                      tintColor: AppColors.gold,
                      opacity: 0.12,
                      borderOpacity: 0.35,
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.gold, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Ronda Activa #$roundNumber de ${slotsData.length}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Bolsa: ${currencyFormat.format(expectedAmount)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Beneficiario(a) de la bolsa:',
                        style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              beneficiaryName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currencyFormat.format(expectedAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recaudado: ${currencyFormat.format(collectedAmount)}',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                          Text(
                            expectedAmount > 0
                                ? '${((collectedAmount / expectedAmount) * 100).toInt()}%'
                                : '0%',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: expectedAmount > 0 ? (collectedAmount / expectedAmount) : 0.0,
                          backgroundColor: Colors.black26,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selector de Pestañas
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.darkTextSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                tabs: const [
                  Tab(text: 'El Camino (Turnos)'),
                  Tab(text: 'Aportaciones'),
                ],
              ),

              // Contenido de las Pestañas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: El Camino de la Tanda
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (userSlots.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tus números: ${userSlots.map((s) => '#${s['slot_number']}').join(', ')} (${userSlots.length} ${userSlots.length == 1 ? 'número' : 'números'}) • Toca cualquier número libre para apartar otro sin límite',
                                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TandaJourneyTimeline(
                            slots: mappedSlots,
                            onSlotTap: (slot) {
                              _showSlotModal(
                                context: context,
                                slot: slot,
                                beneficiarySlot: beneficiarySlot,
                                isOrganizer: isOrganizer,
                                currentUserId: currentUser?.id,
                                tandaStatus: tanda['status'] as String? ?? 'recruiting',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Aportaciones en Vivo
                    _buildPaymentsTab(isOrganizer),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (activeRoundId.isNotEmpty) {
                _handlePickAndSubmitReceipt(activeRoundId);
              }
            },
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.darkBg,
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBg),
                  )
                : const Icon(Icons.receipt_long),
            label: Text(
              _isUploading ? 'Subiendo...' : 'Registrar Aportación',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Error al cargar la tanda: $e'),
        ),
      ),
    );
  }

  Widget _buildPaymentsTab(bool isOrganizer) {
    final paymentsAsync = ref.watch(tandaPaymentsProvider(widget.tandaId));
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aún no hay aportaciones registradas en esta tanda.',
                style: TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final p = payments[index] as Map<String, dynamic>;
            final paymentId = p['id'] as String;
            final payerName = p['payer']?['full_name'] ?? 'Participante';
            final amount = (p['amount'] as num).toDouble();
            final status = p['status'] as String;
            final isApproved = status == 'approved';
            final isPending = status == 'submitted';

            return LiquidGlassContainer(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              borderRadius: BrandConfig.cardRadius,
              opacity: isApproved ? 0.08 : (isPending ? 0.1 : 0.05),
              borderOpacity: isApproved ? 0.25 : (isPending ? 0.35 : 0.15),
              tintColor: isApproved
                  ? AppColors.primary
                  : (isPending ? Colors.orange : Colors.red),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isApproved
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : (isPending
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2)),
                            child: Icon(
                              isApproved
                                  ? Icons.check
                                  : (isPending ? Icons.access_time : Icons.close),
                              color: isApproved
                                  ? AppColors.primary
                                  : (isPending ? Colors.orange : Colors.red),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(payerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                isApproved ? 'Aprobado' : (isPending ? 'En revisión' : 'Rechazado'),
                                style: TextStyle(
                                  color: isApproved
                                      ? AppColors.primary
                                      : (isPending ? Colors.orange : Colors.red),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        currencyFormat.format(amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  if (isOrganizer && isPending) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            ref.read(tandaDetailActionsProvider).reviewPayment(
                                  paymentId: paymentId,
                                  approved: false,
                                  rejectionReason: 'Comprobante ilegible o monto incorrecto',
                                  tandaId: widget.tandaId,
                                );
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.darkBg,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(tandaDetailActionsProvider).reviewPayment(
                                  paymentId: paymentId,
                                  approved: true,
                                  tandaId: widget.tandaId,
                                );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error al cargar pagos: $e')),
    );
  }

  void _showSlotModal({
    required BuildContext context,
    required SlotItemData slot,
    required dynamic beneficiarySlot,
    required bool isOrganizer,
    required String? currentUserId,
    required String tandaStatus,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final isMySlot = slot.userId != null && slot.userId == currentUserId;
    final canClaim = slot.isAvailable && (tandaStatus == 'recruiting' || tandaStatus == 'draft');
    final canRelease = isMySlot && (tandaStatus == 'recruiting' || tandaStatus == 'draft');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Turno #${slot.slotNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (isMySlot)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Tu Turno',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (slot.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Disponible',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                slot.isAvailable ? 'Este número está libre (puedes apartarlo para ti)' : slot.userName,
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fecha de cobro:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(
                          DateFormat('dd MMMM yyyy', 'es_MX').format(slot.dueDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bolsa total a recibir:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(
                          currencyFormat.format(slot.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (canClaim) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: Text('¡Apartar Turno #${slot.slotNumber} para mí!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.darkBg,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                      try {
                        await ref.read(tandaDetailActionsProvider).claimSlot(
                              slotId: slot.slotId,
                              tandaId: widget.tandaId,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('¡Apartaste el Turno #${slot.slotNumber}! 🎉 Puedes apartar más números si gustas.'),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (canRelease) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent, size: 18),
                    label: const Text('Liberar este turno', style: TextStyle(color: Colors.orangeAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orangeAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      HapticFeedback.lightImpact();
                      try {
                        await ref.read(tandaDetailActionsProvider).releaseSlot(
                              slotId: slot.slotId,
                              tandaId: widget.tandaId,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Turno #${slot.slotNumber} liberado con éxito'),
                              backgroundColor: AppColors.darkCard,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
