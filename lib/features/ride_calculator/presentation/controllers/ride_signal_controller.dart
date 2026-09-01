import 'package:signals_flutter/signals_flutter.dart';
import '../../domain/enums/calculation_mode.dart';
import '../../domain/models/ride_input.dart';
import '../../domain/models/ride_result.dart';

/// Controller reativo baseado na biblioteca [Signals].
///
/// Mantém o estado reativo das entradas do usuário e recomputa automaticamente
/// os custos operacionais, o valor a cobrar e o lucro líquido através de [computed()].
class RideSignalController {
  // ===========================================================================
  // SIGNALS DE ENTRADA (MUTAÇÃO DE ESTADO)
  // ===========================================================================

  /// Modo selecionado para obter a distância (GPS vs Entrada Manual).
  final Signal<CalculationMode> calculationModeSignal =
      signal<CalculationMode>(CalculationMode.manual);

  /// Distância calculada dinamicamente pelo GPS em tempo real (km).
  final Signal<double> gpsDistanceKmSignal = signal<double>(0.0);

  /// Média de distância informada manualmente pelo usuário (km).
  final Signal<double> manualDistanceKmSignal = signal<double>(0.0);

  /// Consumo médio do veículo (km/L).
  final Signal<double> fuelConsumptionKmPerLiterSignal = signal<double>(10.0);

  /// Preço do litro do combustível em Reais (R$/L).
  final Signal<double> fuelPricePerLiterSignal = signal<double>(5.50);

  /// Custo estimado de manutenção e depreciação em Reais por quilômetro (R$/km).
  final Signal<double> maintenanceCostPerKmSignal = signal<double>(0.30);

  /// Tarifa/Cobrança desejada por quilômetro rodado em Reais (R$/km).
  final Signal<double> tariffPerKmSignal = signal<double>(2.50);

  // ===========================================================================
  // COMPUTED SIGNALS (RECALCULADOS REATIVAMENTE QUANDO QUALQUER SINAL MUDA)
  // ===========================================================================

  /// Retorna a distância efetiva considerando o modo de cálculo ativo (GPS ou Manual).
  late final ReadonlySignal<double> effectiveDistanceKm = computed<double>(() {
    switch (calculationModeSignal.value) {
      case CalculationMode.gps:
        return gpsDistanceKmSignal.value < 0 ? 0.0 : gpsDistanceKmSignal.value;
      case CalculationMode.manual:
        return manualDistanceKmSignal.value < 0
            ? 0.0
            : manualDistanceKmSignal.value;
    }
  });

  /// Consolida todas as entradas em uma instância imutável de [RideInput].
  late final ReadonlySignal<RideInput> rideInput = computed<RideInput>(() {
    return RideInput(
      calculationMode: calculationModeSignal.value,
      gpsDistanceKm: gpsDistanceKmSignal.value,
      manualDistanceKm: manualDistanceKmSignal.value,
      fuelConsumptionKmPerLiter: fuelConsumptionKmPerLiterSignal.value,
      fuelPricePerLiter: fuelPricePerLiterSignal.value,
      maintenanceCostPerKm: maintenanceCostPerKmSignal.value,
      tariffPerKm: tariffPerKmSignal.value,
    );
  });

  /// Recalcula reativamente todos os resultados ([RideResult]) no instante em que
  /// qualquer sinal de entrada ou configuração operacional muda.
  late final ReadonlySignal<RideResult> rideResult = computed<RideResult>(() {
    return RideResult.fromInput(rideInput.value);
  });

  // ---------------------------------------------------------------------------
  // COMPUTED SIGNALS ATALHOS PARA SAÍDAS ESPECÍFICAS SOLICITADAS
  // ---------------------------------------------------------------------------

  /// 1. Custo Total de Combustível reativo.
  late final ReadonlySignal<double> fuelCost = computed<double>(() {
    return rideResult.value.fuelCost;
  });

  /// 2. Custo Total de Manutenção reativo.
  late final ReadonlySignal<double> maintenanceCost = computed<double>(() {
    return rideResult.value.maintenanceCost;
  });

