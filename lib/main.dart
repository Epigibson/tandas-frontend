import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/brand_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/tanda_creator/presentation/controllers/tanda_controller.dart';
import 'features/tanda_detail/presentation/controllers/tanda_detail_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX', null);
  runApp(
    const ProviderScope(
      child: TandaApp(),
    ),
  );
}

class TandaApp extends ConsumerStatefulWidget {
  const TandaApp({super.key});

  @override
  ConsumerState<TandaApp> createState() => _TandaAppState();
}

class _TandaAppState extends ConsumerState<TandaApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Con la app en segundo plano el socket de Realtime se pierde avisos: al volver se recarga todo
    _lifecycleListener = AppLifecycleListener(onResume: () {
      ref.invalidate(myTandasProvider);
      ref.invalidate(tandaDetailProvider);
      ref.invalidate(tandaPaymentsProvider);
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: BrandConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Look Fintech oscuro OLED por defecto
      home: const SplashScreen(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Al cerrar sesión (manual o por token expirado) se descartan las pantallas abiertas encima
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.value != null && next.hasValue && next.value == null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),
      error: (e, _) => const LoginScreen(),
    );
  }
}
