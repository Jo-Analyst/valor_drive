import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';
import 'features/ride_calculator/presentation/screens/ride_calculator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o Service Locator GetIt
  setupServiceLocator();
  runApp(const ValorDriveApp());
}

class ValorDriveApp extends StatelessWidget {
  const ValorDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0F766E); // Teal profundo/Emerald

    return MaterialApp(
      title: 'ValorDrive',
      debugShowCheckedModeBanner: false,

      // Tema Claro Material 3
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
      ),

      // Tema Escuro Material 3 (Ideal para motoristas à noite)
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
      ),

      themeMode: ThemeMode.system,
      home: const RideCalculatorScreen(),
    );
  }
}
