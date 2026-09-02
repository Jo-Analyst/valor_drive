import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valor_drive/core/di/service_locator.dart';
import 'package:valor_drive/core/services/gps_tracking_service.dart';
import 'package:valor_drive/features/ride_calculator/presentation/controllers/ride_signal_controller.dart';
import 'package:valor_drive/features/ride_calculator/presentation/screens/ride_calculator_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await setupServiceLocator();
  });

  testWidgets('Deve renderizar a tela RideCalculatorScreen com os componentes de UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RideCalculatorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ValorDrive'), findsOneWidget);
    expect(find.text('Modo de Medição'), findsOneWidget);
    expect(find.text('LUCRO LÍQUIDO'), findsOneWidget);
    expect(find.text('CUSTO OPERACIONAL TOTAL'), findsOneWidget);
  });

  testWidgets('Deve alternar entre Modo Manual e Modo GPS no SegmentedButton',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RideCalculatorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final controller = getIt<RideSignalController>();

    expect(find.text('Média Manual (KM)'), findsOneWidget);
    expect(find.text('Modo GPS'), findsOneWidget);

    await tester.tap(find.text('Modo GPS'));
    await tester.pumpAndSettle();

    expect(controller.calculationModeSignal.value.name, equals('gps'));
  });

  testWidgets('Deve atualizar o Lucro Líquido ao simular incremento no GpsTrackingService',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RideCalculatorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final controller = getIt<RideSignalController>();
    final gpsService = getIt<GpsTrackingService>();

    controller.updateOperationalData(
      fuelConsumptionKmPerLiter: 10.0,
      fuelPricePerLiter: 5.0,
      maintenanceCostPerKm: 0.50,
      tariffPerKm: 3.00,
    );

    // Simula percurso de 10.0 km via GPS
    gpsService.simulateDistanceIncrement(10.0);

    await tester.pumpAndSettle();

    // Lucro Líquido: 30 - 10 = R$ 20,00
    expect(find.textContaining('20,00'), findsOneWidget);
    expect(find.textContaining('10,00'), findsOneWidget);
    expect(find.text('✓ Corrida lucrativa para o bolso'), findsOneWidget);
  });
}
