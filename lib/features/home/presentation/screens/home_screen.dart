import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../tanda_detail/presentation/screens/tanda_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
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

    return Scaffold(
      body: LiquidGlassBackground(
        child: SafeArea(
          child: CustomScrollView(
          slivers: [
            // AppBar personalizado
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                              gradient: BrandConfig.avatarGradient,
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
                                    fontSize: 12,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: AppColors.primary, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                '$score pts',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.darkTextSecondary, size: 22),
                          tooltip: 'Cerrar sesión',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ref.read(authControllerProvider.notifier).logout();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tarjeta de Resumen Financiero con Gradiente Premium
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: LiquidGlassContainer(
                  padding: const EdgeInsets.all(22),
                  borderRadius: 24,
                  blur: 14,
                  tintColor: AppColors.primary,
                  opacity: 0.12,
                  borderOpacity: 0.28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total en Tandas Activas',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '2 Tandas',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(20000),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Próximo a pagar',
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(1000),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  '31 Oct (Quincena)',
                                  style: TextStyle(color: AppColors.primary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 36, color: Colors.white12),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Próximo por cobrar',
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(10000),
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Turno #3 • 15 Nov',
                                  style: TextStyle(color: AppColors.gold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              ),
            ),

            // Botones de Acción Rápida
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    const SizedBox(width: 12),
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

            // Encabezado de Sección "Mis Tandas"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tandas de la Familia',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: AppColors.primary),
                      tooltip: 'Actualizar',
                      onPressed: () => ref.invalidate(myTandasProvider),
                    ),
                  ],
                ),
              ),
            ),

            // Lista Dinámica de Tandas desde Supabase
            ref.watch(myTandasProvider).when(
                  data: (tandas) {
                    if (tandas.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: LiquidGlassContainer(
                            padding: const EdgeInsets.all(24),
                            borderRadius: BrandConfig.cardRadius,
                            opacity: 0.08,
                            child: Column(
                              children: [
                                const Icon(Icons.group_outlined, size: 48, color: AppColors.primary),
                                const SizedBox(height: 12),
                                const Text(
                                  'Aún no tienes tandas activas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Crea tu primera tanda familiar o únete con un código de WhatsApp.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
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
                            context: context,
                            title: tanda.title,
                            frequency: '${tanda.frequency.toUpperCase()} • \$${tanda.contributionAmount.toStringAsFixed(0)} MXN',
                            currentSlot: 1,
                            totalSlots: tanda.totalSlots,
                            potAmount: tanda.payoutTotal,
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
                      child: Text('Error al cargar tandas: $err'),
                    ),
                  ),
                ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    ),
  );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = controller.text.trim();
                if (code.isEmpty) return;
                Navigator.pop(context);
                try {
                  await ref.read(tandaCreatorControllerProvider.notifier).joinTanda(code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Te has unido a la tanda con éxito! 🎉'),
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      borderRadius: BrandConfig.buttonRadius,
      opacity: 0.08,
      borderOpacity: 0.25,
      tintColor: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTandaCard({
    required BuildContext context,
    required String title,
    required String frequency,
    required int currentSlot,
    required int totalSlots,
    required double potAmount,
    required bool isOrganizer,
    required VoidCallback onTap,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final progress = currentSlot / totalSlots;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: LiquidGlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        borderRadius: BrandConfig.cardRadius,
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
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOrganizer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Organizador',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                frequency,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Turno actual: $currentSlot de $totalSlots',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Bolsa: ${currencyFormat.format(potAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.darkSurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      );
  }
}
