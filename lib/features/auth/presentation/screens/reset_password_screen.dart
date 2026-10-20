import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../controllers/auth_controller.dart';

/// Cambia la contraseña con el código temporal que genera el organizador de una tanda
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String initialIdentifier;

  const ResetPasswordScreen({super.key, this.initialIdentifier = ''});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _identifierController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(text: widget.initialIdentifier);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            phoneOrEmail: _identifierController.text.trim(),
            code: _codeController.text,
            newPassword: _passwordController.text,
          );
      TextInput.finishAutofillContext();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Listo! Ya cambiaste tu contraseña 🔐'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      // Al regresar, AuthGate ya muestra el Home porque la sesión quedó iniciada
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LiquidGlassContainer(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BrandConfig.cardRadius,
                  blur: 0,
                  tintColor: AppColors.gold,
                  opacity: 0.08,
                  borderOpacity: 0.3,
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pídele al organizador de tu tanda un código para cambiar tu contraseña. '
                          'Lo genera desde tu turno en la tanda y dura 30 minutos.',
                          style: TextStyle(fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: _inputDecoration(label: 'Teléfono o correo', icon: Icons.person_outline),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Escribe tu teléfono o correo' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                            LengthLimitingTextInputFormatter(9),
                          ],
                          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
                          decoration: _inputDecoration(
                            label: 'Código',
                            hint: 'XXXX-XXXX',
                            icon: Icons.key_outlined,
                          ),
                          validator: (val) {
                            final code = (val ?? '').replaceAll('-', '');
                            return code.length != 8 ? 'El código tiene 8 caracteres' : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: _inputDecoration(
                            label: 'Contraseña nueva',
                            hint: 'Mínimo 6 caracteres',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.darkTextSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) =>
                              (val == null || val.length < 6) ? 'Debe tener al menos 6 caracteres' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleReset(),
                          decoration: _inputDecoration(label: 'Repite la contraseña', icon: Icons.lock_reset),
                          validator: (val) =>
                              val != _passwordController.text ? 'Las contraseñas no coinciden' : null,
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleReset,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.darkBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(BrandConfig.buttonRadius),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkBg),
                                )
                              : const Text(
                                  'Cambiar contraseña y entrar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.darkSurface.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandConfig.inputRadius),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandConfig.inputRadius),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandConfig.inputRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
