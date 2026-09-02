import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valor_drive/core/di/service_locator.dart';
import 'package:valor_drive/core/services/gps_tracking_service.dart';
import 'package:valor_drive/core/services/operational_cost_storage_service.dart';
import 'package:valor_drive/features/ride_calculator/domain/enums/calculation_mode.dart';
import 'package:valor_drive/features/ride_calculator/domain/models/ride_input.dart';
import 'package:valor_drive/features/ride_calculator/domain/models/ride_result.dart';
import 'package:valor_drive/features/ride_calculator/presentation/controllers/ride_signal_controller.dart';

void main() {
  group('RideInput Model Tests', () {
    test('Deve retornar a distância manual quando o modo for manual', () {
      const input = RideInput(
        calculationMode: CalculationMode.manual,
        manualDistanceKm: 15.0,
        gpsDistanceKm: 25.0,
      );

      expect(input.effectiveDistanceKm, equals(15.0));
    });

    test('Deve retornar a distância do GPS quando o modo for GPS', () {
      const input = RideInput(
        calculationMode: CalculationMode.gps,
        manualDistanceKm: 15.0,
        gpsDistanceKm: 25.0,
      );

      expect(input.effectiveDistanceKm, equals(25.0));
    });

    test('Deve suportar o método copyWith mantendo a imutabilidade', () {
      const input = RideInput(
        fuelPricePerLiter: 5.0,
        manualDistanceKm: 10.0,
      );

      final updated = input.copyWith(fuelPricePerLiter: 6.0);

      expect(updated.fuelPricePerLiter, equals(6.0));
      expect(updated.manualDistanceKm, equals(10.0));
      expect(input.fuelPricePerLiter, equals(5.0));
    });
  });

  group('RideResult Math Tests', () {
    test('Deve calcular corretamente todos os custos, valor bruto e lucro líquido', () {
      const input = RideInput(
        calculationMode: CalculationMode.manual,
        manualDistanceKm: 20.0,
        fuelConsumptionKmPerLiter: 10.0,
        fuelPricePerLiter: 5.0,
        maintenanceCostPerKm: 0.5,
        tariffPerKm: 3.0,
      );

      final result = RideResult.fromInput(input);

      expect(result.fuelCost, equals(10.0));
      expect(result.maintenanceCost, equals(10.0));
      expect(result.totalOperationalCost, equals(20.0));
      expect(result.grossAmount, equals(60.0));
      expect(result.netProfit, equals(40.0));
      expect(result.isProfitable, isTrue);
      expect(result.profitMarginPercentage, closeTo(66.666, 0.01));
    });

    test('Deve tratar consumo zerado sem lançar exceção (divisão por zero)', () {
      const input = RideInput(
        manualDistanceKm: 10.0,
        fuelConsumptionKmPerLiter: 0.0,
        fuelPricePerLiter: 5.0,
      );

      final result = RideResult.fromInput(input);

      expect(result.fuelCost, equals(0.0));
    });
  });

  group('RideSignalController Reactive Signals Tests', () {
    late RideSignalController controller;

    setUp(() {
      controller = RideSignalController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Deve recalcular reativamente os Signals computados quando uma entrada mudar', () {
      expect(controller.effectiveDistanceKm.value, equals(0.0));
      expect(controller.netProfit.value, equals(0.0));

      controller.updateOperationalData(
        fuelConsumptionKmPerLiter: 10.0,
        fuelPricePerLiter: 6.0,
        maintenanceCostPerKm: 0.40,
        tariffPerKm: 3.0,
      );

      controller.setManualDistance(10.0);

      expect(controller.effectiveDistanceKm.value, equals(10.0));
      expect(controller.fuelCost.value, equals(6.0));
      expect(controller.maintenanceCost.value, equals(4.0));
      expect(controller.totalOperationalCost.value, equals(10.0));
      expect(controller.grossAmount.value, equals(30.0));
      expect(controller.netProfit.value, equals(20.0));
    });

    test('Deve alternar reativamente entre o modo GPS e o modo Manual', () {
      controller.setManualDistance(10.0);
      controller.updateGpsDistance(18.5);

      expect(controller.effectiveDistanceKm.value, equals(10.0));

      controller.setCalculationMode(CalculationMode.gps);
      expect(controller.effectiveDistanceKm.value, equals(18.5));
    });
  });

  group('GpsTrackingService Route Points Tests', () {
    test('Deve acumular pontos de coordenadas na rota ao simular incremento de distância GPS', () {
      final controller = RideSignalController();
      final gpsService = GpsTrackingService(controller);

      expect(gpsService.routePointsSignal.value, isEmpty);

      gpsService.simulateDistanceIncrement(5.0);

      expect(gpsService.routePointsSignal.value.length, equals(2));
      expect(controller.calculationModeSignal.value, equals(CalculationMode.gps));

      gpsService.resetTracking();
      expect(gpsService.routePointsSignal.value, isEmpty);
    });
  });

  group('OperationalCostStorageService Persistence Tests', () {
    test('Deve salvar e carregar os dados operacionais no dispositivo via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = OperationalCostStorageService(prefs);

      final controller1 = RideSignalController(storageService);
      controller1.updateOperationalData(
        fuelConsumptionKmPerLiter: 14.5,
        fuelPricePerLiter: 6.29,
        maintenanceCostPerKm: 0.45,
        tariffPerKm: 3.20,
      );

      // Instancia um novo Controller simulando reabrir o aplicativo
      final controller2 = RideSignalController(storageService);

      expect(controller2.fuelConsumptionKmPerLiterSignal.value, equals(14.5));
      expect(controller2.fuelPricePerLiterSignal.value, equals(6.29));
      expect(controller2.maintenanceCostPerKmSignal.value, equals(0.45));
      expect(controller2.tariffPerKmSignal.value, equals(3.20));
    });
  });

  group('GetIt Service Locator Tests', () {
    test('Deve registrar e fornecer a instância do RideSignalController via GetIt', () async {
      SharedPreferences.setMockInitialValues({});
      await getIt.reset();
      await setupServiceLocator();

      final controllerInstance = getIt<RideSignalController>();
      expect(controllerInstance, isA<RideSignalController>());
    });
  });
}
