import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clabe.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../controllers/auth_controller.dart';

/// Datos de la cuenta. La CLABE y el banco se muestran en la tanda a quien le toca transferirte.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _clabe = TextEditingController();
  final _bank = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;
    _name.text = user?.fullName ?? '';
    _email.text = user?.email ?? '';
    _clabe.text = user?.clabe ?? '';
    _bank.text = user?.bankName ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _clabe, _bank]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: _name.text.trim(),
            email: _emptyToNull(_email.text),
            clabe: _emptyToNull(_clabe.text),
            bankName: _emptyToNull(_bank.text),
          );
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Tus datos quedaron guardados ✅'), backgroundColor: AppColors.primaryDark),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint, String? helper}) => InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(authControllerProvider).value?.phone ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Nombre completo', Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe tu nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: phone,
                    enabled: false,
                    decoration: _decoration(
                      'Teléfono',
                      Icons.phone_android_outlined,
                      helper: 'Es con lo que entras. Si cambió, pídele al organizador que lo corrija.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration('Correo (opcional)', Icons.alternate_email),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      return value.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                          ? null
                          : 'Correo no válido';
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Para recibir tu bolsa',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cuando te toque cobrar, en la tanda se verá tu banco y tu CLABE para que te transfieran.',
                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clabe,
                    keyboardType: TextInputType.number,
                    maxLength: 18,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration('CLABE interbancaria (18 dígitos)', Icons.numbers_outlined),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      if (value.length != 18) return 'La CLABE debe tener 18 dígitos';
                      if (!isValidClabe(value)) return 'La CLABE no es válida, revísala';
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _bank,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Banco', Icons.account_balance_outlined, hint: 'ej. BBVA, Nu, Banorte'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkBg),
                          )
                        : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
