import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TandaApp(),
    ),
  );
}

class TandaApp extends StatelessWidget {
  const TandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TandaApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Modo oscuro OLED predeterminado para el look fintech premium
      home: const HomeScreen(),
    );
  }
}
