import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/di/service_locator.dart';
import 'core/services/background_execution_service.dart';
import 'features/ride_calculator/presentation/screens/ride_calculator_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o Service Locator GetIt e o armazenamento local
  await setupServiceLocator();
  if (Platform.isAndroid) {
    await initializeBackgroundExecution();
  }
  runApp(const ValorDriveApp());
  if (Platform.isAndroid) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestNotificationPermission());
    });
  }
}

Future<void> _requestNotificationPermission() async {
  final permission = Permission.notification;
  if (!await permission.isGranted && !await permission.isPermanentlyDenied) {
    await permission.request();
  }
}

@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ValorDriveOverlay(),
    ),
  );
}

class _ValorDriveOverlay extends StatelessWidget {
  const _ValorDriveOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calculate_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'ValorDrive',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: 'Fechar sobreposição',
                onPressed: FlutterOverlayWindow.closeOverlay,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
