import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/presentation/screens/admin_screen.dart';
import '../controllers/auth_controller.dart';
import '../screens/profile_screen.dart';

/// Pide la huella y registra este teléfono. Devuelve true si quedó activada.
Future<bool> enableBiometricFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final user = ref.read(authControllerProvider).value;
  if (user == null) return false;

  try {
    final ok = await ref.read(biometricServiceProvider).authenticate('Confirma tu huella para activarla en Tanditas');
    if (!ok) return false;
    await ref.read(authRepositoryProvider).enableBiometric(user);
    ref.invalidate(biometricAccountProvider);
    HapticFeedback.mediumImpact();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('¡Listo! La próxima vez entra con tu huella 👆'),
        backgroundColor: AppColors.primaryDark,
      ),
    );
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.error,
      ),
    );
    return false;
  }
}

Future<void> disableBiometricFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  await ref.read(authRepositoryProvider).disableBiometric();
  ref.invalidate(biometricAccountProvider);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Desactivaste la huella en este teléfono'),
      backgroundColor: AppColors.darkCard,
    ),
  );
}

/// Después de entrar con contraseña, ofrece una sola vez activar la huella
class BiometricOfferGate extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricOfferGate({super.key, required this.child});

  @override
  ConsumerState<BiometricOfferGate> createState() => _BiometricOfferGateState();
}

class _BiometricOfferGateState extends ConsumerState<BiometricOfferGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOffer());
  }

  Future<void> _maybeOffer() async {
    if (!ref.read(biometricOfferProvider)) return;
    ref.read(biometricOfferProvider.notifier).consume();

    final user = ref.read(authControllerProvider).value;
    final account = await ref.read(biometricAccountProvider.future);
    if (!mounted || user == null || account?.userId == user.id) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.fingerprint, color: AppColors.primary, size: 44),
        title: const Text('¿Entrar con huella?'),
        content: const Text(
          'La próxima vez entra a Tanditas con tu huella, sin escribir tu contraseña. '
          'Puedes apagarlo cuando quieras desde tu perfil.',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) await enableBiometricFlow(context, ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Hoja con los datos de la cuenta, el interruptor de huella y cerrar sesión
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AccountSheet(),
  );
}

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet();

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  bool _busy = false;
  late final Future<bool> _biometricAvailable;

  @override
  void initState() {
    super.initState();
    _biometricAvailable = ref.read(biometricServiceProvider).isAvailable();
  }

  Future<void> _toggleBiometric(bool enable) async {
    setState(() => _busy = true);
    if (enable) {
      await enableBiometricFlow(context, ref);
    } else {
      await disableBiometricFlow(context, ref);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final account = ref.watch(biometricAccountProvider).value;
    final biometricOn = account != null && account.userId == user?.id;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.fullName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.phone ?? '',
              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            FutureBuilder<bool>(
              future: _biometricAvailable,
              builder: (context, snapshot) {
                if (snapshot.data != true) return const SizedBox.shrink();
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                  title: const Text('Entrar con huella'),
                  subtitle: const Text(
                    'Sin escribir tu contraseña en este teléfono',
                    style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                  ),
                  value: biometricOn,
                  activeThumbColor: AppColors.primary,
                  onChanged: _busy ? null : _toggleBiometric,
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: AppColors.primary),
              title: const Text('Mi perfil'),
              subtitle: Text(
                user?.clabe == null ? 'Agrega tu CLABE para recibir tu bolsa' : 'Nombre, correo y datos bancarios',
                style: TextStyle(
                  fontSize: 12,
                  color: user?.clabe == null ? AppColors.gold : AppColors.darkTextSecondary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            if (user?.isSuperuser == true)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.verified_outlined, color: AppColors.gold),
                title: const Text('Panel de administrador'),
                subtitle: const Text(
                  'Todas las tandas y los datos de cada persona',
                  style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                },
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
