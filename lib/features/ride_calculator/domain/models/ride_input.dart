import 'package:flutter/foundation.dart';
import '../enums/calculation_mode.dart';

/// Modelo imutável que encapsula todas as variáveis de entrada para o cálculo
/// do custo e tarifação de uma corrida.
@immutable
class RideInput {
  /// Modo ativo de cálculo de distância ([CalculationMode.gps] ou [CalculationMode.manual]).
  final CalculationMode calculationMode;

  /// Distância calculada em tempo real pelo GPS em quilômetros.
  final double gpsDistanceKm;

  /// Distância média informada manualmente em quilômetros.
  final double manualDistanceKm;

  /// Consumo médio de combustível do veículo em quilômetros por litro (km/L).
  final double fuelConsumptionKmPerLiter;

  /// Preço do litro de combustível em Reais (R$/L).
  final double fuelPricePerLiter;

  /// Custo de manutenção e depreciação por quilômetro rodado em Reais (R$/km).
  final double maintenanceCostPerKm;

  /// Tarifa/Cobrança desejada por quilômetro rodado em Reais (R$/km).
  final double tariffPerKm;

  const RideInput({
    this.calculationMode = CalculationMode.manual,
    this.gpsDistanceKm = 0.0,
    this.manualDistanceKm = 0.0,
    this.fuelConsumptionKmPerLiter = 10.0,
    this.fuelPricePerLiter = 0.0,
    this.maintenanceCostPerKm = 0.0,
    this.tariffPerKm = 0.0,
  });

  /// Retorna a distância efetiva a ser considerada nos cálculos operacionais.
  double get effectiveDistanceKm {
    switch (calculationMode) {
      case CalculationMode.gps:
        return gpsDistanceKm < 0 ? 0.0 : gpsDistanceKm;
      case CalculationMode.manual:
        return manualDistanceKm < 0 ? 0.0 : manualDistanceKm;
    }
  }

  /// Retorna uma nova instância de [RideInput] com os atributos especificados modificados.
  RideInput copyWith({
    CalculationMode? calculationMode,
    double? gpsDistanceKm,
    double? manualDistanceKm,
    double? fuelConsumptionKmPerLiter,
    double? fuelPricePerLiter,
    double? maintenanceCostPerKm,
    double? tariffPerKm,
  }) {
    return RideInput(
      calculationMode: calculationMode ?? this.calculationMode,
      gpsDistanceKm: gpsDistanceKm ?? this.gpsDistanceKm,
      manualDistanceKm: manualDistanceKm ?? this.manualDistanceKm,
      fuelConsumptionKmPerLiter:
          fuelConsumptionKmPerLiter ?? this.fuelConsumptionKmPerLiter,
      fuelPricePerLiter: fuelPricePerLiter ?? this.fuelPricePerLiter,
      maintenanceCostPerKm: maintenanceCostPerKm ?? this.maintenanceCostPerKm,
      tariffPerKm: tariffPerKm ?? this.tariffPerKm,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideInput &&
        other.calculationMode == calculationMode &&
        other.gpsDistanceKm == gpsDistanceKm &&
        other.manualDistanceKm == manualDistanceKm &&
        other.fuelConsumptionKmPerLiter == fuelConsumptionKmPerLiter &&
        other.fuelPricePerLiter == fuelPricePerLiter &&
        other.maintenanceCostPerKm == maintenanceCostPerKm &&
        other.tariffPerKm == tariffPerKm;
  }

  @override
  int get hashCode => Object.hash(
        calculationMode,
        gpsDistanceKm,
        manualDistanceKm,
        fuelConsumptionKmPerLiter,
        fuelPricePerLiter,
        maintenanceCostPerKm,
        tariffPerKm,
      );

  @override
  String toString() {
    return 'RideInput('
        'calculationMode: $calculationMode, '
        'effectiveDistanceKm: $effectiveDistanceKm, '
        'fuelConsumptionKmPerLiter: $fuelConsumptionKmPerLiter, '
        'fuelPricePerLiter: $fuelPricePerLiter, '
        'maintenanceCostPerKm: $maintenanceCostPerKm, '
        'tariffPerKm: $tariffPerKm)';
  }
}
