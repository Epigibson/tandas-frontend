import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../controllers/auth_controller.dart';
import '../../../home/presentation/screens/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _clabeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _clabeController.dispose();
    _bankNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await ref.read(authControllerProvider.notifier).register(
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
            fullName: _fullNameController.text.trim(),
            password: _passwordController.text,
            clabe: _clabeController.text.trim().isNotEmpty ? _clabeController.text.trim() : null,
            bankName: _bankNameController.text.trim().isNotEmpty ? _bankNameController.text.trim() : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada con éxito! Bienvenido a las Tandas 🎉'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Únete a la Tanda',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Completa tus datos para organizar o participar en tandas con tu familia y amigos.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Nombre Completo
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _buildInputDecoration(
                    label: 'Nombre Completo',
                    hint: 'ej. Mariana López',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor escribe tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Teléfono
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    label: 'Teléfono Móvil (10 dígitos)',
                    hint: '5512345678',
                    icon: Icons.phone_android_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor escribe tu número';
                    }
                    if (val.trim().length < 10) {
                      return 'El número debe tener al menos 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Correo Opcional
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    label: 'Correo Electrónico (Opcional)',
                    hint: 'ejemplo@correo.com',
                    icon: Icons.alternate_email_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _buildInputDecoration(
                    label: 'Contraseña',
                    hint: 'Mínimo 6 caracteres',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.darkTextSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sección Opcional de Datos Bancarios (CLABE)
                LiquidGlassContainer(
                  padding: const EdgeInsets.all(18),
                  borderRadius: BrandConfig.cardRadius,
                  opacity: 0.08,
                  borderOpacity: 0.25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Para recibir tus tandas (Opcional)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Facilita que el organizador te transfiera tu pozo directo por SPEI.',
                        style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _clabeController,
                        keyboardType: TextInputType.number,
                        maxLength: 18,
                        decoration: _buildInputDecoration(
                          label: 'CLABE Interbancaria (18 dígitos)',
                          hint: '012180012345678901',
                          icon: Icons.numbers_outlined,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _bankNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          label: 'Banco',
                          hint: 'ej. BBVA, Nu, Banorte, Mercado Pago',
                          icon: Icons.storefront_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Botón Registrarme
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.darkBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.darkBg,
                          ),
                        )
                      : const Text(
                          'Crear mi Cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
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
