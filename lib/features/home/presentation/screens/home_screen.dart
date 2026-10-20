import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/realtime/tanda_realtime.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../tanda_detail/presentation/screens/tanda_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../tanda_creator/data/models/tanda_model.dart';
import '../../../tanda_creator/presentation/controllers/tanda_controller.dart';
import '../../../tanda_creator/presentation/screens/create_tanda_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final currentUser = ref.watch(authControllerProvider).value;
    final displayName = currentUser?.fullName ?? 'Compadre';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';
    final score = currentUser?.tandaScore ?? 100;

    final tandasAsync = ref.watch(myTandasProvider);
    final tandasList = tandasAsync.asData?.value ?? [];
    final activeTandas = tandasList.where((t) => t.status != 'completed' && t.status != 'cancelled').toList();
    final totalPots = activeTandas.fold<double>(0.0, (acc, t) => acc + t.payoutTotal);
    // Se aporta una cuota por cada número que tengas en la tanda
    final contributionPerRound = activeTandas.fold<double>(
      0.0,
      (acc, t) => acc + t.contributionAmount * t.mySlotNumbers.length,
    );
    final tandasCount = activeTandas.length;
    final upcomingPayouts = activeTandas.where((t) => t.myNextPayoutDate != null).toList()
      ..sort((a, b) => a.myNextPayoutDate!.compareTo(b.myNextPayoutDate!));
    final nextPayout = upcomingPayouts.isNotEmpty ? upcomingPayouts.first : null;

    // Escucha en vivo las tandas de la lista: cualquier cambio recarga el Home
    for (final tanda in tandasList) {
      ref.watch(tandaRealtimeProvider(tanda.id));
    }

    return Scaffold(
      body: LiquidGlassBackground(
        child: SafeArea(
          child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () => ref.refresh(myTandasProvider.future),
          child: CustomScrollView(
          // Permite jalar para refrescar aunque la lista sea corta
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar personalizado compacto
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 1.5),
                              gradient: BrandConfig.avatarGradient,
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  BrandConfig.greeting,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge de Reputación
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: AppColors.primary, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                '$score pts',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.darkTextSecondary, size: 20),
                          tooltip: 'Cerrar sesión',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ref.read(authControllerProvider.notifier).logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tarjeta de Resumen Financiero con Gradiente Premium Compacto
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: LiquidGlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  borderRadius: 18,
                  blur: 12,
                  tintColor: AppColors.primary,
                  opacity: 0.10,
                  borderOpacity: 0.25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bolsas de tus tandas activas',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$tandasCount ${tandasCount == 1 ? 'Tanda' : 'Tandas'}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(totalPots),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Aportas por ronda',
                                  style: TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currencyFormat.format(contributionPerRound),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  activeTandas.isNotEmpty
                                      ? 'Sumando todas tus tandas'
                                      : 'Sin pagos pendientes',
                                  style: TextStyle(
                                    color: activeTandas.isNotEmpty ? AppColors.primary : Colors.white38,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 28, color: Colors.white12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Próximo por cobrar',
                                  style: TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currencyFormat.format(nextPayout?.payoutTotal ?? 0),
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  nextPayout != null
                                      ? '${nextPayout.title} · ${DateFormat('d MMM', 'es_MX').format(nextPayout.myNextPayoutDate!.toLocal())}'
                                      : 'Sin cobros pendientes',
                                  style: TextStyle(
                                    color: nextPayout != null ? AppColors.gold : Colors.white38,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
              ),
            ),

            // Botones de Acción Rápida Compactos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.add_circle_outline,
                        label: 'Nueva Tanda',
                        color: AppColors.primary,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateTandaScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.qr_code_scanner,
                        label: 'Unirme con Link',
                        color: AppColors.gold,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showJoinDialog(context, ref);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Encabezado de Sección "Mis Tandas" Compacto
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tandas de la Familia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                      tooltip: 'Actualizar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => ref.invalidate(myTandasProvider),
                    ),
                  ],
                ),
              ),
            ),

            // Lista Dinámica de Tandas desde Supabase Compacta
            ref.watch(myTandasProvider).when(
                  data: (tandas) {
                    if (tandas.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: LiquidGlassContainer(
                            padding: const EdgeInsets.all(18),
                            borderRadius: 16,
                            opacity: 0.08,
                            child: Column(
                              children: [
                                const Icon(Icons.group_outlined, size: 36, color: AppColors.primary),
                                const SizedBox(height: 8),
                                const Text(
                                  'Aún no tienes tandas activas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Crea tu primera tanda familiar o únete con un código de WhatsApp.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CreateTandaScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('¡Crear mi Primera Tanda!'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tanda = tandas[index];
                          final isOrganizer = currentUser?.id == tanda.organizerId;

                          return _buildTandaCard(
                            tanda: tanda,
                            isOrganizer: isOrganizer,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TandaDetailScreen(tandaId: tanda.id),
                                ),
                              );
                            },
                          );
                        },
                        childCount: tandas.length,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(err.toString().replaceAll('Exception: ', '')),
                    ),
                  ),
                ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
        ),
      ),
    ),
  );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Unirme a una Tanda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pega el código de invitación que te compartieron por WhatsApp:',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'ej. TANDA-A1B2C3',
                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = controller.text.trim();
                if (code.isEmpty) return;
                // Se toma antes del await: el contexto del diálogo deja de existir al cerrarlo
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);
                try {
                  await ref.read(tandaCreatorControllerProvider.notifier).joinTanda(code);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('¡Te has unido a la tanda con éxito! 🎉'),
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
              child: const Text('Unirme'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LiquidGlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 10),
      borderRadius: 14,
      opacity: 0.08,
      borderOpacity: 0.25,
      tintColor: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTandaCard({
    required TandaModel tanda,
    required bool isOrganizer,
    required VoidCallback onTap,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final totalSlots = tanda.totalSlots;
    final currentRound = tanda.currentRoundNumber;
    final isRunning = tanda.status == 'active' && currentRound != null;
    final statusLabel = switch (tanda.status) {
      'draft' || 'recruiting' => 'Reuniendo participantes · $totalSlots lugares',
      'active' => currentRound != null ? 'Turno actual: $currentRound de $totalSlots' : 'En curso',
      'completed' => 'Terminada',
      'cancelled' => 'Cancelada',
      _ => '$totalSlots turnos',
    };
    final frequency = '${tanda.frequency.toUpperCase()} • ${currencyFormat.format(tanda.contributionAmount)} MXN';
    final myNumbers = tanda.mySlotNumbers.map((n) => '#$n').join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: LiquidGlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        blur: 0, // Se repite en la lista: sin BackdropFilter por rendimiento
        opacity: 0.07,
        borderOpacity: 0.2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tanda.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOrganizer)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Organizador',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              myNumbers.isNotEmpty ? '$frequency • Tus números: $myNumbers' : frequency,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    statusLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Bolsa: ${currencyFormat.format(tanda.payoutTotal)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (isRunning) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: currentRound / totalSlots,
                  backgroundColor: AppColors.darkSurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
