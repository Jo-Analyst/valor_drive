import 'package:flutter_test/flutter_test.dart';
import 'package:valor_drive/core/di/service_locator.dart';
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
      // Cenário:
      // Distância: 20 km
      // Consumo: 10 km/L -> usa 2 Litros
      // Preço Combustível: R$ 5,00/L -> Custo Combustível = R$ 10,00
      // Custo Manutenção/km: R$ 0,50/km -> Custo Manutenção = R$ 10,00
      // Custo Operacional Total = R$ 20,00
      // Tarifa/km: R$ 3,00/km -> Valor Bruto = R$ 60,00
      // Lucro Líquido = R$ 60,00 - R$ 20,00 = R$ 40,00
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
      // Estado inicial
      expect(controller.effectiveDistanceKm.value, equals(0.0));
      expect(controller.netProfit.value, equals(0.0));

      // Configura dados operacionais do veículo
      controller.updateOperationalData(
        fuelConsumptionKmPerLiter: 10.0,
        fuelPricePerLiter: 6.0,
        maintenanceCostPerKm: 0.40,
        tariffPerKm: 3.0,
      );

      // Altera distância manual para 10 km
      controller.setManualDistance(10.0);

      // Custo Combustível: (10 / 10) * 6 = R$ 6,00
      // Custo Manutenção: 10 * 0,40 = R$ 4,00
      // Custo Operacional Total = R$ 10,00
      // Valor Bruto: 10 * 3,00 = R$ 30,00
      // Lucro Líquido = R$ 20,00
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

      // Por padrão está no modo Manual
      expect(controller.effectiveDistanceKm.value, equals(10.0));

      // Altera para modo GPS
      controller.setCalculationMode(CalculationMode.gps);
      expect(controller.effectiveDistanceKm.value, equals(18.5));
    });
  });

  group('GetIt Service Locator Tests', () {
    test('Deve registrar e fornecer a instância do RideSignalController via GetIt', () {
      setupServiceLocator();

      final controllerInstance = getIt<RideSignalController>();
      expect(controllerInstance, isA<RideSignalController>());
    });
  });
}
