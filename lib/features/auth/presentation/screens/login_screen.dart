import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../data/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

enum _LoginMode { phone, email }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  _LoginMode _mode = _LoginMode.phone;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _biometricAvailable = false;
  bool _autoPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-calienta la conexión con el servidor para que el login sea instantáneo
      ref.read(apiClientProvider).prewarmConnection();
      _loadSavedState();
    });
  }

  Future<void> _loadSavedState() async {
    final repository = ref.read(authRepositoryProvider);
    final lastIdentifier = await repository.getLastIdentifier();
    final biometricAvailable = await ref.read(biometricServiceProvider).isAvailable();
    if (!mounted) return;

    setState(() {
      _biometricAvailable = biometricAvailable;
      if (lastIdentifier != null && _identifierController.text.isEmpty) {
        _mode = lastIdentifier.contains('@') ? _LoginMode.email : _LoginMode.phone;
        _identifierController.text = lastIdentifier;
      }
    });

    // Si ya hay huella activada, se pide de una vez (solo al abrir la pantalla)
    final account = await ref.read(biometricAccountProvider.future);
    if (account != null && biometricAvailable && !_autoPrompted && mounted) {
      _autoPrompted = true;
      _handleBiometricLogin();
    } else if (lastIdentifier != null && mounted) {
      // Con el usuario prellenado, el cursor va directo a la contraseña
      _passwordFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    // Se pide antes del login: al entrar, AuthGate cambia al Home y ahí se ofrece activar la huella
    if (_biometricAvailable) ref.read(biometricOfferProvider.notifier).request();

    try {
      await ref.read(authControllerProvider.notifier).login(
            phoneOrEmail: _identifierController.text.trim(),
            password: _passwordController.text,
          );
      // Le avisa al gestor de contraseñas del teléfono que guarde lo que se escribió
      TextInput.finishAutofillContext();
    } catch (e) {
      ref.read(biometricOfferProvider.notifier).consume();
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isBiometricLoading) return;
    setState(() => _isBiometricLoading = true);
    try {
      final ok = await ref.read(biometricServiceProvider).authenticate('Confirma tu huella para entrar a Tanditas');
      if (!ok) return;
      HapticFeedback.mediumImpact();
      await ref.read(authControllerProvider.notifier).loginWithDevice();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  void _switchMode(_LoginMode mode) {
    if (mode == _mode) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      _identifierController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final biometricAccount = ref.watch(biometricAccountProvider).value;
    final showBiometric = _biometricAvailable && biometricAccount != null;
    final heroHeight = MediaQuery.sizeOf(context).height * 0.30;

    return Scaffold(
      body: LiquidGlassBackground(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(heroHeight),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showBiometric) ...[
                      _buildBiometricCard(biometricAccount),
                      const SizedBox(height: 18),
                      _buildDivider('o entra con tu contraseña'),
                      const SizedBox(height: 18),
                    ],
                    _buildForm(),
                    const SizedBox(height: 20),
                    // Wrap: con letra grande, "Crear cuenta" baja a otra línea en vez de desbordarse
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          '¿Aún no tienes cuenta?',
                          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Crear cuenta',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Arte de la marca arriba, desvanecido hacia el fondo, con el nombre de la app encima
  Widget _buildHero(double height) {
    return SizedBox(
      height: height + MediaQuery.paddingOf(context).top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/branding/splash_art.png', fit: BoxFit.cover, alignment: Alignment.topCenter),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.55, 1.0],
                colors: [
                  AppColors.darkBg.withValues(alpha: 0.15),
                  AppColors.darkBg.withValues(alpha: 0.55),
                  AppColors.darkBg,
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BrandConfig.appName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  BrandConfig.appTagline,
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard(BiometricAccount account) {
    final firstName = account.displayName.split(' ').first;
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BrandConfig.modalRadius,
      tintColor: AppColors.primary,
      opacity: 0.10,
      borderOpacity: 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            firstName.isNotEmpty ? '¡Hola de nuevo, $firstName!' : '¡Hola de nuevo!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isBiometricLoading ? null : _handleBiometricLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.darkBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BrandConfig.buttonRadius)),
            ),
            icon: _isBiometricLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkBg),
                  )
                : const Icon(Icons.fingerprint, size: 26),
            label: const Text('Entrar con huella', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white12)),
        Flexible(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }

  Widget _buildForm() {
    final isPhone = _mode == _LoginMode.phone;

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BrandConfig.modalRadius,
      blur: 16,
      opacity: 0.08,
      borderOpacity: 0.25,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_LoginMode>(
                segments: const [
                  ButtonSegment(value: _LoginMode.phone, icon: Icon(Icons.phone_iphone, size: 18), label: Text('Teléfono')),
                  ButtonSegment(value: _LoginMode.email, icon: Icon(Icons.alternate_email, size: 18), label: Text('Correo')),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => _switchMode(selection.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.18),
                  selectedForegroundColor: AppColors.primary,
                  foregroundColor: AppColors.darkTextSecondary,
                  side: const BorderSide(color: AppColors.darkBorder),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                // La key cambia con el modo para que el teclado se reconstruya (numérico vs. correo)
                key: ValueKey(_mode),
                controller: _identifierController,
                keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: isPhone
                    ? const [AutofillHints.telephoneNumber, AutofillHints.username]
                    : const [AutofillHints.email, AutofillHints.username],
                inputFormatters: isPhone
                    ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
                    : null,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: _inputDecoration(
                  label: isPhone ? 'Teléfono' : 'Correo',
                  hint: isPhone ? '10 dígitos' : 'correo@ejemplo.com',
                  icon: isPhone ? Icons.phone_iphone : Icons.alternate_email,
                ),
                validator: (val) {
                  final value = val?.trim() ?? '';
                  if (value.isEmpty) return isPhone ? 'Escribe tu teléfono' : 'Escribe tu correo';
                  if (isPhone && value.length != 10) return 'El teléfono debe tener 10 dígitos';
                  if (!isPhone && !value.contains('@')) return 'Revisa tu correo';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _handleLogin(),
                decoration: _inputDecoration(
                  label: 'Contraseña',
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
                validator: (val) => (val == null || val.isEmpty) ? 'Escribe tu contraseña' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResetPasswordScreen(initialIdentifier: _identifierController.text.trim()),
                      ),
                    );
                  },
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.darkBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BrandConfig.buttonRadius)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkBg),
                      )
                    : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
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