  /// 3. Custo Operacional Total reativo (Combustível + Manutenção).
  late final ReadonlySignal<double> totalOperationalCost = computed<double>(() {
    return rideResult.value.totalOperationalCost;
  });

  /// 4. Valor Bruto a Cobrar reativo.
  late final ReadonlySignal<double> grossAmount = computed<double>(() {
    return rideResult.value.grossAmount;
  });

  /// 5. Lucro Líquido reativo.
  late final ReadonlySignal<double> netProfit = computed<double>(() {
    return rideResult.value.netProfit;
  });

  // ===========================================================================
  // AÇÕES / MÉTODOS DE ATUALIZAÇÃO
  // ===========================================================================

  /// Altera o modo de cálculo (GPS vs Manual).
  void setCalculationMode(CalculationMode mode) {
    calculationModeSignal.value = mode;
  }

  /// Atualiza a distância manual digitada pelo usuário.
  void setManualDistance(double distanceKm) {
    manualDistanceKmSignal.value = distanceKm < 0 ? 0.0 : distanceKm;
  }

  /// Atualiza a distância recebida do serviço de GPS.
  void updateGpsDistance(double distanceKm) {
    gpsDistanceKmSignal.value = distanceKm < 0 ? 0.0 : distanceKm;
  }

  /// Atualiza o consumo médio do veículo (km/L).
  void setFuelConsumption(double kmPerLiter) {
    fuelConsumptionKmPerLiterSignal.value = kmPerLiter < 0 ? 0.0 : kmPerLiter;
  }

  /// Atualiza o preço do combustível (R$/L).
  void setFuelPrice(double pricePerLiter) {
    fuelPricePerLiterSignal.value = pricePerLiter < 0 ? 0.0 : pricePerLiter;
  }

  /// Atualiza o custo de manutenção/depreciação por KM (R$/km).
  void setMaintenanceCostPerKm(double costPerKm) {
    maintenanceCostPerKmSignal.value = costPerKm < 0 ? 0.0 : costPerKm;
  }

  /// Atualiza a tarifa desejada por KM (R$/km).
  void setTariffPerKm(double tariff) {
    tariffPerKmSignal.value = tariff < 0 ? 0.0 : tariff;
  }

  /// Atualiza em lote as configurações operacionais do carro.
  void updateOperationalData({
    double? fuelConsumptionKmPerLiter,
    double? fuelPricePerLiter,
    double? maintenanceCostPerKm,
    double? tariffPerKm,
  }) {
    batch(() {
      if (fuelConsumptionKmPerLiter != null) {
        setFuelConsumption(fuelConsumptionKmPerLiter);
      }
      if (fuelPricePerLiter != null) {
        setFuelPrice(fuelPricePerLiter);
      }
      if (maintenanceCostPerKm != null) {
        setMaintenanceCostPerKm(maintenanceCostPerKm);
      }
      if (tariffPerKm != null) {
        setTariffPerKm(tariffPerKm);
      }
    });
  }

  /// Reseta todos os valores para o estado padrão inicial.
  void reset() {
    batch(() {
      calculationModeSignal.value = CalculationMode.manual;
      gpsDistanceKmSignal.value = 0.0;
      manualDistanceKmSignal.value = 0.0;
      fuelConsumptionKmPerLiterSignal.value = 10.0;
      fuelPricePerLiterSignal.value = 5.50;
      maintenanceCostPerKmSignal.value = 0.30;
      tariffPerKmSignal.value = 2.50;
    });
  }

  /// Libera recursos e descarta os sinais quando não forem mais necessários.
  void dispose() {
    calculationModeSignal.dispose();
    gpsDistanceKmSignal.dispose();
    manualDistanceKmSignal.dispose();
    fuelConsumptionKmPerLiterSignal.dispose();
    fuelPricePerLiterSignal.dispose();
    maintenanceCostPerKmSignal.dispose();
    tariffPerKmSignal.dispose();
  }
}
