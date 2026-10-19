import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
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

        // Mapear slots a SlotItemData para la línea de tiempo
        final mappedSlots = slotsData.map((s) {
          final slotNum = s['slot_number'] as int;
          final user = s['user'];
          final isUser = user != null && user['id'] == currentUser?.id;
          final userName = user != null ? (isUser ? '${user['full_name']} (Tú)' : user['full_name']) : 'Turno disponible';
          final scheduledDateStr = s['scheduled_payout_date'] as String?;
          final scheduledDate = scheduledDateStr != null ? DateTime.parse(scheduledDateStr) : DateTime.now();
          final isCurrent = slotNum == beneficiarySlotNumber;
          final isCompleted = s['payout_status'] == 'confirmed';

          return SlotItemData(
            slotNumber: slotNum,
            userName: userName,
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
          body: Column(
            children: [
              // Tarjeta de Ronda Activa
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.gold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Ronda Activa #$roundNumber de ${slotsData.length}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Bolsa: ${currencyFormat.format(expectedAmount)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Beneficiario(a) de la bolsa:',
                        style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            beneficiaryName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currencyFormat.format(expectedAmount),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recaudado: ${currencyFormat.format(collectedAmount)}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          Text(
                            expectedAmount > 0
                                ? '${((collectedAmount / expectedAmount) * 100).toInt()}%'
                                : '0%',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: expectedAmount > 0 ? (collectedAmount / expectedAmount) : 0.0,
                          backgroundColor: Colors.black26,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                      child: TandaJourneyTimeline(
                        slots: mappedSlots,
                        onSlotTap: (slot) {
                          _showSlotModal(context, slot, beneficiarySlot, isOrganizer, currentUser?.id);
                        },
                      ),
                    ),

                    // Tab 2: Aportaciones en Vivo
                    _buildPaymentsTab(isOrganizer),
                  ],
                ),
              ),
            ],
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

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
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

  void _showSlotModal(
    BuildContext context,
    SlotItemData slot,
    dynamic beneficiarySlot,
    bool isOrganizer,
    String? currentUserId,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Turno #${slot.slotNumber} • ${slot.userName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Fecha programada de cobro: ${DateFormat('dd MMMM yyyy', 'es_MX').format(slot.dueDate)}',
                style: const TextStyle(color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance, color: AppColors.primary),
                title: const Text('Bolsa total a recibir'),
                trailing: Text(
                  currencyFormat.format(slot.amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
