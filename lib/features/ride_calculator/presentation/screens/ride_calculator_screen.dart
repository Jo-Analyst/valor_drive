import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../controllers/ride_signal_controller.dart';
import '../widgets/calculation_mode_selector.dart';
import '../widgets/ride_input_form.dart';
import '../widgets/ride_result_dashboard.dart';

/// Tela principal do aplicativo de cálculo de corrida para motoristas.
///
/// Integra a injeção de dependência [GetIt] com o estado reativo [Signals].
class RideCalculatorScreen extends StatefulWidget {
  const RideCalculatorScreen({super.key});

  @override
  State<RideCalculatorScreen> createState() => _RideCalculatorScreenState();
}

class _RideCalculatorScreenState extends State<RideCalculatorScreen> {
  late final RideSignalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<RideSignalController>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calculate_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ValorDrive',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Cálculo de Corrida para Motoristas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Sobre as fórmulas',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'ValorDrive',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    'Cálculo preciso de custos operacionais (combustível e manutenção) vs lucro líquido do motorista.',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SELETOR DE MODO (GPS VS MANUAL)
              CalculationModeSelector(controller: _controller),

              const SizedBox(height: 20),

              // 2. DASHBOARD DE RESULTADO (DESTAQUE CUSTO VS LUCRO)
              RideResultDashboard(controller: _controller),

              const SizedBox(height: 24),

              // 3. FORMULÁRIO DE ENTRADA DINÂMICA
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RideInputForm(controller: _controller),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
