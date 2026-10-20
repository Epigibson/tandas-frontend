import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/realtime/tanda_realtime.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../shared/widgets/reset_code_dialog.dart';
import '../../../admin/presentation/screens/admin_screen.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../tanda_creator/data/models/tanda_model.dart';
import '../../../tanda_creator/presentation/screens/create_tanda_screen.dart';
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
  bool _isStarting = false;
  final Set<String> _reviewingPayments = {};

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

  Future<void> _handlePickAndSubmitReceipt(String roundId, {String? payerUserId, String? payerName}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null || !mounted) return;

    setState(() => _isUploading = true);
    HapticFeedback.lightImpact();

    try {
      await ref.read(tandaDetailActionsProvider).submitPaymentProof(
            roundId: roundId,
            file: pickedFile,
            tandaId: widget.tandaId,
            payerUserId: payerUserId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(payerName != null
                ? 'Registraste la aportación de ${payerName.split(' ').first}. Ahora apruébala en Aportaciones ✅'
                : '¡Comprobante subido! En espera de validación del organizador ⏱️'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Ejecutar el sorteo?'),
        content: const Text(
          'Se asignarán los turnos de forma aleatoria. Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sortear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReviewPayment({
    required String paymentId,
    required bool approved,
  }) async {
    String? rejectionReason;
    if (!approved) {
      rejectionReason = await _askRejectionReason();
      if (rejectionReason == null || !mounted) return;
    }

    setState(() => _reviewingPayments.add(paymentId));
    try {
      await ref.read(tandaDetailActionsProvider).reviewPayment(
            paymentId: paymentId,
            approved: approved,
            rejectionReason: rejectionReason,
            tandaId: widget.tandaId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'Aportación aprobada ✅' : 'Aportación rechazada'),
            backgroundColor: approved ? AppColors.primaryDark : AppColors.darkCard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _reviewingPayments.remove(paymentId));
      }
    }
  }

  Future<void> _openProof(String proofPath) async {
    final url = ApiClient.resolveFileUrl(proofPath);

    // Las URLs firmadas de Storage traen ?token=..., por eso se revisa solo la ruta
    if (Uri.parse(url).path.toLowerCase().endsWith('.pdf')) {
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el PDF'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : const CircularProgressIndicator(color: AppColors.primary),
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No se pudo cargar el comprobante. Puede que se haya borrado del servidor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruitingBanner({
    required bool isOrganizer,
    required int emptySlotsCount,
    DateTime? startDate,
  }) {
    final isFull = emptySlotsCount == 0;
    final message = isOrganizer
        ? (isFull
            ? '¡Ya están todos los lugares! Cuando quieras, inicia la tanda para abrir la primera ronda.'
            : 'Faltan $emptySlotsCount ${emptySlotsCount == 1 ? 'lugar' : 'lugares'} por apartar. Comparte el código para llenarlos.')
        : (isFull
            ? 'Todos los lugares están apartados. Esperando a que el organizador inicie la tanda.'
            : 'Reuniendo participantes: faltan $emptySlotsCount ${emptySlotsCount == 1 ? 'lugar' : 'lugares'}.');

    return LiquidGlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      blur: 0,
      tintColor: AppColors.gold,
      opacity: 0.08,
      borderOpacity: 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: const TextStyle(fontSize: 12, color: AppColors.darkTextPrimary)),
          if (startDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Fecha de inicio: ${DateFormat("d 'de' MMMM 'de' y", 'es_MX').format(startDate.toLocal())}',
                    style: const TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          if (isOrganizer && isFull) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: _isStarting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBg),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Iniciar tanda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.darkBg,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _isStarting ? null : _handleStartTanda,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleStartTanda() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Iniciar la tanda?'),
        content: const Text(
          'Se cierra el reclutamiento: ya no se podrán apartar, liberar ni sortear números, '
          'ni editar la tanda. La primera ronda empieza a recibir aportaciones desde hoy.',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Todavía no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isStarting = true);
    HapticFeedback.heavyImpact();
    try {
      await ref.read(tandaDetailActionsProvider).startTanda(tandaId: widget.tandaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Arrancó la tanda! La primera ronda ya recibe aportaciones 🚀'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _handleEditTanda(Map<String, dynamic> tanda) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateTandaScreen(tanda: TandaModel.fromJson(tanda))),
    );
    if (saved == true) {
      ref.invalidate(tandaDetailProvider(widget.tandaId));
    }
  }

  Future<void> _handleDeleteTanda(String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 40),
        title: Text('¿Eliminar "$title"?'),
        content: const Text(
          'Se borra la tanda con todos sus números apartados. Quienes ya entraron dejarán de verla. '
          'Esto no se puede deshacer.',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    HapticFeedback.heavyImpact();
    try {
      await ref.read(tandaDetailActionsProvider).deleteTanda(tandaId: widget.tandaId);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Eliminaste la tanda "$title"'),
          backgroundColor: AppColors.darkCard,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCreateResetCode({required String userId, required String userName}) async {
    try {
      final code = await ref.read(tandaDetailActionsProvider).createPasswordResetCode(
            tandaId: widget.tandaId,
            userId: userId,
          );
      if (!mounted) return;
      await showResetCodeDialog(context, code: code, userName: userName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<bool?> _confirmPayoutDialog(double amount) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Ya recibiste tu bolsa?'),
        content: Text(
          'Confirma solo si ya tienes los ${currencyFormat.format(amount)} en tu cuenta. '
          'Todos en la tanda verán que tu turno quedó pagado.',
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Todavía no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, ya la recibí'),
          ),
        ],
      ),
    );
  }

  /// Regresa null si el organizador cancela
  Future<String?> _askRejectionReason() {
    const defaultReason = 'Comprobante ilegible o monto incorrecto';
    final controller = TextEditingController(text: defaultReason);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rechazar aportación'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Motivo (lo verá el participante)',
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              final reason = controller.text.trim();
              Navigator.pop(dialogContext, reason.isEmpty ? defaultReason : reason);
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tandaAsync = ref.watch(tandaDetailProvider(widget.tandaId));
    // Mientras la pantalla esté abierta, los cambios de otros miembros llegan solos
    ref.watch(tandaRealtimeProvider(widget.tandaId));
    final currentUser = ref.watch(authControllerProvider).value;
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return tandaAsync.when(
      data: (tanda) {
        final title = tanda['title'] as String? ?? 'Detalle de Tanda';
        // El super admin tiene los mismos permisos que el organizador en cualquier tanda
        final isOrganizer = currentUser?.id == tanda['organizer_id'] || currentUser?.isSuperuser == true;
        final inviteCode = tanda['invite_code'] as String? ?? '';
        final tandaStatus = tanda['status'] as String? ?? 'recruiting';
        final isRecruiting = tandaStatus == 'recruiting' || tandaStatus == 'draft';
        final isDraw = tanda['assignment_method'] == 'draw';
        final startDate = DateTime.tryParse(tanda['start_date'] as String? ?? '');
        final slotsData = tanda['slots'] as List<dynamic>? ?? [];
        final roundsData = tanda['rounds'] as List<dynamic>? ?? [];

        // Solo se aceptan aportaciones en la ronda que está recaudando
        final collectingRound = roundsData.where((r) => r['status'] == 'collecting').firstOrNull;
        // La ronda en juego: recaudando o ya completa esperando la entrega de la bolsa
        final displayRound = roundsData
            .where((r) => r['status'] == 'collecting' || r['status'] == 'completed_pending_payout')
            .firstOrNull;
        final readyPayoutSlotNumbers = roundsData
            .where((r) => r['status'] == 'completed_pending_payout')
            .map((r) => (r['slot_number_beneficiary'] as num).toInt())
            .toSet();

        final payoutTotal = (tanda['payout_total'] as num?)?.toDouble() ?? 0.0;
        final expectedAmount = (displayRound?['expected_amount'] as num?)?.toDouble() ?? payoutTotal;
        final collectedAmount = (displayRound?['collected_amount'] as num?)?.toDouble() ?? 0.0;
        final roundNumber = (displayRound?['round_number'] as num?)?.toInt();
        final collectingRoundId = collectingRound?['id'] as String?;

        // Beneficiario del turno activo (no hay mientras no existan rondas)
        final beneficiarySlotNumber = (displayRound?['slot_number_beneficiary'] as num?)?.toInt();
        final beneficiarySlot = beneficiarySlotNumber == null
            ? null
            : slotsData.where((s) => s['slot_number'] == beneficiarySlotNumber).firstOrNull;
        final beneficiaryName = beneficiarySlot?['user']?['full_name'] as String? ?? 'Por asignar';

        final userSlots = slotsData.where((s) => s['user']?['id'] == currentUser?.id).toList();
        final emptySlotsCount = slotsData.where((s) => s['user'] == null).length;

        // Si ya mandó comprobante de esta ronda (en revisión o aprobado) no se le vuelve a ofrecer
        final payments = ref.watch(tandaPaymentsProvider(widget.tandaId)).value ?? const [];
        final paidThisRound = collectingRoundId == null
            ? const <String>{}
            : payments
                .where((p) =>
                    p['round_id'] == collectingRoundId &&
                    (p['status'] == 'submitted' || p['status'] == 'approved'))
                .map((p) => p['payer_user_id'] as String)
                .toSet();
        final alreadyPaidThisRound = paidThisRound.contains(currentUser?.id);

        // Mapear slots a SlotItemData para la línea de tiempo
        final mappedSlots = slotsData.map((s) {
          final slotId = s['id'] as String;
          final slotNum = (s['slot_number'] as num).toInt();
          final user = s['user'];
          final isUser = user != null && user['id'] == currentUser?.id;
          final fullName = user?['full_name'] as String? ?? 'Participante';
          final userName = user != null ? (isUser ? '$fullName (Tú)' : fullName) : 'Turno disponible';
          final scheduledDateStr = s['scheduled_payout_date'] as String?;
          final scheduledDate = scheduledDateStr != null ? DateTime.tryParse(scheduledDateStr)?.toLocal() : null;
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
            isPayoutReady: readyPayoutSlotNumbers.contains(slotNum),
            isAvailable: user == null,
          );
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              // El sorteo solo tiene sentido antes de arrancar la tanda y si no se eligieron números
              if (isOrganizer && isRecruiting && isDraw)
                IconButton(
                  icon: const Icon(Icons.casino_outlined, color: AppColors.gold),
                  tooltip: 'Ejecutar Sorteo Aleatorio',
                  onPressed: _handleTriggerDraw,
                ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.primary),
                tooltip: 'Compartir invitación',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final msg =
                      '¡Hola! Te invito a mi tanda "$title". Únete en la app con este código: $inviteCode 📱🎉';
                  SharePlus.instance.share(ShareParams(text: msg, subject: 'Invitación a la tanda "$title"'));
                },
              ),
              if (isOrganizer && isRecruiting)
                PopupMenuButton<String>(
                  // more_vert_rounded ya viene en la fuente de íconos de la versión instalada
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'Opciones de la tanda',
                  color: AppColors.darkSurface,
                  onSelected: (value) {
                    if (value == 'edit') _handleEditTanda(tanda);
                    if (value == 'delete') _handleDeleteTanda(title);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.stars_outlined, color: AppColors.primary),
                        title: Text('Editar tanda'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.remove_circle_outline, color: AppColors.error),
                        title: Text('Eliminar tanda', style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                  ],
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
                        children: [
                          const Icon(Icons.star, color: AppColors.gold, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              roundNumber != null
                                  ? 'Ronda Activa #$roundNumber de ${slotsData.length}'
                                  : 'Reuniendo participantes',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Con montos grandes o letra grande, la cápsula se encoge en vez de desbordarse
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Bolsa: ${currencyFormat.format(expectedAmount)}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                          Expanded(
                            child: Text(
                              'Recaudado: ${currencyFormat.format(collectedAmount)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    _withPullToRefresh(SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isRecruiting)
                            _buildRecruitingBanner(
                              isOrganizer: isOrganizer,
                              emptySlotsCount: emptySlotsCount,
                              startDate: startDate,
                            ),
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
                                      'Tus números: ${userSlots.map((s) => '#${s['slot_number']}').join(', ')} (${userSlots.length} ${userSlots.length == 1 ? 'número' : 'números'})'
                                          '${isRecruiting && emptySlotsCount > 0 ? ' • Toca cualquier número libre para apartar otro' : ''}',
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
                                tandaStatus: tandaStatus,
                                collectingRoundId: collectingRoundId,
                                paidUserIds: paidThisRound,
                              );
                            },
                          ),
                        ],
                      ),
                    )),

                    // Tab 2: Aportaciones en Vivo
                    _withPullToRefresh(_buildPaymentsTab(isOrganizer)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Solo los participantes aportan, y solo mientras una ronda está recaudando
      floatingActionButton: collectingRoundId == null || userSlots.isEmpty || alreadyPaidThisRound
          ? null
          : FloatingActionButton.extended(
            onPressed: _isUploading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _handlePickAndSubmitReceipt(collectingRoundId);
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
      // También llega aquí si el organizador eliminó la tanda mientras estaba abierta
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 40, color: AppColors.darkTextSecondary),
                const SizedBox(height: 12),
                Text(
                  e.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(tandaPaymentsProvider(widget.tandaId));
    ref.invalidate(tandaDetailProvider(widget.tandaId));
    try {
      await ref.read(tandaDetailProvider(widget.tandaId).future);
    } catch (_) {
      // El error ya se muestra en pantalla vía tandaDetailProvider
    }
  }

  Widget _withPullToRefresh(Widget scrollable) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.darkSurface,
      onRefresh: _refreshAll,
      child: scrollable,
    );
  }

  /// Mensaje dentro de una lista para que también se pueda jalar para refrescar
  Widget _scrollableMessage(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab(bool isOrganizer) {
    final paymentsAsync = ref.watch(tandaPaymentsProvider(widget.tandaId));
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final currentUserId = ref.watch(authControllerProvider).value?.id;

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _scrollableMessage('Aún no hay aportaciones registradas en esta tanda.');
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final p = payments[index] as Map<String, dynamic>;
            final paymentId = p['id'] as String;
            final payerName = p['payer']?['full_name'] ?? 'Participante';
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            final status = p['status'] as String;
            final isApproved = status == 'approved';
            final isPending = status == 'submitted';
            final isReviewing = _reviewingPayments.contains(paymentId);
            final proofUrl = p['proof_image_url'] as String?;
            final rejectionReason = p['rejection_reason'] as String?;
            final isMine = p['payer_user_id'] == currentUserId;
            final canSeeProof = proofUrl != null && (isOrganizer || isMine);
            // Cada ronda le paga al turno con su mismo número
            final roundNumber = (p['slot_number'] as num?)?.toInt();
            final statusColor = isApproved
                ? AppColors.primary
                : (isPending ? Colors.orange : Colors.red);
            final statusLabel = isApproved ? 'Aprobado' : (isPending ? 'En revisión' : 'Rechazado');

            return LiquidGlassContainer(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              borderRadius: BrandConfig.cardRadius,
              blur: 0, // Se repite por cada aportación: sin BackdropFilter por rendimiento
              opacity: isApproved ? 0.08 : (isPending ? 0.1 : 0.05),
              borderOpacity: isApproved ? 0.25 : (isPending ? 0.35 : 0.15),
              tintColor: isApproved
                  ? AppColors.primary
                  : (isPending ? Colors.orange : Colors.red),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: statusColor.withValues(alpha: 0.2),
                        child: Icon(
                          isApproved
                              ? Icons.check
                              : (isPending ? Icons.access_time : Icons.close),
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Expanded: con nombres largos o letra grande, el nombre se corta en vez de empalmarse
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              roundNumber != null ? '$statusLabel · Ronda $roundNumber' : statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyFormat.format(amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  if (status == 'rejected' && rejectionReason != null && (isOrganizer || isMine)) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Motivo: $rejectionReason${isMine ? ' • Puedes volver a enviar tu comprobante.' : ''}',
                        style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                      ),
                    ),
                  ],
                  if (canSeeProof)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        icon: const Icon(Icons.receipt_long_outlined, size: 16),
                        label: const Text('Ver comprobante'),
                        onPressed: () => _openProof(proofUrl),
                      ),
                    ),
                  if (isOrganizer && isPending) ...[
                    const SizedBox(height: 6),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 6),
                    // Botones a lo ancho: así caben aunque el teléfono tenga la letra grande
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red.withValues(alpha: 0.6)),
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Rechazar', maxLines: 1),
                            onPressed: isReviewing
                                ? null
                                : () => _handleReviewPayment(paymentId: paymentId, approved: false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.darkBg,
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Aprobar', maxLines: 1),
                            onPressed: isReviewing
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _handleReviewPayment(paymentId: paymentId, approved: true);
                                  },
                          ),
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
      error: (e, _) => _scrollableMessage(e.toString().replaceAll('Exception: ', '')),
    );
  }

  void _showSlotModal({
    required BuildContext context,
    required SlotItemData slot,
    required dynamic beneficiarySlot,
    required bool isOrganizer,
    required String? currentUserId,
    required String tandaStatus,
    required String? collectingRoundId,
    required Set<String> paidUserIds,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final isRecruiting = tandaStatus == 'recruiting' || tandaStatus == 'draft';
    final isMySlot = slot.userId != null && slot.userId == currentUserId;
    final isOthersSlot = slot.userId != null && !isMySlot;
    final canClaim = slot.isAvailable && isRecruiting;
    // El organizador (o el admin) también puede liberar el número de alguien más
    final canRelease = isRecruiting && (isMySlot || (isOrganizer && isOthersSlot));
    final payoutPending = slot.isPayoutReady && !slot.isCompleted;
    final canConfirmPayout = isMySlot && payoutPending;
    // Acciones a nombre de quien no usa la app
    final canConfirmForOther = isOrganizer && isOthersSlot && payoutPending;
    final canPayForOther = isOrganizer &&
        isOthersSlot &&
        collectingRoundId != null &&
        !paidUserIds.contains(slot.userId);
    final canAssign = isOrganizer && slot.isAvailable && isRecruiting;
    final firstName = slot.userName.replaceAll(' (Tú)', '').split(' ').first;
    final messenger = ScaffoldMessenger.of(context);

    Future<void> run(Future<void> Function() action, String success) async {
      HapticFeedback.mediumImpact();
      try {
        await action();
        messenger.showSnackBar(SnackBar(content: Text(success), backgroundColor: AppColors.primaryDark));
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SingleChildScrollView(
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
                          slot.dueDate != null
                              ? DateFormat('dd MMMM yyyy', 'es_MX').format(slot.dueDate!)
                              : 'Por definir',
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
                      // Se toma antes del await: el contexto del modal deja de existir al cerrarlo
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(sheetContext);
                      HapticFeedback.mediumImpact();
                      try {
                        await ref.read(tandaDetailActionsProvider).claimSlot(
                              slotId: slot.slotId,
                              tandaId: widget.tandaId,
                            );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('¡Apartaste el Turno #${slot.slotNumber}! 🎉 Puedes apartar más números si gustas.'),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (canConfirmPayout) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Ya recibí mi bolsa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.darkBg,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(sheetContext);
                      final confirmed = await _confirmPayoutDialog(slot.amount);
                      if (confirmed != true) return;
                      HapticFeedback.mediumImpact();
                      try {
                        await ref.read(tandaDetailActionsProvider).confirmPayout(
                              slotId: slot.slotId,
                              tandaId: widget.tandaId,
                            );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('¡Listo! Confirmaste que recibiste tu bolsa 💰'),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (canAssign) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('Darle este número a alguien'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final user = await showUserPicker(context);
                      if (user == null) return;
                      final name = (user['full_name'] as String).split(' ').first;
                      await run(
                        () => ref.read(tandaDetailActionsProvider).assignSlot(
                              slotId: slot.slotId,
                              userId: user['id'] as String,
                              tandaId: widget.tandaId,
                            ),
                        'Le diste el Turno #${slot.slotNumber} a $name',
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (canPayForOther) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: Text('Registrar la aportación de $firstName'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _handlePickAndSubmitReceipt(
                        collectingRoundId,
                        payerUserId: slot.userId,
                        payerName: slot.userName,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (canConfirmForOther) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.verified_outlined, size: 18, color: AppColors.gold),
                    label: Text('$firstName ya recibió su bolsa', style: const TextStyle(color: AppColors.gold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: AppColors.darkSurface,
                          title: Text('¿$firstName ya recibió su bolsa?'),
                          content: Text(
                            'Confírmalo solo si ya tiene los ${currencyFormat.format(slot.amount)}. '
                            'Se cierra la ronda y quedará registrado que lo confirmaste tú.',
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('Todavía no'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text('Sí, ya la recibió'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await run(
                        () => ref.read(tandaDetailActionsProvider).confirmPayout(
                              slotId: slot.slotId,
                              tandaId: widget.tandaId,
                            ),
                        'Listo: quedó confirmada la bolsa de $firstName 💰',
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (isOrganizer && slot.userId != null && !isMySlot) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.key_outlined, size: 18),
                    label: const Text('Código para cambiar su contraseña'),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _handleCreateResetCode(userId: slot.userId!, userName: slot.userName);
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (canRelease) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent, size: 18),
                    label: Text(
                      isMySlot ? 'Liberar este turno' : 'Quitarle este número a $firstName',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orangeAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      // Se toma antes del await: el contexto del modal deja de existir al cerrarlo
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(sheetContext);
                      HapticFeedback.lightImpact();
                      try {
                        await ref.read(tandaDetailActionsProvider).releaseSlot(
                              slotId: slot.slotId,
                              tandaId: widget.tandaId,
                            );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Turno #${slot.slotNumber} liberado con éxito'),
                            backgroundColor: AppColors.darkCard,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
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
