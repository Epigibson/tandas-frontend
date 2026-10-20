import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../tanda_detail/presentation/screens/tanda_detail_screen.dart';
import '../controllers/tanda_controller.dart';

/// Antes de entrar con un código: muestra la tanda y, en elección libre, deja escoger los números
class JoinTandaScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const JoinTandaScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<JoinTandaScreen> createState() => _JoinTandaScreenState();
}

class _JoinTandaScreenState extends ConsumerState<JoinTandaScreen> {
  final Set<int> _selected = {};
  bool _joining = false;

  static const _frequencyLabels = {
    'semanal': 'Cada semana',
    'catorcenal': 'Cada 14 días',
    'quincenal': 'Días 15 y último de mes',
    'mensual': 'Cada mes',
  };

  void _openDetail(String tandaId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TandaDetailScreen(tandaId: tandaId)),
    );
  }

  Future<void> _join({required bool freeChoice}) async {
    setState(() => _joining = true);
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final numbers = _selected.toList()..sort();
      final tandaId = await ref
          .read(tandaCreatorControllerProvider.notifier)
          .joinTanda(widget.inviteCode, slotNumbers: freeChoice ? numbers : const []);
      messenger.showSnackBar(
        SnackBar(
          content: Text(freeChoice
              ? '¡Listo! Apartaste ${numbers.map((n) => '#$n').join(', ')} 🎉'
              : '¡Te uniste a la tanda! 🎉'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      if (mounted) _openDetail(tandaId);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      if (!mounted) return;
      // Si alguien más ganó el número, se vuelve a pedir el tablero actualizado
      setState(() {
        _selected.clear();
        _joining = false;
      });
      ref.invalidate(invitePreviewProvider(widget.inviteCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(invitePreviewProvider(widget.inviteCode));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirme a una tanda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidGlassBackground(
        child: SafeArea(
          child: preview.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => _buildMessage(
              icon: Icons.info_outline,
              text: e.toString().replaceAll('Exception: ', ''),
            ),
            data: _buildContent,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.darkTextSecondary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> tanda) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final slots = (tanda['slots'] as List<dynamic>).cast<Map<String, dynamic>>();
    final freeCount = slots.where((s) => s['taken'] != true).length;
    final isRecruiting = tanda['status'] == 'recruiting' || tanda['status'] == 'draft';
    final freeChoice = tanda['assignment_method'] == 'first_come';
    final alreadyMember = tanda['already_member'] == true;
    final startDate = DateTime.tryParse(tanda['start_date'] as String? ?? '')?.toLocal();
    final contribution = (tanda['contribution_amount'] as num).toDouble();
    final description = tanda['description'] as String?;

    final Widget? bottomButton;
    if (alreadyMember) {
      bottomButton = ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Ya estás en esta tanda: ver tanda'),
        onPressed: () => _openDetail(tanda['id'] as String),
      );
    } else if (!isRecruiting || freeCount == 0) {
      bottomButton = null;
    } else {
      final numbers = _selected.toList()..sort();
      final label = !freeChoice
          ? 'Unirme a la tanda'
          : numbers.isEmpty
              ? 'Elige tu número'
              : numbers.length == 1
                  ? 'Entrar con el #${numbers.first}'
                  : 'Entrar con ${numbers.length} números';
      bottomButton = ElevatedButton(
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: _joining || (freeChoice && numbers.isEmpty) ? null : () => _join(freeChoice: freeChoice),
        child: _joining
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkBg),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(invitePreviewProvider(widget.inviteCode));
              await ref.read(invitePreviewProvider(widget.inviteCode).future).catchError((_) => tanda);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                LiquidGlassContainer(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 18,
                  tintColor: AppColors.primary,
                  opacity: 0.1,
                  borderOpacity: 0.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tanda['title'] as String,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organiza: ${tanda['organizer_name']}',
                        style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(description, style: const TextStyle(fontSize: 13)),
                      ],
                      const SizedBox(height: 14),
                      _infoRow(Icons.receipt_long_outlined, 'Aportas ${currencyFormat.format(contribution)} por número en cada ronda'),
                      _infoRow(Icons.account_balance_outlined,
                          'Bolsa de ${currencyFormat.format((tanda['payout_total'] as num).toDouble())} por turno'),
                      _infoRow(Icons.refresh, _frequencyLabels[tanda['frequency']] ?? tanda['frequency'] as String),
                      if (startDate != null)
                        _infoRow(Icons.access_time,
                            'Inicia el ${DateFormat("d 'de' MMMM 'de' y", 'es_MX').format(startDate)}'),
                      _infoRow(Icons.group_outlined,
                          '$freeCount de ${tanda['total_slots']} ${freeCount == 1 ? 'lugar libre' : 'lugares libres'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!isRecruiting && !alreadyMember)
                  _notice('Esta tanda ya inició y no acepta nuevos participantes.')
                else if (freeCount == 0 && !alreadyMember)
                  _notice('Ya no quedan lugares libres en esta tanda.')
                else if (!alreadyMember && !freeChoice)
                  _notice('Tu número se define con el sorteo que hace el organizador antes de iniciar.')
                else if (!alreadyMember) ...[
                  const Text(
                    'Elige tu número',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Puedes apartar más de uno. Cada número es una aportación por ronda y una bolsa.',
                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: slots.map(_buildSlotTile).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (bottomButton != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(width: double.infinity, child: bottomButton),
          ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _notice(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildSlotTile(Map<String, dynamic> slot) {
    final number = (slot['slot_number'] as num).toInt();
    final taken = slot['taken'] == true;
    final selected = _selected.contains(number);
    final date = DateTime.tryParse(slot['scheduled_payout_date'] as String? ?? '')?.toLocal();
    final caption = taken
        ? (slot['holder_first_name'] as String? ?? 'Apartado')
        : (date != null ? DateFormat('d MMM', 'es_MX').format(date) : 'Libre');

    final color = selected
        ? AppColors.primary
        : taken
            ? AppColors.darkTextSecondary
            : AppColors.darkTextPrimary;

    return Semantics(
      button: !taken,
      selected: selected,
      label: taken ? 'Número $number, apartado por $caption' : 'Número $number, libre, cobra el $caption',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: taken || _joining
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() => selected ? _selected.remove(number) : _selected.add(number));
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : taken
                    ? Colors.black26
                    : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.darkBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '#$number',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  decoration: taken ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
