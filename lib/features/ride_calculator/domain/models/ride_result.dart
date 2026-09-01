import 'package:flutter/foundation.dart';
import 'ride_input.dart';

/// Modelo imutável que consolida os resultados financeiros e operacionais de uma corrida.
@immutable
class RideResult {
  /// Custo total de combustível estimado em Reais (R$).
  final double fuelCost;

  /// Custo total de manutenção e depreciação em Reais (R$).
  final double maintenanceCost;

  /// Custo operacional total (Combustível + Manutenção) em Reais (R$).
  final double totalOperationalCost;

  /// Valor bruto a cobrar do cliente/passageiro em Reais (R$).
  final double grossAmount;

  /// Lucro líquido final (Valor Bruto - Custo Operacional Total) em Reais (R$).
  final double netProfit;

  const RideResult({
    required this.fuelCost,
    required this.maintenanceCost,
    required this.totalOperationalCost,
    required this.grossAmount,
    required this.netProfit,
  });

  /// Construtor para estado zerado ou sem distância percorrida.
  const RideResult.zero()
      : fuelCost = 0.0,
        maintenanceCost = 0.0,
        totalOperationalCost = 0.0,
        grossAmount = 0.0,
        netProfit = 0.0;

  /// Factory reativo que realiza os cálculos matemáticos com base nos dados de [RideInput].
  factory RideResult.fromInput(RideInput input) {
    final distanceKm = input.effectiveDistanceKm;

    if (distanceKm <= 0) {
      return const RideResult.zero();
    }

    // 1. Custo Total de Combustível = (Distância / Consumo km/L) * Preço do Litro
    final double fuelCostCalculated;
    if (input.fuelConsumptionKmPerLiter <= 0) {
      fuelCostCalculated = 0.0; // Proteção contra divisão por zero
    } else {
      fuelCostCalculated =
          (distanceKm / input.fuelConsumptionKmPerLiter) * input.fuelPricePerLiter;
    }

    // 2. Custo Total de Manutenção = Distância * Custo Manutenção por KM
    final double maintenanceCostCalculated =
        distanceKm * input.maintenanceCostPerKm;

    // 3. Custo Operacional Total = Combustível + Manutenção
    final double totalOperationalCostCalculated =
        fuelCostCalculated + maintenanceCostCalculated;

    // 4. Valor Bruto a Cobrar = Distância * Tarifa por KM
    final double grossAmountCalculated = distanceKm * input.tariffPerKm;

    // 5. Lucro Líquido = Valor Bruto - Custo Operacional Total
    final double netProfitCalculated =
        grossAmountCalculated - totalOperationalCostCalculated;

    return RideResult(
      fuelCost: fuelCostCalculated,
      maintenanceCost: maintenanceCostCalculated,
      totalOperationalCost: totalOperationalCostCalculated,
      grossAmount: grossAmountCalculated,
      netProfit: netProfitCalculated,
    );
  }

  /// Retorna a margem de lucro percentual (%).
  double get profitMarginPercentage {
    if (grossAmount <= 0) return 0.0;
    return (netProfit / grossAmount) * 100;
  }

  /// Indica se a corrida é rentável (lucro maior que zero).
  bool get isProfitable => netProfit > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideResult &&
        other.fuelCost == fuelCost &&
        other.maintenanceCost == maintenanceCost &&
        other.totalOperationalCost == totalOperationalCost &&
        other.grossAmount == grossAmount &&
        other.netProfit == netProfit;
  }

  @override
  int get hashCode => Object.hash(
        fuelCost,
        maintenanceCost,
        totalOperationalCost,
        grossAmount,
        netProfit,
      );

  @override
  String toString() {
    return 'RideResult('
        'fuelCost: R\$${fuelCost.toStringAsFixed(2)}, '
        'maintenanceCost: R\$${maintenanceCost.toStringAsFixed(2)}, '
        'totalOperationalCost: R\$${totalOperationalCost.toStringAsFixed(2)}, '
        'grossAmount: R\$${grossAmount.toStringAsFixed(2)}, '
        'netProfit: R\$${netProfit.toStringAsFixed(2)})';
  }
}
